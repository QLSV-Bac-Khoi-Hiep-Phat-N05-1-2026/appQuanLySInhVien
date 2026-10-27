# Nghiệm thu phần nền GĐ1 — 27/10/2026

## Code và contract

- Có 16 user stories, tiêu chí nghiệm thu và phân công theo tên 4 thành viên.
- Có 5 model, mapping Firestore, repository có kiểu, kiểm tra trùng mã/references.
- Có AuthService, khởi tạo Firebase có retry, emulator config và rules.
- Giữ bài Generics/Pavlova và các sửa đổi màn hình có sẵn trong bản local.
- Có hợp đồng module, quy trình PR và hợp đồng xử lý xóa sinh viên có điểm ở
  [bàn giao nhóm](04-team-handoff.md). US08 chưa triển khai; delete vẫn đóng.
- Có CI cho Flutter analyze/tests và Firestore rules emulator, cùng PR template.

## Kiểm chứng kỹ thuật

| Hạng mục | Kết quả |
|---|---|
| flutter analyze | PASS — No issues found |
| flutter test | PASS — 17 tests |
| Firestore rules emulator | PASS — 6 tests, project giả demo-qlsv |
| Firestore database | PASS — (default), Native/Standard, asia-southeast1, freeTier=true |
| Cloud rules/indexes | PASS — deploy thành công vào đúng project |
| Email/Password | PASS — provider được bật bằng Firebase CLI |
| 4 tài khoản thử | PASS — Bắc, Phát, Khôi, Hiệp đều đăng nhập và đọc profile của mình |
| Cloud đọc/ghi | PASS — tạo lớp, sinh viên, môn, điểm thử và đọc lại đúng |
| Cloud truy cập không đăng nhập | PASS — bị rules từ chối |
| Cloud điểm ngoài 0–10 và tự nâng quyền | PASS — bị rules từ chối, dữ liệu hợp lệ giữ nguyên |
| Android SDK | PASS — Flutter doctor nhận SDK 36, Java 21 và giấy phép |
| Android debug APK | PASS — build APK thành công; có artifact tại build/app/outputs/flutter-apk/app-debug.apk |

Bằng chứng cloud không chứa mật khẩu/token nằm trong
[05-g1-cloud-evidence.json](05-g1-cloud-evidence.json). Mật khẩu ngẫu nhiên của
4 tài khoản thử được lưu riêng trên máy nhóm trưởng, ngoài Git và OneDrive.
Không có service-account key mới hoặc thay đổi gói thanh toán.

Cloud được kiểm chứng bằng phiên Firebase Auth của tài khoản thử, không dùng
quyền admin để giả lập việc client đọc/ghi. Chỉ bước cấp profile manager dùng
quyền chủ project, đúng phạm vi được người dùng xác nhận.

## Môi trường tái lập

Flutter 3.47.2 / Dart 3.13.2, Java 21, Node 24. Giữ pubspec.lock và npm lockfile.
Trên Windows, nếu Flutter analyzer lỗi LSP ở đường dẫn có dấu, dùng đường dẫn
checkout không dấu. Không bỏ qua analyzer của code.

Rules tests dùng firebase.test.json với cổng 18080 để không đụng dịch vụ cổng 8080.
Unit tests và emulator tests không thay thế kết quả cloud. Chưa kiểm tra giao diện
trên thiết bị Android thật/emulator; build APK không đồng nghĩa nghiệm thu UI.

## Trạng thái bàn giao

G1-01 chỉ đánh Đạt sau khi PR nền đã merge và các kiểm tra kỹ thuật đạt. G1-02
chỉ đánh Đạt sau khi build Android cũng xác nhận thành công. Các việc G1-03,
G1-04, G1-05 do Phát, Khôi, Hiệp thực hiện và tự mở PR, không đánh thay.

Chưa triển khai UI của 16 stories, chưa hoàn thành Câu 6/Câu 8 cho toàn bộ dự án.
Không đánh dấu đã có review của Hiệp nếu Hiệp chưa review thực tế ở việc G1-05.
