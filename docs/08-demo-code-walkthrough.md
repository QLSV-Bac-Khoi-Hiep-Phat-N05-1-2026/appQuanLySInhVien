# Kịch bản trình bày EduSpace và giải thích code

## 1. Giới thiệu khoảng 40 giây

“Em chào cô. Nhóm em trình bày EduSpace, ứng dụng quản lý sinh viên viết bằng Flutter và Dart, sử dụng Firebase Authentication để xác thực và Cloud Firestore lưu dữ liệu. Ứng dụng quản lý sinh viên, lớp, môn học và điểm theo học kỳ. Nhóm đang phát triển ba vai trò: Admin, giảng viên và sinh viên. Admin quản lý quyền và phân công lớp; giảng viên quản lý lớp được giao; sinh viên xem dữ liệu của mình và cập nhật thông tin liên hệ.”

“Bắc phụ trách nền tảng, đăng nhập, quản lý sinh viên/lớp, tích hợp dữ liệu và phân quyền. Hiệp đóng góp module môn học/bảng điểm, kiểm thử và màn hình cổng sinh viên. Phần tích hợp chung được nối qua store và callback; lịch sử PR thể hiện các lần bàn giao.”

Chỉ nhận phần mình hiểu và thực tế tham gia; các file tích hợp là công việc chung, không khẳng định một người tự viết toàn bộ mã nguồn.

## 2. Thứ tự demo khoảng 6–7 phút

1. 0:00–0:40: giới thiệu mục tiêu và hai thành viên.
2. 0:40–1:20: đăng nhập Admin thật nếu đã xác nhận dữ liệu tải được; nếu chưa thì dùng demo và nói rõ dữ liệu mẫu.
3. 1:20–2:20: dashboard → danh sách lớp → sinh viên → thêm một sinh viên thử, chỉ ra kiểm tra trùng mã và dữ liệu bắt buộc.
4. 2:20–3:30: Hiệp mở module môn và điểm: tìm môn, thêm môn hợp lệ, chọn sinh viên, thử nhập 11 để thấy chặn lỗi, rồi lưu 8.5 ở học kỳ 2026-1.
5. 3:30–4:20: chuyển vai trò demo giảng viên, giải thích chỉ có lớp được phân công; các thao tác quản lý tài khoản thật cần backend.
6. 4:20–5:20: chuyển demo sinh viên, mở hồ sơ, xem điểm, sửa liên hệ. Không có nút sửa học vụ hay nhập điểm.
7. 5:20–6:40: mở code theo hai luồng bên dưới, không đọc hết mọi dòng.
8. 6:40–7:20: báo kiểm thử và phần cần hoàn thiện. Video yêu cầu dưới 8 phút thì chừa thời gian cho thao tác chậm.

Dữ liệu demo không đồng bộ sang Firebase. Không nhập dữ liệu thật của người khác khi trình diễn. Không xóa dữ liệu cloud để minh họa: chức năng xóa cloud hiện đang khóa.

## 3. Luồng code chính của Bắc: từ lúc mở ứng dụng

### Bước 1 — lib/main.dart

`main()` gọi `WidgetsFlutterBinding.ensureInitialized()` để Flutter sẵn sàng dùng plugin. Android được bọc bởi `FirebaseAppLoader`; web mở app demo. `MyApp` tạo `MaterialApp`, đặt theme và màn hình đầu tiên là `ProjectLoginScreen`.

Cách nói: “Đây là điểm bắt đầu. Em khởi tạo môi trường rồi hiển thị màn hình đăng nhập; chưa truy vấn dữ liệu nghiệp vụ ngay.”

### Bước 2 — lib/widgets/firebase_app_loader.dart và lib/services/firebase_bootstrap.dart

Loader chạy quá trình khởi tạo Firebase qua FutureBuilder. Trong lúc chờ có tiến trình; thất bại có nút Thử lại; thành công mới mở app chính. Bootstrap sử dụng cấu hình Firebase theo nền tảng. `firebase_options.dart` chứa định danh project/client, không phải khóa quản trị.

### Bước 3 — lib/screens/project_login_screen.dart

`_open(false)` kiểm tra form, tạo AuthService, gọi `signIn`. Không cho chọn vai trò khi đăng nhập thật. Vai trò được đọc từ hồ sơ server. Tài khoản chưa active hoặc giảng viên chưa xác minh email vào PendingAccountScreen; tài khoản hợp lệ tạo ProjectStore.cloud và mở RoleSessionScreen.

`_open(true)` là luồng riêng cho demo: chọn vai trò và khởi tạo ProjectStore.demo. Phải nói rõ nút chọn vai trò không cấp quyền Firebase.

### Bước 4 — lib/services/auth_service.dart

`signIn` gọi Firebase Auth xác nhận email/mật khẩu, lấy UID, rồi đọc `users/{uid}` bằng StudentDataService. Không tìm người dùng bằng mật khẩu trong Firestore. Nếu không có hồ sơ hợp lệ, đăng xuất và báo lỗi.

`registerLecturer` gửi backend tạo tài khoản pending, sau đó đăng nhập và gửi xác minh email. `refreshProfile` làm mới token/hồ sơ. Xác minh email chỉ chứng minh quyền sở hữu email; Admin vẫn cần kiểm tra người đó là giảng viên trước khi duyệt.

### Bước 5 — lib/models/app_user.dart

Model quy định ba role admin/lecturer/student và các trạng thái active/pending/rejected/suspended. Sinh viên phải có studentId liên kết. `fromMap/toMap` chuyển giữa dữ liệu Firestore và object Dart có kiểu. Không lưu mật khẩu trong model này.

### Bước 6 — lib/screens/role_session_screen.dart

Màn hình phiên làm việc khởi tạo store và lắng nghe thay đổi. Có ba nhánh: loading, lỗi, dữ liệu sẵn sàng. Sinh viên đi vào StudentSessionScreen rồi StudentPortalScreen của Hiệp; Admin/giảng viên đi vào ProjectWorkspace. Adapter truyền dữ liệu đã được giới hạn và các callback lưu liên hệ, đặt lại mật khẩu, đăng xuất cho màn hình sinh viên.

### Bước 7 — lib/services/project_store.dart

Đây là lớp điều phối trạng thái nghiệp vụ, kế thừa ChangeNotifier. Giao diện gọi store thay vì viết Firebase rải rác trong từng màn hình.

- `initialize`: demo đọc SharedPreferences hoặc tạo dữ liệu mẫu; cloud đăng ký stream dữ liệu và theo dõi hồ sơ quyền hiện tại.
- `_active`, `_admin`, `_manage`: kiểm tra trạng thái và quyền trước thao tác. Lecturer phải sở hữu lớp liên quan; student không được ghi học vụ.
- `saveStudent`: kiểm tra dữ liệu, lớp tồn tại, mã trùng, sinh viên cần sửa có tồn tại; giữ accountUid khi sửa. Khi chuyển lớp, cả lớp cũ và mới phải thuộc phạm vi được phép.
- `saveClass/saveSubject`: xử lý danh mục và quyền Admin; assignment giảng viên là thao tác backend riêng.
- `saveGrade`: kiểm tra quyền trên sinh viên và tham chiếu môn; lưu điểm theo khóa ghép.
- `_change`: chụp trạng thái trước thao tác, chạy hành động, lưu demo; nếu thất bại phục hồi bản chụp và ném lỗi để UI thông báo. Không phải rollback tự động tất cả dữ liệu cloud.
- `_changed/notifyListeners`: báo giao diện vẽ lại khi dữ liệu thay đổi.
- `averageFor`: tính trung bình có trọng số tín chỉ từ các điểm hiện có; chưa phải quy chế GPA chính thức của trường.
- `dispose`: hủy đăng ký stream khi rời phiên, tránh cập nhật vào màn hình đã đóng.

### Bước 8 — lib/services/role_data_source.dart

Admin đọc các collection cần thiết. Giảng viên truy vấn lớp có lecturerId của mình, sau đó sinh viên trong các lớp đó và điểm tương ứng. Sinh viên đọc đúng hồ sơ studentId đã liên kết, lớp và điểm của mình. Khi đổi phạm vi lớp, các stream cũ được hủy.

Điểm cần giải thích: không chỉ tải toàn bộ dữ liệu rồi ẩn trên giao diện; query được giới hạn theo vai trò. Danh sách tài khoản Admin bỏ qua role manager cũ, không tự chuyển các tài khoản đó thành Admin.

### Bước 9 — lib/services/student_data_service.dart

Tập hợp repository của users/students/classes/subjects/grades. `createStudent` dùng transaction kiểm tra mã chưa tồn tại và lớp hợp lệ trước khi ghi. `saveGrade` kiểm tra sinh viên/môn tồn tại rồi ghi theo Grade.id. Các stream theo lớp/sinh viên phục vụ đồng bộ giao diện.

### Bước 10 — lib/services/firestore_repository.dart

Repository dùng chung, có generic T và converter. `getById/watchAll` đọc object có kiểu; `create` kiểm tra trùng bằng transaction; `update` chỉ sửa bản ghi đã tồn tại. `fromMap/toMap` là ánh xạ dữ liệu document, không phải ORM SQL với bảng và join tự động.

### Bước 11 — firestore.rules

Đây là lớp chặn trên server, vẫn áp dụng nếu người dùng bỏ qua UI và gửi yêu cầu trực tiếp. Rule kiểm tra đăng nhập, hồ sơ active, role, lớp của giảng viên, studentId của sinh viên và tính hợp lệ dữ liệu. Client không được tự tạo/đổi role/status/accountUid. Không lưu credential quản trị trong Flutter để vượt qua rules.

### Bước 12 — lib/screens/project_workspace.dart

Đây là nơi ghép dashboard, lớp, sinh viên, module môn/điểm của Hiệp và màn hình tài khoản Admin. Form nhận nhập liệu, gọi hàm store, hiển thị lỗi/thành công. `ListenableBuilder` nhận thay đổi từ store. Logout giữ Navigator trước await để không bị kẹt màn hình khi Firebase ngắt các stream sau đăng xuất.

## 4. Một thao tác cụ thể: thêm sinh viên

ProjectWorkspace mở form → kiểm tra trường nhập → tạo Student → ProjectStore.saveStudent kiểm tra quyền/mã/lớp → StudentDataService.createStudent chạy transaction → Firestore rules kiểm tra lại → ghi document students → stream nhận bản ghi mới → store notifyListeners → danh sách trên UI cập nhật.

Nếu demo thì bước lưu dùng SharedPreferences và danh sách local, không chạy Firestore rules. Thêm hồ sơ sinh viên khác với cấp tài khoản đăng nhập: cấp tài khoản là bước backend riêng.

## 5. Phần của Hiệp: môn học và bảng điểm

### lib/screens/subjects_screen.dart

Nhận danh sách Subject và callback onCreate từ màn hình cha. `_query` dùng cho tìm kiếm. `_addSubject` mở form, kiểm tra mã trùng, tên bắt buộc và tín chỉ nguyên 1–10, tạo Subject rồi gọi callback. Không nhúng kết nối Firebase vào màn hình. Thuộc tính canCreate dùng để giới hạn thao tác tạo môn trên UI; quyền server vẫn kiểm tra riêng.

### lib/screens/grades_screen.dart

Giữ studentId đang chọn, lọc điểm theo sinh viên và hiển thị tên môn từ danh mục Subject. `_addGrade` mở form chọn môn/học kỳ và nhập điểm. Điểm phải hữu hạn từ 0 đến 10, học kỳ YYYY-1 hoặc YYYY-2. Gọi onSave để phía tích hợp chuyển xuống ProjectStore.saveGrade.

### lib/models/grade.dart — quy ước dữ liệu dùng chung

Khóa bản ghi là `studentId~subjectId~semester`. Ví dụ `SV001~MOB01~2026-1`. Lưu 8.5 rồi sửa thành 9 ở cùng bộ ba sẽ cập nhật bản ghi cũ; học kỳ 2026-2 tạo bản ghi khác. Đây là cách tránh nhân đôi điểm khi bấm lưu lại; không dùng tên người làm khóa vì tên có thể trùng.

Model là phần nền tảng dùng chung, không khẳng định chỉ Hiệp viết model này.

### Luồng nhập điểm

GradesScreen → onSave → ProjectWorkspace truyền callback → ProjectStore.saveGrade kiểm tra vai trò và phạm vi → StudentDataService.saveGrade kiểm tra tham chiếu trong transaction → FirestoreRepository/converter ghi dữ liệu → rules xác nhận → stream trả điểm mới → UI cập nhật.

### lib/screens/student_portal_screen.dart

Hiệp thêm cổng sinh viên qua PR #7: hồ sơ học vụ chỉ đọc; lọc grades theo student.studentId; hiển thị trạng thái chưa có điểm; form sửa phone/contactEmail/address; email đăng nhập hiển thị riêng; reset mật khẩu và logout gọi callback. Các nút bị khóa khi tác vụ đang chạy; lỗi lưu giữ lại nội dung form. Màn hình không tự chọn hoặc nâng role.

### test của Hiệp

`test/subjects_grades_screen_test.dart`: tìm/thêm môn hợp lệ, mã trùng, tín chỉ sai; chọn sinh viên, điểm sai và cập nhật đúng bản ghi.
`test/student_portal_screen_test.dart`: hồ sơ và điểm riêng; form liên hệ; lưu lỗi vẫn giữ dữ liệu; callback reset/logout; màn hình điện thoại không overflow.
Công việc GĐ1 của Hiệp còn có test plan và bằng chứng review trong PR #3. Có thể mở GitHub để đối chiếu, không chỉ nêu tổng số commit.

## 6. Backend tài khoản — phần Bắc giải thích nếu cô hỏi

- `lib/services/account_api.dart`: URL backend lấy từ dart-define, gửi JSON và Firebase ID token; không gửi credential Admin.
- `backend/server.mjs`: xác minh token, đọc profile active, kiểm tra role và lớp trước khi thực hiện. Đăng ký lecturer luôn pending; chỉ Admin duyệt/assign; cấp student luôn role student và liên kết hồ sơ. Có xử lý yêu cầu đồng thời để tránh tạo nhiều tài khoản cho một sinh viên.
- `backend/domain.mjs`: validation và các điều kiện quyền dùng chung cho backend.
- `backend/firebase.mjs`: khởi tạo SDK phía máy chủ và gửi yêu cầu email đặt mật khẩu; credential nằm ở server. Browser API key dùng cho link email là cấu hình client, không thay credential Admin.
- `backend/bootstrap-admin.mjs`: chỉ công cụ chủ dự án dùng để khởi tạo Admin đầu tiên, từ chối khi đã có Admin khác; gửi email để chủ tài khoản tự đặt mật khẩu.
- `admin_accounts_screen.dart`, `lecturer_registration_screen.dart`, `pending_account_screen.dart`: các màn hình tạo yêu cầu/duyệt/trạng thái; không tự ghi quyền vào Firestore từ UI.

Luồng cấp student: lecturer thêm hồ sơ → yêu cầu backend cấp account cho email thật → backend xác minh lớp/role → tạo Auth user → ghi profile student và accountUid → gửi email đặt mật khẩu. Hệ thống không tạo hộp thư Gmail và giảng viên không biết mật khẩu sinh viên.

## 7. Kết quả kiểm thử và giới hạn phải nói đúng

- 35 Flutter test đã đạt sau sửa lỗi tài khoản legacy; Dart analyze lib/test không có vấn đề.
- 12 Firestore rules test và 6 backend test đạt trên Firebase Emulator, không thay đổi dữ liệu thật.
- APK debug build thành công và đã mở trên Android Emulator.
- Admin thật đã tạo, rules ba vai trò đã deploy. Lần đăng nhập thật trước gặp lỗi tải dữ liệu; bản sửa mới cần xác nhận lại trọn luồng đăng nhập trên máy.
- Backend HTTPS chưa triển khai. Đăng nhập/đọc Firestore có thể chạy trực tiếp; đăng ký giảng viên, duyệt, phân công và cấp tài khoản cần backend URL hợp lệ. Bản app chạy mặc định chưa được cấu hình URL này.
- Không tuyên bố toàn bộ dự án/báo cáo đã hoàn tất. Chưa nghiệm thu đầy đủ chuỗi tài khoản thật từ đầu tới cuối và chưa chứng minh đủ 10 câu rubric chỉ bằng bộ test.

## 8. Câu hỏi thường gặp

“Vì sao cần Firebase Auth và Firestore?” — Auth xác nhận danh tính và cấp UID/token; Firestore lưu hồ sơ/lớp/môn/điểm. Rules dùng danh tính đó để quyết định ai được truy cập gì.

“Ẩn nút sửa điểm đã đủ chưa?” — Chưa, vẫn cần kiểm tra store và rules/backend; giao diện có thể bị bỏ qua.

“Vì sao sinh viên không tự sửa lớp?” — Đây là dữ liệu học vụ chính thức, thay đổi phải do người có quyền; sinh viên chỉ sửa liên hệ.

“Future và Stream khác gì?” — Future chờ một kết quả như đăng nhập/lưu; Stream nhận nhiều lần thay đổi như danh sách điểm realtime.

“Vì sao dùng callback?” — UI không phụ thuộc trực tiếp Firebase, có thể thay nguồn demo/cloud và kiểm thử dễ hơn.

“Làm sao tránh trùng điểm?” — Dùng khóa xác định bởi sinh viên, môn, học kỳ; lưu lại cùng khóa cập nhật một document.

“Hiện hoàn thành gì?” — Demo quản lý lớp/sinh viên/môn/điểm và cổng sinh viên; code ba role và test đã có. Backend và nghiệm thu cloud đầy đủ là phần tiếp tục hoàn thiện.
