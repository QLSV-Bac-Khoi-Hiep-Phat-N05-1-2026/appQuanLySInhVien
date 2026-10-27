# Phạm vi và 16 User Stories — Quản lý sinh viên

Ngày chốt bản nền: 27/10/2026. Nhóm 4 người. Hoàn thành sản phẩm 01/11;
nộp PDF 02/11 trước 23:59; nộp bản cứng và ký danh sách ngày 03/11.

## Quy ước phạm vi

- Actor chính: **người quản lý** (tài khoản được chủ project cấp sẵn).
- Cả 4 tài khoản quản lý dùng chung dữ liệu lớp, sinh viên, môn học, điểm.
- Không mở đăng ký công khai, không có cổng sinh viên/phụ huynh trong đợt này.
- Một sinh viên thuộc tối đa một lớp; có thể chưa xếp lớp.
- Một điểm tổng kết cho mỗi bộ (sinh viên, môn, học kỳ), thang 0–10.
- Mã sinh viên, mã lớp, mã môn cố định sau khi tạo. Đổi mã là ngoài phạm vi.
- Đây là backlog đã chốt để triển khai, **không phải tuyên bố 16 chức năng đã xong**.
- Màn hình mẫu Câu 5 và tài liệu/sơ đồ là đầu việc bổ sung, không tính thành story nghiệp vụ.

## Danh sách và tiêu chí nghiệm thu

| ID | User story | Tiêu chí nghiệm thu | Phụ trách |
|---|---|---|---|
| US01 | Là người quản lý, tôi có thể đăng nhập để truy cập dữ liệu quản lý sinh viên. | Email/mật khẩu đúng và hồ sơ có quyền manager thì vào ứng dụng; sai thông tin, tài khoản chưa được cấp quyền hoặc lỗi mạng thì báo lỗi, không vào màn hình quản lý. | Nguyễn Văn Bắc (nhóm trưởng) |
| US02 | Là người quản lý, tôi có thể đăng xuất để kết thúc phiên làm việc. | Đăng xuất về đăng nhập; không thể dùng nút Back để xem dữ liệu phiên cũ; hủy các subscription dữ liệu khi đăng xuất. | Nguyễn Văn Bắc (nhóm trưởng) |
| US03 | Là người quản lý, tôi có thể xem hồ sơ tài khoản để kiểm tra thông tin cá nhân. | Hiển thị tên, email từ users/{uid}; không hiển thị mật khẩu; có trạng thái tải và lỗi. | Nguyễn Văn Bắc (nhóm trưởng) |
| US04 | Là người quản lý, tôi có thể cập nhật họ tên của mình để thông tin tài khoản chính xác. | Tên sau trim không trống, tối đa 150 ký tự; lưu và tải lại vẫn đúng; không sửa uid/email/role hoặc hồ sơ người khác. | Nguyễn Văn Bắc (nhóm trưởng) |
| US05 | Là người quản lý, tôi có thể xem danh sách sinh viên để tra cứu hồ sơ đang quản lý. | Hiển thị mã, tên, lớp; có trạng thái tải/rỗng/lỗi; cập nhật khi dữ liệu thay đổi. | Nguyễn Bá Phát |
| US06 | Là người quản lý, tôi có thể thêm sinh viên để lưu hồ sơ mới. | Mã không trùng; tên/ngành bắt buộc; tuổi nguyên 1–120; email để trống hoặc hợp lệ; lớp được chọn phải tồn tại; lưu và tải lại được từ Firebase. | Nguyễn Bá Phát |
| US07 | Là người quản lý, tôi có thể sửa hồ sơ sinh viên để cập nhật thông tin. | Sửa tên/ngành/tuổi/email/lớp theo quy tắc US06; không đổi mã; không tạo lại bản ghi đã bị xóa; không báo thành công nếu ghi lỗi. | Nguyễn Bá Phát |
| US08 | Là người quản lý, tôi có thể xóa sinh viên để loại bỏ hồ sơ không còn sử dụng. | Có xác nhận; hủy thì giữ nguyên; nếu sinh viên có điểm thì chặn xóa và giải thích; nếu chưa có điểm thì xóa và làm mới danh sách. Phải bổ sung cơ chế kiểm tra ràng buộc đồng thời trước khi mở quyền delete. | Nguyễn Bá Phát |
| US09 | Là người quản lý, tôi có thể xem danh sách lớp để tra cứu lớp hiện có. | Hiển thị mã, tên, ngành, khóa; có tải/rỗng/lỗi và cập nhật dữ liệu. | Nguyễn Minh Khôi |
| US10 | Là người quản lý, tôi có thể tạo lớp để tổ chức sinh viên theo lớp học. | Mã không trùng; tên/ngành/khóa không trống; tên/ngành tối đa 150 ký tự, khóa tối đa 30; dữ liệu được lưu Firebase. | Nguyễn Minh Khôi |
| US11 | Là người quản lý, tôi có thể sửa thông tin lớp để cập nhật tên, ngành và khóa học. | Giữ nguyên mã; kiểm tra dữ liệu như US10; sinh viên đang thuộc lớp vẫn giữ liên kết. | Nguyễn Minh Khôi |
| US12 | Là người quản lý, tôi có thể xem sinh viên của một lớp để theo dõi thành viên trong lớp. | Chỉ hiển thị sinh viên có classId bằng mã lớp đã chọn; lớp rỗng có thông báo; đổi lớp ở US07 cập nhật kết quả. | Nguyễn Minh Khôi |
| US13 | Là người quản lý, tôi có thể xem danh sách môn học để tra cứu chương trình học. | Hiển thị mã, tên, số tín chỉ; có trạng thái tải/rỗng/lỗi. | Nguyễn Huy Hiệp |
| US14 | Là người quản lý, tôi có thể thêm môn học để chuẩn bị nhập kết quả học tập. | Mã không trùng; tên bắt buộc, tối đa 150 ký tự; tín chỉ là số nguyên 1–10; lưu Firebase. | Nguyễn Huy Hiệp |
| US15 | Là người quản lý, tôi có thể lưu điểm tổng kết của sinh viên theo môn và học kỳ để ghi nhận kết quả học tập. | Chọn sinh viên/môn tồn tại và học kỳ; điểm hữu hạn từ 0 đến 10; lần đầu tạo, lần sau cập nhật đúng một bản ghi của cùng bộ khóa; các học kỳ khác nhau lưu riêng. | Nguyễn Huy Hiệp |
| US16 | Là người quản lý, tôi có thể xem bảng điểm của sinh viên để theo dõi kết quả học tập. | Chỉ hiển thị điểm của sinh viên đã chọn; hiển thị môn, học kỳ, điểm; có tải/rỗng/lỗi; cập nhật sau US15. | Nguyễn Huy Hiệp |

Mã nghiệp vụ: 1–80 ký tự gồm A–Z, a–z, 0–9, `_`, `-`. Học kỳ dùng dạng
`2026-1`, `2026-2`. Dấu `~` dành riêng để ghép ID bản ghi điểm.

## Definition of Done cho mỗi story

1. Có giao diện sử dụng được trên điện thoại, kèm tải/rỗng/lỗi khi thích hợp.
2. Dữ liệu đọc/ghi Firestore theo model và quyền truy cập chung; không chỉ dùng danh sách giả.
3. Có test trường hợp hợp lệ và không hợp lệ; test UI khi có tương tác.
4. Có ảnh minh chứng và phần giải thích trong báo cáo.
5. Có commit của đúng người làm và được kiểm tra khi ghép vào main.

## Phần nền đã chuẩn bị, phần UI còn triển khai

Đợt này cung cấp model, serializer, repository có kiểu, auth service,
khởi tạo Firebase, quy tắc truy cập và test cho phần nền. Chưa cung cấp giao diện
đăng nhập, CRUD, bảng điểm hoặc tuyên bố hoàn thành Câu 6/Câu 8.
Quyền xóa đang đóng; US08 phải bổ sung xử lý ràng buộc điểm và test trước khi mở.

## Phân công tài liệu và tích hợp

- Nguyễn Văn Bắc (nhóm trưởng): tổng hợp stories, cấu hình Firebase, tích hợp, báo cáo và demo dưới 8 phút.
- Nguyễn Bá Phát: phân tích đối tượng, Class Diagram, sơ đồ thêm/sửa sinh viên.
- Nguyễn Minh Khôi: wireframe toàn bộ màn hình, ít nhất 5 flow; sơ đồ tạo lớp; 1 layout mẫu Câu 5.
- Nguyễn Huy Hiệp: sơ đồ nhập điểm; tổng hợp kiểm thử và phần quyền riêng tư/đạo đức.
- Nguyễn Văn Bắc (nhóm trưởng) vẽ sơ đồ đăng nhập. Tổng cộng tối thiểu 5 sơ đồ thuật toán.
- Mỗi người tự viết test, báo cáo, tài liệu code và commit của module mình.
