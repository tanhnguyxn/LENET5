# LeNet: modular memories and streaming convolution

Bản này tách bộ nhớ khỏi Engine/Conv Controller và sửa Conv để thực sự chạy
nhiều cửa sổ đồng thời qua pipeline PEA. Các layer vẫn chạy tuần tự và dùng
chung một PEA 4 bank × 25 PE.

## Cin lớn hơn 1

Với một output channel `oc` và vị trí `(oy,ox)`:

```text
output[oc,oy,ox] = activation(saturate(
    bias[oc] + tổng qua ic,ky,kx của ((input[ic,oy+ky,ox+kx]*weight[oc,ic,ky,kx]) >>> 8)
))
```

Cin=2 là cộng hai tổng từ hai input channel của cùng một layer.
Mỗi input channel dùng một lát kernel riêng `weight[oc][ic]`.
Bias chỉ cộng một lần sau khi đủ Cin. Không bão hòa partial sum từng channel.
Trong Conv, activation là ReLU. Với FC3 không có ReLU.

## Các module bộ nhớ

| Module | Vai trò | Giao tiếp |
|---|---|---|
| `Sync_RAM_1R1W.v` | Mảng nhớ cơ sở, không reset toàn bộ RAM | 1 cổng đọc đồng bộ + 1 cổng ghi |
| `Ping_Pong_Memory.v` | Hai vùng activation A/B | Đọc nguồn, ghi đích đối diện; nạp ảnh vào A khi idle |
| `Weight_Memory.v` | Weight của Conv1/Conv2/FC1/FC2/FC3 | Nạp theo layer; đọc một từ mỗi clock |
| `Bias_Memory.v` | Bias của 5 layer có tham số | Nạp theo layer; đọc một từ mỗi clock |
| `Partial_Sum_Memory.v` | 4 bank tổng tích lũy qua Cin | Mỗi bank 576 từ × 48 bit mặc định; 4 đọc/4 ghi song song |
| `Line_Buffer_Memory.v` | Lưu 4 hàng pixel trước | Tap đọc tổ hợp; cập nhật theo pixel hợp lệ |

Engine không còn chứa mảng activation/weight/bias; Conv Controller không còn
chứa mảng partial sum. `Line_Buffer_5x5` giữ bộ đếm và thanh ghi cửa sổ, gọi
`Line_Buffer_Memory` để lưu hàng. Thanh ghi weight trong từng PE vẫn giữ tại PE.

Các module mô tả RAM trong RTL; chưa khẳng định ánh xạ BRAM cụ thể.
`Sync_RAM_1R1W` dùng đọc đồng bộ, phù hợp để công cụ suy diễn RAM.
Line memory ngắn có tap đọc tổ hợp, có thể thành distributed RAM hoặc FF.
Cần kiểm tra synthesis report trên FPGA đích; chưa có primitive/IP hãng.

## Flow và pipeline thực sự

1. Engine nhận start, chọn Conv1.
2. Conv FSM nạp bias và weight cho nhóm tối đa 4 output channel.
3. `LOAD` chốt weight vào PE; `CLEAR` khởi tạo lượt quét input channel.
4. `STREAM` phát một yêu cầu pixel mỗi clock. RAM trả dữ liệu với latency 1.
5. Line buffer tạo các cửa sổ hợp lệ; mỗi cửa sổ được gửi ngay vào PEA.
6. PEA gồm 1 tầng product register và 5 tầng adder tree. Các cửa sổ chạy chồng.
7. Nhánh nhận kết quả độc lập đọc partial sum, chốt dot/address rồi cộng-ghi
   ở clock kế tiếp. Có thể nhận một kết quả gồm 4 tổng mỗi clock.
8. `DRAIN` đợi tất cả tổng được ghi xong trước khi đổi input channel/weight.
9. Hết Cin mới đọc partial sum cuối, cộng bias, saturate, ReLU và ghi output.
10. Hết output group thì Conv báo done. Engine chạy Pool1, Conv2, Pool2,
    FC1, FC2, FC3, cuối cùng argmax.

### Ghép đúng địa chỉ với kết quả

PEA có độ trễ cố định và trả kết quả đúng thứ tự. `result_r` tăng chỉ khi
`pea_valid_i=1`; giá trị đó chính là địa chỉ spatial của dot đang trả về.
`accumulate_addr_r` và `dot_r` giữ địa chỉ/dữ liệu cùng một nhịp với đọc RAM.
`accumulate_valid_r` cho phép ghi ở nhịp tiếp theo. `committed_r` đếm số ghi
đã thực hiện. Chỉ đổi channel khi `committed_r == output_pixels_w`.
Không có channel/group cũ còn trong pipeline khi thay weight.

Ví dụ các cửa sổ A/B/C được nhận ở ba cạnh clock liên tiếp:

| Cạnh | Nhân | Cộng 0 | Cộng 1 | Cộng 2 | Cộng 3 | Cộng 4 |
|---|---|---|---|---|---|---|
| C1 | A | | | | | |
| C2 | B | A | | | | |
| C3 | C | B | A | | | |
| C4 | | C | B | A | | |
| C5 | | | C | B | A | |
| C6 | | | | C | B | A |
| C7 | | | | | C | B |
| C8 | | | | | | C |

Controller nhận `valid` tại cạnh tiếp theo sau khi thanh ghi đầu ra cập nhật.
Sau đó còn bước đọc/cộng/ghi partial sum. Không được hiểu C6 là thời điểm
output cuối của layer đã ghi vào activation RAM.

### Phạm vi tốc độ

- Trong vùng pixel tạo được window: Conv cấp một cửa sổ mỗi clock.
- Có bubble tại đầu ảnh và 4 pixel đầu mỗi hàng; còn thời gian nạp weight,
  drain và ghi output. Không phải toàn inference có output mỗi clock.
- Ghi output cuối được serialize qua cổng activation một từ mỗi clock,
  sau khi hoàn thành lượt quét của input channel cuối.
- Weight/bias vẫn nạp tuần tự qua cổng đọc dùng chung; chưa chia weight thành
  4 bank để nạp song song cho 4 bank tính toán.
- FC vẫn xử lý từng chunk 25 phần tử và đợi dot hoàn thành. FC dùng PEA thật
  nhưng chưa có prefetch để chạy chồng các chunk.
- Hai vùng A/B luân phiên qua layer; chưa overlap các layer hoặc DMA.

## Thứ tự layer, model và số học

Mặc định: ảnh 28×28, CONV1_CH=6, CONV2_CH=16, FC1_NEURONS=120,
FC2_NEURONS=84. Tiny: 4/8/64/32 (11.578 tham số).

| Stage | Xử lý | Đọc → ghi | Shape mặc định |
|---|---|---|---|
| 0 | Conv1 5×5 valid + ReLU | A → B | 1×28×28 → 6×24×24 |
| 1 | MaxPool 2×2 | B → A | 6×24×24 → 6×12×12 |
| 2 | Conv2 5×5 valid + ReLU | A → B | 6×12×12 → 16×8×8 |
| 3 | MaxPool 2×2 | B → A | 16×8×8 → 16×4×4 |
| 4 | FC1 + ReLU | A → B | 256 → 120 |
| 5 | FC2 + ReLU | B → A | 120 → 84 |
| 6 | FC3 | A → B | 84 → 10 |

Đây là biến thể LeNet 28×28/ReLU/MaxPool của flow đã dùng, không tự đổi
thành LeNet gốc 32×32/tanh/average pooling. Flatten dùng thứ tự channel-row-column.
Q8.8 signed 16-bit, tích signed 32-bit, shift từng tích 8 bit, tổng 48-bit.
Bias thêm một lần, bão hòa [-32768,32767], rồi ReLU nếu cần. Argmax chọn class
đầu tiên khi hòa điểm. Model QAT shift sau tổng có thể khác bit với quy tắc này.

## Host và memory map

Top: `Lenet5_Core`. Clock `clk_i`, reset bất đồng bộ active-low `rst_n_i`.
Giao tiếp host là bus đơn giản, chưa phải AXI/Avalon chuẩn và chưa có DMA.
Ghi: giữ địa chỉ/data qua cạnh lên với `host_wr_valid_i=1`.
Đọc: giữ địa chỉ qua cạnh lên với `host_rd_valid_i=1`, nhận data sau cạnh đó.

| Địa chỉ từ | Nội dung |
|---|---|
| 0x00000 | Ghi bit0=start; đọc bit0=busy, bit1=done |
| 0x10000+x | 784 pixel input |
| 0x20000+x | Conv1 weight |
| 0x30000+x | Conv2 weight |
| 0x40000+x | FC1 weight |
| 0x50000+x | FC2 weight |
| 0x60000+x | FC3 weight |
| 0x70000+layer*0x2000+x | Bias, layer=0..4 |
| 0x80000 | class[19:16], score[15:0] |
| 0x90000+x | 10 logits, sign-extended lên host data |

Host data mặc định 64 bit; payload Q8.8 ở 16 bit thấp. Địa chỉ tăng 1 mỗi từ.
Nạp đủ weight/bias/ảnh, pulse start, poll done, đọc kết quả.
Ghi host khi busy bị bỏ qua. Nạp lại ảnh trước inference tiếp theo do RAM A
đã được dùng cho feature map. Reset không xóa mảng nhớ.
Weight phẳng theo `[oc][ic][ky][kx]`, FC `[out][in]`, bias `[out]`.
Các chiều model phải khớp checkpoint. Bộ nhớ tham số/activation dùng địa chỉ
16-bit; không vượt 65536 từ mỗi mảng. Bias tối đa 8192 từ/layer theo host map.

## Chạy test

Linux với Icarus Verilog:

```bash
bash tests/run_iverilog.sh
```

Windows với Vivado:

```powershell
./tests/run_vivado.ps1 -VivadoBin C:/Xilinx/Vivado/2022.2/bin
```

ModelSim (working directory là thư mục này):

```tcl
do tests/run_modelsim.do
```

RTL/testbench đều không dùng for/genvar/generate/integer/SystemVerilog.
Testbench dùng repeat/while để phát stimulus và chờ có timeout.
Xem VALIDATION.md và tests/results để biết kết quả đã thực sự kiểm tra.
