import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torchvision import datasets

from train import LeNet5


SCALE = 256
QMIN = -32768
QMAX = 32767

LAYERS = ("conv1", "conv2", "fc1", "fc2", "fc3")


def quantize(array):
    """Round to nearest, ties to even; saturate to signed Q8.8."""
    rounded = np.rint(np.asarray(array, dtype=np.float64) * SCALE)
    clipped = int(np.count_nonzero(
        (rounded < QMIN) | (rounded > QMAX)
    ))
    result = np.clip(rounded, QMIN, QMAX).astype(np.int16)
    return result, clipped


def save_hex(path, array):
    """One signed 16-bit two's-complement word per line."""
    with path.open("w", encoding="ascii") as file:
        for value in array.reshape(-1):
            file.write(f"{int(value) & 0xFFFF:04X}\n")


class FixedLeNet5:
    def __init__(self, parameters):
        # int64 is a simulation container, not the hardware data width.
        self.p = {
            name: value.astype(np.int64)
            for name, value in parameters.items()
        }
        self.stats = {}

    def finish(self, acc, name, relu):
        # With this network and signed 16-bit operands, the sum fits
        # within a signed 48-bit accumulator. Check explicitly.
        if np.any(acc < -(1 << 47)) or np.any(acc > (1 << 47) - 1):
            raise OverflowError(f"48-bit accumulator overflow: {name}")

        if relu:
            acc = np.maximum(acc, 0)

        stat = self.stats.setdefault(
            name, {"saturated": 0, "total": 0}
        )
        stat["saturated"] += int(np.count_nonzero(
            (acc < QMIN) | (acc > QMAX)
        ))
        stat["total"] += int(acc.size)

        return np.clip(acc, QMIN, QMAX)

    def conv(self, x, name):
        weight = self.p[name + ".weight"]
        bias = self.p[name + ".bias"]

        batch, cin, height, width = x.shape
        cout, weight_cin, kh, kw = weight.shape
        assert cin == weight_cin

        oh = height - kh + 1
        ow = width - kw + 1

        acc = np.broadcast_to(
            bias[None, :, None, None],
            (batch, cout, oh, ow),
        ).copy()

        # Conv2d uses cross-correlation: do not reverse the kernel.
        for ic in range(cin):
            for ky in range(kh):
                for kx in range(kw):
                    patch = x[
                        :, ic, ky:ky + oh, kx:kx + ow
                    ][:, None, :, :]

                    coeff = weight[
                        :, ic, ky, kx
                    ][None, :, None, None]

                    # Arithmetic shift EACH product before accumulation.
                    acc += (patch * coeff) >> 8

        return self.finish(acc, name, relu=True)

    @staticmethod
    def pool(x):
        batch, channels, height, width = x.shape
        assert height % 2 == 0 and width % 2 == 0
        return x.reshape(
            batch, channels, height // 2, 2, width // 2, 2
        ).max(axis=(3, 5))

    def linear(self, x, name, relu):
        weight = self.p[name + ".weight"]
        bias = self.p[name + ".bias"]

        assert x.shape[1] == weight.shape[1]

        acc = np.broadcast_to(
            bias[None, :], (x.shape[0], weight.shape[0])
        ).copy()

        for index in range(x.shape[1]):
            product = (
                x[:, index:index + 1] * weight[None, :, index]
            )
            acc += product >> 8

        return self.finish(acc, name, relu)

    def __call__(self, x):
        x = self.pool(self.conv(x, "conv1"))
        x = self.pool(self.conv(x, "conv2"))

        # NCHW flatten: channel -> row -> column.
        x = x.reshape(x.shape[0], -1)

        x = self.linear(x, "fc1", relu=True)
        x = self.linear(x, "fc2", relu=True)
        return self.linear(x, "fc3", relu=False)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--checkpoint", default="outputs/best_model.pt"
    )
    parser.add_argument("--data-dir", default="data")
    parser.add_argument("--out-dir", default="outputs_q88")
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument(
        "--limit", type=int, default=0,
        help="0 = all 10000 test images; positive = smoke test",
    )
    args = parser.parse_args()

    if args.batch_size < 1 or args.limit < 0:
        raise ValueError("Invalid batch-size or limit.")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    checkpoint = torch.load(
        args.checkpoint, map_location="cpu", weights_only=True
    )
    state = checkpoint["model_state_dict"]

    float_model = LeNet5()
    float_model.load_state_dict(state, strict=True)
    float_model.eval()

    device = torch.device(
        "cuda" if torch.cuda.is_available() else "cpu"
    )
    float_model.to(device)

    parameters = {}
    manifest = {
        "format": "signed int16, 8 fractional bits",
        "scale": SCALE,
        "rounding": "nearest, ties to even",
        "mac": "bias_q + sum((x_q * w_q) >> 8)",
        "accumulator_bits": 48,
        "output": "ReLU where specified, then int16 saturation",
        "input": "round((pixel / 255.0) * 256)",
        "conv_order": "output_channel,input_channel,kernel_y,kernel_x",
        "fc_order": "output_neuron,input_index",
        "flatten_order": "channel,row,column",
        "tensors": {},
    }

    for layer in LAYERS:
        for kind in ("weight", "bias"):
            name = f"{layer}.{kind}"
            original = state[name].detach().cpu().numpy()
            quantized, clipped = quantize(original)
            parameters[name] = quantized

            filename = f"{layer}_{kind}.hex"
            save_hex(out_dir / filename, quantized)

            manifest["tensors"][name] = {
                "shape": list(quantized.shape),
                "count": int(quantized.size),
                "hex_file": filename,
                "clipped_parameters": clipped,
                "max_abs_quantization_error": float(
                    np.max(np.abs(
                        original.astype(np.float64)
                        - quantized.astype(np.float64) / SCALE
                    ))
                ),
            }

    np.savez(out_dir / "parameters_q88.npz", **parameters)

    with (out_dir / "manifest.json").open(
        "w", encoding="utf-8"
    ) as file:
        json.dump(manifest, file, indent=2)

    dataset = datasets.MNIST(
        root=args.data_dir, train=False, download=True
    )

    count = len(dataset) if args.limit == 0 else min(
        args.limit, len(dataset)
    )
    labels = dataset.targets[:count].numpy()
    fixed_model = FixedLeNet5(parameters)

    float_correct = 0
    fixed_correct = 0
    disagreement = 0
    confusion = np.zeros((10, 10), dtype=np.int64)

    print("Float32 device:", device)
    print("Fixed-point simulator: CPU / integer arithmetic")
    print("Images:", count)

    with torch.inference_mode():
        for start in range(0, count, args.batch_size):
            end = min(start + args.batch_size, count)

            images = (
                dataset.data[start:end]
                .unsqueeze(1)
                .float()
                .div(255.0)
            )
            expected = labels[start:end]

            float_logits = float_model(images.to(device))
            float_pred = float_logits.argmax(1).cpu().numpy()

            fixed_input, _ = quantize(images.numpy())
            fixed_logits = fixed_model(
                fixed_input.astype(np.int64)
            )
            fixed_pred = fixed_logits.argmax(axis=1)

            float_correct += int(np.sum(float_pred == expected))
            fixed_correct += int(np.sum(fixed_pred == expected))
            disagreement += int(np.sum(float_pred != fixed_pred))
            np.add.at(confusion, (expected, fixed_pred), 1)

            if start == 0:
                save_hex(out_dir / "sample_input.hex", fixed_input[0])
                save_hex(
                    out_dir / "sample_logits.hex", fixed_logits[0]
                )
                with (out_dir / "sample_info.json").open(
                    "w", encoding="utf-8"
                ) as file:
                    json.dump({
                        "mnist_test_index": 0,
                        "label": int(expected[0]),
                        "float_prediction": int(float_pred[0]),
                        "q88_prediction": int(fixed_pred[0]),
                    }, file, indent=2)

            print(
                f"\rProcessed {end}/{count} | "
                f"Float32: {100 * float_correct / end:.2f}% | "
                f"Q8.8: {100 * fixed_correct / end:.2f}%",
                end="", flush=True,
            )

    float_acc = 100 * float_correct / count
    fixed_acc = 100 * fixed_correct / count

    results = {
        "images": count,
        "full_test": count == len(dataset),
        "float_accuracy_percent": float_acc,
        "q88_accuracy_percent": fixed_acc,
        "accuracy_drop_percentage_points": float_acc - fixed_acc,
        "prediction_disagreements": disagreement,
        "activation_saturation": fixed_model.stats,
    }

    with (out_dir / "metrics_q88.json").open(
        "w", encoding="utf-8"
    ) as file:
        json.dump(results, file, indent=2)

    np.savetxt(
        out_dir / "confusion_matrix_q88.csv",
        confusion, fmt="%d", delimiter=","
    )

    print("\n\nFloat32 accuracy:", f"{float_acc:.2f}%")
    print("Q8.8 accuracy:  ", f"{fixed_acc:.2f}%")
    print("Accuracy drop:  ", f"{float_acc - fixed_acc:.2f} percentage points")

    for name, stat in fixed_model.stats.items():
        rate = 100 * stat["saturated"] / stat["total"]
        print(f"{name}: saturation = {rate:.4f}%")

    print("Results:", out_dir.resolve())


if __name__ == "__main__":
    main()