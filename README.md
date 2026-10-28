# Ứng dụng quản lý sinh viên

Ứng dụng Flutter/Dart.

## Bài tập Generics

- Theo [tài liệu của giảng viên](https://nglthu.github.io/flutter_docs/docs/generic_class).
- Lớp dùng chung [Genericclass<T>](lib/models/generic_class.dart) có `id`, `name`, `description`, constructor và các hàm get/set.
- Lớp có sẵn [Student](lib/models/student.dart) kế thừa `Genericclass<Object>`: `id` là mã sinh viên, `name` là họ tên, `description` là ngành học. `age` là thuộc tính riêng của sinh viên.
- [GenericsScreen](lib/screens/generics_screen.dart) minh họa gán `Student` cho biến `Object`, lấy `Type` bằng `runtimeType`, hiển thị thông tin sinh viên.

Trong Dart, `runtimeType` trả về `Type` để xem thông tin lớp; Dart không có lớp tên `Class` như Java.
Tài liệu: [Generics](https://dart.dev/language/generics), [Object.runtimeType](https://api.dart.dev/dart-core/Object/runtimeType.html).

## Chạy bài

```sh
flutter pub get
flutter run
```

Tại Home, chọn **Thực hành Generics**.

## Nội dung nộp

- Code chính: ba file được liên kết ở trên.
- README: [README trên GitHub](https://github.com/QLSV-Bac-Khoi-Hiep-Phat-N05-1-2026/appQuanLySInhVien/blob/main/README.md).
- Ảnh minh họa màn hình Flutter (xuất bằng widget test): [generics.png](docs/screenshots/generics.png).
- Commit: xem commit **Hoàn thành bài tập Generics** trong [lịch sử commit](https://github.com/QLSV-Bac-Khoi-Hiep-Phat-N05-1-2026/appQuanLySInhVien/commits/main/).

![Kết quả bài tập Generics](docs/screenshots/generics.png)

## Bài tập lớn cuối kỳ

- [16 user stories và nghiệm thu](docs/01-user-stories.md).
- [Model, Firestore, API và hướng dẫn thiết lập](docs/02-data-and-firebase.md).
- [Trạng thái kiểm chứng](docs/03-verification.md).

## Bản trình diễn giao diện — 28/10/2026

- Trang chủ theo mẫu học tập: thẻ xanh lá/vàng/xanh dương, banner và điều hướng thích ứng điện thoại/máy tính.
- Có màn hình mẫu học tập Câu 5 riêng; giữ Generics và Pavlova.
- Sinh viên: tìm kiếm, lọc lớp, xem hồ sơ, thêm/sửa; lớp: thêm/sửa/xem thành viên; hồ sơ: sửa tên và đăng xuất.
- Web chạy chế độ trình diễn với dữ liệu mẫu lưu trên trình duyệt. Dữ liệu demo tách biệt Firebase; không tự nạp mẫu vào cloud.
- Android có form đăng nhập Firebase và lựa chọn trình diễn. Tầng dữ liệu Firebase đã có kiểm chứng nền; giao diện Android mới cần nghiệm thu trên thiết bị.
- Xóa sinh viên có xác nhận và chặn khi có điểm trong demo. Xóa cloud vẫn khóa, chờ giải pháp ràng buộc đồng thời.
- Module thêm môn/nhập và xem điểm của Hiệp đang chờ PR tích hợp; chưa tuyên bố 16 stories hoàn thành.

Chạy bản web:

```sh
flutter pub get
flutter run -d chrome --web-port 51238
```

Chọn **Khám phá bản trình diễn**. Có thể show theo thứ tự: trang chủ → thêm lớp → thêm sinh viên → tìm/lọc/sửa hồ sơ → cập nhật tên → màn hình mẫu Câu 5. Dữ liệu còn sau khi tải lại cùng địa chỉ/cổng trên cùng trình duyệt.

Kiểm tra: `flutter analyze`, `flutter test`. Bộ test bao gồm lưu demo/mở lại, trùng mã, reference lớp, ràng buộc xóa, upsert điểm, form nhập sai/đúng và bố cục 390px/1440px.

- [Hướng dẫn nhận việc cho Bắc, Phát, Khôi, Hiệp](docs/04-team-handoff.md).
- [Bằng chứng kiểm tra Firebase cloud](docs/05-g1-cloud-evidence.json).
