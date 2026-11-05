# LeNet5 Parallel Load — bản tối ưu, chưa có DMA

## Đọc trước

Top vẫn là `Lenet5_Core`. Giữ nguyên host map, model mặc định 6/16/120/84,
Q8.8, accumulator 48 bit, 4 bank × 25 PE và golden output của bản streaming.
Dùng trọn bộ thư mục này, không trộn Controller mới với Engine cũ.
Verilog 2001; không for/genvar/generate/integer, không task/function trong RTL.
Comment RTL tiếng Anh, chân _i/_o, thanh ghi _r, dây _w.

## Thay đổi chính

- Thêm `Parallel_Data_Loader`: ba đường đọc RAM độc lập cho input/weight/bias.
- Conv đọc weight và bias đồng thời, phát một yêu cầu weight mỗi clock.
- FC đọc input, weight, bias đồng thời. Đoạn sau giữ bias đã nạp, không đọc lại.
- Engine bỏ đường mux dữ liệu tham số chung; activation vẫn đi qua rd_* cũ,
  weight và bias có weight_rd_* / bias_rd_* riêng.
- Conv gộp chốt weight và clear lượt quét thành PREPARE; không xóa psum RAM.
- Ghi output cuối đồng thời báo done, không cần state FINISH riêng.
- Không thay đổi Pool, phép nhân, adder tree, saturation hoặc memory arrays.

## FSM Conv: 8 state

IDLE → LOAD_DATA → PREPARE → STREAM → DRAIN → OUT_REQ → OUT_WAIT → WRITE.

LOAD_DATA: loader chạy hai luồng tham số độc lập. Bias chỉ nạp khi ic_r=0.
PREPARE: chốt weight và clear line buffer/counter trước quét.
STREAM: đọc input liên tục, tạo window, đưa vào PEA 6 tầng.
DRAIN: đợi committed_r bằng số pixel output; còn channel thì tăng ic_r và
quay về LOAD_DATA. Hết channel thì OUT_REQ.
OUT_REQ/OUT_WAIT: đọc bốn tổng cuối từ RAM đồng bộ.
WRITE: ghi từng bank; đổi pixel, đổi nhóm (group+=4), hoặc done và về IDLE.
Khối cộng/ghi psum vẫn chạy độc lập trong STREAM/DRAIN.

## FSM FC: 6 state

IDLE → LOAD_DATA → LOAD → SEND → DOT_WAIT → WRITE.

LOAD_DATA: ba luồng cùng chạy; chỉ tiến khi đã nhận đủ, không dựa trên số
request đã phát. LOAD chốt weight. SEND ở clock sau để PE dùng weight mới.
DOT_WAIT tích lũy; còn đoạn 25 input thì quay lại LOAD_DATA.
WRITE xuất tối đa 4 neuron; đổi nhóm hoặc done và về IDLE.
FC chưa chạy chồng các đoạn tính toán và chưa có double-buffer prefetch.

## Loader và hợp đồng timing

Mỗi memory nhận một request mỗi clock, trả data/valid theo RAM đồng bộ một
chu kỳ hiện có. Không có ready; KHÔNG nối trực tiếp AXI/DDR hoặc RAM có
latency biến đổi. Metadata (slot, real/zero) được chốt cùng cạnh RAM nhận
request; cạnh sau loader dùng metadata đó để ghi đúng lát buffer.

Weight: 100 slot (4×25), input: 25 slot, bias: 4 slot. Bank/tap không hợp lệ
không đọc RAM, buffer nhận zero. Tất cả slot đều được xử lý kể cả bank dư;
đây là lựa chọn giữ logic đơn giản, chưa tối ưu riêng thời gian nhóm cuối.
Bias_enable=0 giữ nguyên buffer bias. Conv không dùng đường input của loader.

Các tham số group, kích thước, base, stride phải ổn định trong cả lần load.
Done chỉ lên sau khi đủ 100/25/4 slot đã xử lý. loader_started_r ngăn đọc nhầm
cờ done còn từ lượt trước. Reset hủy request đang chờ; chủ điều khiển phải
khởi động lại, không tiếp tục giữa lượt.

## Giao tiếp và memory map giữ nguyên

Host bus word-addressed, data mặc định 64 bit; payload Q8.8 ở 16 bit thấp.
Ghi khi idle; khi busy các ghi host bị bỏ qua. Nạp đủ ảnh/tham số rồi start.
Không có bộ đếm xác nhận ảnh đầu vào đã nạp đủ.

| Địa chỉ từ | Nội dung |
|---|---|
| 0x00000 | Ghi start bit 0; đọc busy bit 0, done bit 1 |
| 0x10000+x | 784 pixel ảnh grayscale 28×28 |
| 0x20000+x | Conv1 weight |
| 0x30000+x | Conv2 weight |
| 0x40000+x | FC1 weight |
| 0x50000+x | FC2 weight |
| 0x60000+x | FC3 weight |
| 0x70000+layer*0x2000+x | Bias layer 0..4 |
| 0x80000 | class[19:16], score[15:0] |
| 0x90000+x | 10 logits signed |

Weight Conv: [oc][ic][ky][kx]; FC: [out][in]. Ảnh/feature map: CHW.
Mỗi lần nhận diện mới cần nạp lại ảnh. Weight/bias có thể giữ lại.

## Chạy kiểm thử

Linux: `bash tests/run_iverilog.sh` (Icarus Verilog).
Windows Vivado: `powershell -ExecutionPolicy Bypass -File tests/run_vivado.ps1`.
ModelSim: `do tests/run_modelsim.do` từ thư mục RTL.
Script tự lấy tất cả *.v, bao gồm Parallel_Data_Loader.v.
Chỉ Icarus được chạy cho bản này; hai script khác cung cấp để người dùng chạy.
Xem VALIDATION.md và tests/results để biết kết quả thật.

## Phạm vi

Đây là tối ưu đường nạp nội bộ, không phải DMA. Chưa thêm AXI/Avalon,
chưa chạy board, chưa đo Fmax/tài nguyên/accuracy checkpoint MNIST.
Không suy ra FPS chỉ từ clock mô phỏng. Cần synthesis/implementation để
kiểm tra RAM mapping và đường timing sau khi tách các cổng đọc.
Giữ nguyên giới hạn model/địa chỉ của bản trước (memory 16-bit address,
không quá 65536 từ/mảng; Conv width tối đa 28, psum depth mặc định 576).
BASELINE_README.md chỉ mô tả bản trước để tham khảo, không phải RTL mới.
