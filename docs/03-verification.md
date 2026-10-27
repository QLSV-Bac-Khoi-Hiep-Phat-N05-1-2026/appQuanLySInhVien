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
Tái kiểm chứng G1-05 — 27/10/2026

Kết quả chạy lại trên môi trường cập nhật: Flutter 3.47.8 / Dart 3.13.7, Node 24.22.0.

| Hạng mục | Kết quả thực tế |
|---|---|
| flutter analyze | PASS — No issues found |
| flutter test | PASS — 21 tests |
| Firestore Rules Emulator | PASS — 6 tests, project giả demo-qlsv |
| Cổng emulator | 18080 bị Firebase CLI từ chối; chạy thành công bằng config tạm cổng 18081; config tạm đã dọn |
| Firebase cloud | Không được truy cập trong lượt kiểm tra này |

GitHub PR #1 (head b098fd5) đã merge; checks “Flutter analyze and tests” và “Firestore rules emulator” đều success. GitHub API không có review event hoặc issue comment. Rà soát hồi cứu ghi nhận finding P2: validator model/rules chấp nhận kỳ ngoài hợp đồng (ví dụ 2026-3); chuyển xử lý cho US15. Không ghi nhận approval event của Hiệp trên PR đã merge.

npm ci cài thành công dependency theo lockfile; npm báo 11 advisory trong dev dependency tree (6 moderate, 5 high). Không chạy npm audit fix.

Báo cáo G1-05 và ảnh giao diện minh chứng: docs/08-gd1-05-report.md, docs/screenshots/subjects.png.

## Ghi chú cập nhật trạng thái giao diện

Mục “Chưa triển khai UI của 16 stories” ở phần nghiệm thu phía trên mô tả trạng thái nền G1 tại thời điểm PR #1 merge. Sau đó, US13–US14 có màn hình danh sách/thêm môn trong working tree; chưa merge và chưa kiểm thử Firebase cloud. Widget tests hiện có dùng FakeFirestore.

## Tái kiểm chứng mới nhất G1-05 — 27/10/2026
Kết quả chạy lại trên môi trường cập nhật: Flutter 3.47.8 / Dart 3.13.7, Node 24.22.0.

| Hạng mục | Kết quả thực tế |
|---|---|
| flutter analyze | PASS — No issues found |
| flutter test | PASS — 21 tests |
| Firestore Rules Emulator | PASS — 6 tests, project giả demo-qlsv |
| Cổng emulator | 18080 bị Firebase CLI từ chối; chạy thành công bằng config tạm cổng 18081; config tạm đã dọn |
| Firebase cloud | Không được truy cập trong lượt kiểm tra này

GitHub PR #1 (head b098fd5) đã merge; checks “Flutter analyze and tests” và “Firestore rules emulator” đều success. GitHub API không có review event hoặc issue comment. Rà soát hồi cứu ghi nhận finding P2: validator model/rules chấp nhận kỳ ngoài hợp đồng (ví dụ 2026-3); chuyển xử lý cho US15. Không ghi nhận approval event của Hiệp trên PR đã merge.

npm ci cài thành công dependency theo lockfile; npm báo 11 advisory trong dev dependency tree (6 moderate, 5 high). Không chạy npm audit fix.

Báo cáo G1-05 và ảnh giao diện minh chứng: docs/08-gd1-05-report.md, docs/screenshots/subjects.png.
Ghi chú cập nhật trạng thái giao diện

Mục “Chưa triển khai UI của 16 stories” ở phần nghiệm thu phía trên mô tả trạng thái nền G1 tại thời điểm PR #1 merge. Sau đó, US13–US14 có màn hình danh sách/thêm môn trong working tree; chưa merge và chưa kiểm thử Firebase cloud. Widget tests hiện có dùng FakeFirestore.
## Tái kiểm chứng mới nhất G1-05 — 27/10/2026

- Môi trường: Flutter 3.47.8 / Dart 3.13.7, Node 24.22.0, Temurin Java 21.0.12.1 (portable, chỉ dùng cho tiến trình test).
- flutter analyze: PASS — No issues found.
- flutter test: PASS — 21 tests.
- Firestore Rules Emulator: PASS — 6 tests, project giả demo-qlsv, cổng chuẩn 18080.
- Chẩn đoán lần chạy đầu: Java trên PATH là 26.0.1; emulator thoát mã 3221225786. Dùng JDK 21 portable sau đó thì test đạt. Không truy cập Firebase cloud và không thay đổi cài đặt Java hệ thống.
- PR #1 head b098fd5: hai GitHub checks Flutter analyze/tests và Firestore rules emulator success; GitHub API không trả review event/comment. Rà soát hồi cứu ghi nhận finding P2 về validator kỳ học, chuyển follow-up cho US15.
