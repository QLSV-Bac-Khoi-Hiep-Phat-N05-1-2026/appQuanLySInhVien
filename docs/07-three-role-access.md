# Ba vai trò và backend tài khoản

- Admin duyệt hồ sơ giảng viên đã xác minh email, phân công lớp và khóa tài khoản.
- Giảng viên chỉ quản lý sinh viên và điểm thuộc lớp được giao; cấp tài khoản bằng email thật của sinh viên.
- Sinh viên chỉ đọc học vụ của mình và sửa số điện thoại, email liên hệ, địa chỉ. Email liên hệ khác email đăng nhập.
- Vai trò, trạng thái và liên kết tài khoản chỉ được backend ghi. Không gửi khóa quản trị trong ứng dụng.
- Tài khoản thử vai trò `manager` cũ không được cấp quyền ba vai trò; danh sách Admin bỏ qua các tài khoản này.

## Chạy demo Flutter

```powershell
flutter pub get
flutter run -d emulator-5554
```

Chọn Trải nghiệm demo và vai trò. Demo dùng dữ liệu mẫu trên máy, không gửi email thật.

## Backend cục bộ cho chức năng quản trị tài khoản

Cần Node >=22 và thông tin xác thực quản trị hợp lệ. Ưu tiên Application Default Credentials trên máy chủ. Không commit credential hoặc đặt credential trong Flutter.

```powershell
npm --prefix backend ci
$env:FIREBASE_PROJECT_ID='quan-ly-sinh-vien-ba83b'
# Chỉ trên máy phát triển đã đăng nhập Firebase CLI của chủ dự án:
$env:USE_FIREBASE_CLI_CREDENTIALS='true'
$env:HOST='127.0.0.1'
npm --prefix backend start
```

Chế độ dùng Firebase CLI cần cài dependency trong tools/firestore-tests và chỉ được bind loopback. Android Emulator gọi máy chủ cục bộ qua 10.0.2.2; cần cấu hình mạng Android debug phù hợp khi dùng HTTP. Bản phát hành phải dùng backend HTTPS và cấu hình ACCOUNT_API_URL:

```powershell
flutter run -d emulator-5554 --dart-define=ACCOUNT_API_URL=https://YOUR_BACKEND_HOST
```

Chưa có backend HTTPS được triển khai trong nhánh này. Đăng nhập và đọc dữ liệu Firestore không cần backend riêng; duyệt tài khoản, phân công lớp, đăng ký giảng viên và cấp tài khoản cần backend đang hoạt động.

Email đặt mật khẩu dùng browser API key của project (đọc từ cấu hình Identity Platform hoặc FIREBASE_WEB_API_KEY), tránh dùng Android key cho trang xử lý email. Không lưu mật khẩu người dùng. Chủ tài khoản tự đặt mật khẩu từ email mới nhất.

Khởi tạo Admin đầu tiên (chỉ chủ dự án chạy, từ chối nếu đã có Admin khác):

```powershell
node backend/bootstrap-admin.mjs YOUR_ADMIN_EMAIL
```

## Kiểm thử

```powershell
flutter analyze --no-pub
flutter test --no-pub
npm --prefix tools/firestore-tests ci
npm --prefix backend ci
$env:FIREBASE_PROJECT_ID='demo-qlsv'
./tools/firestore-tests/node_modules/.bin/firebase.cmd emulators:exec --config firebase.test.json --only auth,firestore --project demo-qlsv "npm --prefix tools/firestore-tests test && npm --prefix backend test"
```

Các bài test backend dùng Firebase Auth/Firestore Emulator; không gửi email thật. Bộ kiểm thử không thay thế nghiệm thu đầy đủ trên thiết bị với tài khoản thật.

Firestore rules ba vai trò đã được triển khai lên project của nhóm ngày 30/10/2026. Tài khoản thử `manager` cũ không còn quyền quản lý dữ liệu. Thao tác xóa cloud tiếp tục đóng.
