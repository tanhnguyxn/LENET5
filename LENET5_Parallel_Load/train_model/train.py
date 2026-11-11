import argparse
import csv
import json
import random
from pathlib import Path

import torch
from torch import nn
from torch.utils.data import DataLoader, random_split
from torchvision import datasets, transforms


class LeNet5(nn.Module):
    def __init__(self):
        super().__init__()

        self.conv1 = nn.Conv2d(1, 6, kernel_size=5)
        self.conv2 = nn.Conv2d(6, 16, kernel_size=5)

        self.relu = nn.ReLU()
        self.pool = nn.MaxPool2d(kernel_size=2, stride=2)

        self.fc1 = nn.Linear(16 * 4 * 4, 120)
        self.fc2 = nn.Linear(120, 84)
        self.fc3 = nn.Linear(84, 10)

    def forward(self, x):
        x = self.pool(self.relu(self.conv1(x)))
        x = self.pool(self.relu(self.conv2(x)))

        # Flatten order: channel, row, column.
        x = torch.flatten(x, start_dim=1)

        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))

        # Return logits. CrossEntropyLoss applies log-softmax internally.
        return self.fc3(x)


def set_seed(seed):
    random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)

    # Improve repeatability on the same software/hardware setup.
    torch.backends.cudnn.benchmark = False
    torch.backends.cudnn.deterministic = True
    torch.backends.cuda.matmul.allow_tf32 = False
    torch.backends.cudnn.allow_tf32 = False


def train_epoch(model, loader, criterion, optimizer, device):
    model.train()

    loss_sum = 0.0
    correct = 0
    total = 0

    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)

        logits = model(images)
        loss = criterion(logits, labels)

        loss.backward()
        optimizer.step()

        batch_size = labels.size(0)
        loss_sum += loss.item() * batch_size
        correct += (logits.argmax(dim=1) == labels).sum().item()
        total += batch_size

    return loss_sum / total, correct / total


@torch.inference_mode()
def evaluate(model, loader, criterion, device):
    model.eval()

    loss_sum = 0.0
    correct = 0
    total = 0
    confusion = torch.zeros(10, 10, dtype=torch.int64)

    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        logits = model(images)
        loss = criterion(logits, labels)
        predicted = logits.argmax(dim=1)

        batch_size = labels.size(0)
        loss_sum += loss.item() * batch_size
        correct += (predicted == labels).sum().item()
        total += batch_size

        # Rows: actual labels. Columns: predicted labels.
        indices = (labels * 10 + predicted).cpu()
        confusion += torch.bincount(
            indices, minlength=100
        ).reshape(10, 10)

    return loss_sum / total, correct / total, confusion


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs", type=int, default=20)
    parser.add_argument("--batch-size", type=int, default=128)
    parser.add_argument("--lr", type=float, default=0.001)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--data-dir", default="data")
    parser.add_argument("--out-dir", default="outputs")
    args = parser.parse_args()

    if args.epochs < 1 or args.batch_size < 1:
        raise ValueError("epochs and batch-size must be positive.")

    if not torch.cuda.is_available():
        raise RuntimeError(
            "CUDA is unavailable. Check the NVIDIA driver and "
            "install the CUDA-enabled PyTorch build."
        )

    set_seed(args.seed)
    device = torch.device("cuda")

    # Fail early if CUDA kernels cannot run on this GPU.
    probe = torch.randn(32, 32, device=device)
    _ = probe @ probe
    torch.cuda.synchronize()

    output_dir = Path(args.out_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # ToTensor converts uint8 pixels to float32 values in [0, 1].
    transform = transforms.ToTensor()

    full_train = datasets.MNIST(
        root=args.data_dir,
        train=True,
        download=True,
        transform=transform,
    )

    test_dataset = datasets.MNIST(
        root=args.data_dir,
        train=False,
        download=True,
        transform=transform,
    )

    train_dataset, val_dataset = random_split(
        full_train,
        [55000, 5000],
        generator=torch.Generator().manual_seed(args.seed),
    )

    # Save the exact split for future comparisons.
    torch.save(
        {
            "train_indices": train_dataset.indices,
            "val_indices": val_dataset.indices,
        },
        output_dir / "split_indices.pt",
    )

    loader_options = {
        "batch_size": args.batch_size,
        "num_workers": 0,  # Simple and reliable on Windows.
        "pin_memory": True,
    }

    train_loader = DataLoader(
        train_dataset,
        shuffle=True,
        generator=torch.Generator().manual_seed(args.seed),
        **loader_options,
    )
    val_loader = DataLoader(
        val_dataset, shuffle=False, **loader_options
    )
    test_loader = DataLoader(
        test_dataset, shuffle=False, **loader_options
    )

    model = LeNet5().to(device)
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=args.lr)

    parameter_count = sum(p.numel() for p in model.parameters())

    print("GPU:", torch.cuda.get_device_name(0))
    print("PyTorch:", torch.__version__)
    print("CUDA runtime:", torch.version.cuda)
    print("Parameters:", parameter_count)
    print("Dataset: 55000 train / 5000 validation / 10000 test")

    best_val_accuracy = -1.0
    best_val_loss = float("inf")
    best_epoch = 0
    checkpoint_path = output_dir / "best_model.pt"

    config = {
        **vars(args),
        "architecture": "LeNet5_28_ReLU_MaxPool",
        "input_shape": [1, 28, 28],
        "preprocessing": "float32(pixel) / 255.0",
        "flatten_order": "channel,row,column",
        "parameters": parameter_count,
        "torch_version": str(torch.__version__),
        "cuda_version": torch.version.cuda,
        "gpu": torch.cuda.get_device_name(0),
    }

    with (output_dir / "config.json").open(
        "w", encoding="utf-8"
    ) as file:
        json.dump(config, file, indent=2)

    with (output_dir / "history.csv").open(
        "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.writer(file)
        writer.writerow([
            "epoch", "train_loss", "train_accuracy",
            "val_loss", "val_accuracy",
        ])

        for epoch in range(1, args.epochs + 1):
            train_loss, train_acc = train_epoch(
                model, train_loader, criterion, optimizer, device
            )

            val_loss, val_acc, _ = evaluate(
                model, val_loader, criterion, device
            )

            writer.writerow([
                epoch, train_loss, train_acc, val_loss, val_acc
            ])
            file.flush()

            improved = (
                val_acc > best_val_accuracy
                or (
                    val_acc == best_val_accuracy
                    and val_loss < best_val_loss
                )
            )

            if improved:
                best_val_accuracy = val_acc
                best_val_loss = val_loss
                best_epoch = epoch

                # Store portable CPU tensors in the checkpoint.
                torch.save(
                    {
                        "model_state_dict": {
                            name: value.detach().cpu().clone()
                            for name, value in model.state_dict().items()
                        },
                        "epoch": epoch,
                        "val_accuracy": val_acc,
                        "val_loss": val_loss,
                        "config": config,
                    },
                    checkpoint_path,
                )

            print(
                f"Epoch {epoch:02d}/{args.epochs} | "
                f"Train loss {train_loss:.4f}, "
                f"acc {train_acc * 100:.2f}% | "
                f"Val loss {val_loss:.4f}, "
                f"acc {val_acc * 100:.2f}%"
                + (" | saved best" if improved else "")
            )

    # Evaluate the selected checkpoint on the test set once.
    checkpoint = torch.load(
        checkpoint_path, map_location="cpu", weights_only=True
    )
    model.load_state_dict(checkpoint["model_state_dict"])

    test_loss, test_acc, confusion = evaluate(
        model, test_loader, criterion, device
    )

    metrics = {
        "best_epoch": best_epoch,
        "best_val_accuracy": best_val_accuracy,
        "test_loss": test_loss,
        "test_accuracy": test_acc,
    }

    with (output_dir / "metrics.json").open(
        "w", encoding="utf-8"
    ) as file:
        json.dump(metrics, file, indent=2)

    with (output_dir / "confusion_matrix.csv").open(
        "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.writer(file)
        writer.writerow(
            ["actual/predicted"] + list(range(10))
        )
        for digit, row in enumerate(confusion.tolist()):
            writer.writerow([digit] + row)

    print(f"\nBest epoch: {best_epoch}")
    print(f"Test accuracy: {test_acc * 100:.2f}%")
    print(f"Checkpoint: {checkpoint_path.resolve()}")


if __name__ == "__main__":
    main()