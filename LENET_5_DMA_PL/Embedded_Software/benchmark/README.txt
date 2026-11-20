KR260 / Linux AArch64, PIO and optional AXI CDMA simple mode
===========================================================
Run one process only. Stop the digit UI and other processes using the IP.
Use the clock and addresses from the actual loaded bitstream and Address Editor.
Set HEX to the directory with the ten parameter .hex files plus sample_input.hex
and sample_logits.hex. These must be from the same model export.

gcc -std=c11 -O2 -Wall -Wextra bench.c -o bench
python3 prepare.py "$HEX" data
sudo ./bench pio "$IP" - data/prep.bin 1000 pio.csv

Use a NEW CSV filename per run. An initial A-B-A test checks all ten logits
at each step. A is the exported sample. B is a generated diagnostic input
whose logits are calculated by the integer software reference. It is not a
labelled MNIST sample. Repetition mode alternates A/B; no accuracy is reported.
For real MNIST data set IDX to the folder containing the official test pair
(t10k-images-idx3-ubyte and t10k-labels-idx1-ubyte, uncompressed or .gz).
python3 prepare.py "$HEX" data --mnist "$IDX"
sudo ./bench pio "$IP" - data/prep.bin data/mnist.bin pio_test.csv

CDMA requires the full AXI CDMA (32-bit address, 64-bit data, simple mode,
4 KiB BTT supported), burst-compatible path to the IP, exclusive userspace
controller ownership and /dev/udmabuf0 backed by CDMA-accessible DDR below 4 GiB.
CPU and CDMA must see the IP at the same address. The u-dma-buf sysfs path
is /sys/class/u-dma-buf/udmabuf0/. Set CDMA to the actual control address.
sudo ./bench cdma "$IP" "$CDMA" data/prep.bin data/mnist.bin cdma_test.csv
python3 compare.py pio_test.csv cdma_test.csv

params_ms: one transfer of the 44,426 parameters, excluding file preparation.
upload_us includes CDMA staging, synchronization, start and completion polling.
start_done_us is software time from issuing START until observing DONE.
read_us includes ten logits and the result register. total_us includes all
three stages. batch FPS includes host-side bookkeeping but excludes setup,
warm-up, parameter loading, dataset I/O and writing the CSV. No web UI involved.
For true core cycles use a PL cycle counter or ILA timestamps with enough
capture coverage to see START and DONE. Accuracy uses signed logits checked
against the hardware result register, with labels from the MNIST test set.

PS ZDMA / GDMA on KR260 Linux
=============================
Same HEX, IP, prep.bin, mnist.bin and CSV format as the previous package.
The new frontend asks Linux DMAengine for a free FPD GDMA channel and logs its
identity. The module allocates coherent DDR and maps the upload aperture as a
DMA resource. Uploads include copying and packing values into 64-bit AXI words,
DMA submission, and waiting for the completion IRQ. An image uses transfers
of 512 and 272 AXI words. START, DONE polling and results use CPU MMIO.
The PL IP must accept incrementing DMA writes to its word windows via the
implemented PS-to-PL route, with suitable width/burst conversion in the fabric.
Do not run the UI or any other owner of this accelerator during measurements.
Prerequisites: matching kernel build tree on board, enabled ZynqMP DMAengine
driver, a free enabled FPD GDMA channel, and permission to load local modules.
On Ubuntu check: uname -r; ls /lib/modules/$(uname -r)/build/Makefile
If headers are missing, install matching vendor headers/build tree for that
kernel. If module signing is enforced, use a module signed for that kernel.
No udmabuf is required for the PS ZDMA mode.

gcc -O2 -std=c11 -Wall -Wextra bench.c -o bench
make module
sudo insmod ./lenet_zdma.ko ip_base="$IP"
sudo dmesg | tail -30
sudo ./bench zdma "$IP" - data/prep.bin 1 zdma_check.csv
sudo ./bench zdma "$IP" - data/prep.bin 1000 zdma_1000.csv
sudo ./bench zdma "$IP" - data/prep.bin data/mnist.bin zdma_mnist.csv
python3 compare.py pio_mnist.csv zdma_mnist.csv
python3 compare.py pio_mnist.csv zdma_mnist.csv cdma_mnist.csv
sudo rmmod lenet_zdma

If insmod reports No such device: inspect /sys/class/dma and kernel logs for
the FPD channels; do not take a channel away from a different active client.
If the upload times out or the A-B-A check fails, stop before performance runs.
Check the implemented IP base, PS-to-PL reachability, burst/width adaptation,
clock, reset and matching parameter export. Do not interpret a failed run as FPS.
