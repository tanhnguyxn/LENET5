# Các file cần đọc khi đối chiếu

1. `Parallel_Data_Loader.v` (mới): phát/nhận liên tục trên ba đường RAM riêng.
   w_issue_r/x_issue_r/b_issue_r đếm slot phát; *_tag_r giữ vị trí buffer;
   *_pending_r và *_real_r phân biệt request thật với slot đệm zero.
   *_done_r đếm slot đã nhận/xử lý. Không có FSM phụ tuần tự theo từng từ.
2. `Conv_Controller.v`: dùng loader, giảm 15 → 8 state; giữ đường psum,
   DRAIN và output wait. Nạp bias đầu nhóm, thay weight mỗi input channel.
3. `FC_Controller.v`: dùng loader cho ba luồng; giảm 15 → 6 state.
   Giữ riêng LOAD và SEND để không nhân bằng weight cũ.
4. `Lenet5_Engine.v`: route weight và bias độc lập với activation;
   không mux ba response thành một response nữa.
5. `tests/tb_cin2.v`: mô hình ba cổng đọc độc lập thay shared rd_kind.
6. `tests/tb_loader.v` (mới): kiểm tra loader độc lập.
7. Scripts chạy test: thêm tb_loader, tự lấy module mới.

Lenet5_Core, Arbiter và host map không đổi. Tất cả module tính toán, memory
cơ sở, Pool_Controller giữ nguyên nội dung. Hãy thêm toàn bộ 21 file RTL vào
project hoặc dùng scripts đi kèm; không chỉ thay riêng Conv_Controller.

Không đổi ACC_WIDTH xuống 32 trong bản này: giữ 48 để tách riêng tác động
của tối ưu điều khiển và nạp dữ liệu. Không tăng số bank. Không có DMA.
Mỗi controller có instance loader riêng; chúng không chạy đồng thời do
Engine chạy tuần tự các layer. Việc chia sẻ thêm loader giữa controller
là một lựa chọn tài nguyên khác, chưa thực hiện/đánh giá trong bản này.
