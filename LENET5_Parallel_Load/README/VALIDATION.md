# Kiểm thử và so sánh

## Môi trường và phạm vi

Icarus Verilog 12, `-g2001 -Wall`. 21 RTL module, không cảnh báo biên dịch.
Kiểm tra token sau khi bỏ comment: không for/genvar/generate/integer,
SystemVerilog, task/function trong RTL. Testbench có task/repeat/while.

| Test | Kiểm tra |
|---|---|
| tb_pea | Số signed, pipeline bubble, tổng rộng, bias/saturation/ReLU |
| tb_loader | Đọc ba memory đồng thời, dữ liệu mã hóa theo địa chỉ, bank dư, tap dư, giữ bias giữa đoạn, reset giữa lượt rồi chạy lại |
| tb_cin2 | Conv 7×7×2, Cout=5; 45 output, 36 window, bank cuối dư |
| tb_tails | 5/6/27/26, hai ảnh liên tiếp, mọi giá trị ở bảy stage |
| tb_classic | 6/16/120/84, hai ảnh liên tiếp, mọi giá trị ở bảy stage |
| tb_tiny | 4/8/64/32, hai ảnh liên tiếp, mọi giá trị ở bảy stage |

Ba test mạng đối chiếu 27.166 giá trị trung gian với cùng reference integer
của baseline. Cin2 thêm 45 giá trị. Kiểm tra ghi đúng/đủ địa chỉ, số lần gọi
PEA, busy/done, readback, ghi host lúc busy bị bỏ qua, tie argmax chọn class đầu.
Vector thử là dữ liệu tổng hợp, không phải checkpoint MNIST của người dùng.

## Kết quả số chu kỳ

Baseline là LENET5_Modular_Streaming, không phải bản NoLoops cũ hơn.
Cùng vector, cấu hình, 4 bank × 25 PE, accumulator 48 bit và quy tắc Q8.8.
Các log baseline được lưu riêng trong tests/baseline_results.

| Test | Baseline | Parallel Load | Giảm chu kỳ |
|---|---:|---:|---:|
| Cin2 | 1424 | 764 | 46,35% |
| Tails | 38675 | 24888 | 35,65% |
| Classic | 200001 | 76854 | 61,57% |
| Tiny | 61531 | 27783 | 54,85% |

Mỗi cấu hình mạng có hai ảnh, hai lần cho cùng số chu kỳ và 0 lỗi.
Pipeline Conv vẫn max_in_flight=6, max_consecutive_windows=24.
Các bộ đếm mạng bắt đầu sau bước kiểm tra busy, không phải latency tuyệt đối
start-to-done. Không gồm thời gian host nạp ảnh/tham số.
Không quy đổi các số này thành FPS hoặc Fmax khi chưa chạy implementation.

## Giao tiếp và giới hạn

Top Lenet5_Core giữ nguyên cổng. Conv/FC thay rd_kind_o bằng hai đường
weight_rd_* và bias_rd_* mới; rd_* còn lại chỉ dành cho activation.
Testbench Conv trực tiếp đã cập nhật theo giao tiếp mới.
Loader yêu cầu fixed-latency one-cycle RAM, ordered responses, không ready.
Delay biến đổi hoặc mất valid là vi phạm hợp đồng, không có retry tự động.
Synthesis/BRAM inference/utilization/timing/board chưa thực hiện.
Vivado/ModelSim scripts cung cấp nhưng chưa chạy trong lần kiểm chứng này.
