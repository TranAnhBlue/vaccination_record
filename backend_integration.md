# Hướng dẫn tích hợp Backend

Hiện tại, ứng dụng Sổ Tiêm Chủng (Vaccination Record App) hoạt động gần như ngoại tuyến hoàn toàn, sử dụng cơ sở dữ liệu **SQLite** để tải và lưu tài khoản người dùng, thành viên gia đình, hồ sơ tiêm chủng và các lịch hẹn. Nếu bạn có kế hoạch chuyển đổi ứng dụng này sang sử dụng Backend dùng chung (ví dụ: REST API được xây dựng bằng NodeJS, Spring Boot hoặc qua các nền tảng BaaS như Firebase), bạn sẽ cần thay đổi một số cấu trúc nền tảng.

Bởi vì ứng dụng này lấy cốt lõi là **Kiến trúc sạch (Clean Architecture)**, Giao diện (Tầng Presentation) và các Quy tắc Nghiệp vụ (Tầng Domain) gần như đã tách biệt hoàn toàn khỏi CSDL (Tầng Data). Hầu hết các thay đổi sẽ được cô lập bên trong **Tầng Data (Dữ liệu)**.

## 1. Cập nhật Tầng Domain (Nghiệp vụ cốt lõi)
Tầng này yêu cầu thay đổi rất ít, tuy nhiên bạn có thể tự thay đổi Model/Entity để tương thích với cơ chế giao tiếp Backend:
- **Trạng thái xác thực (Tokens/Auth State)**: Nếu sử dụng JWT (JSON Web Tokens) hoặc Session cookies, hãy thêm các method trừu tượng mới vào `AuthRepository` (ví dụ: `Future<String?> getToken()`, `Future<void> logout()`).
- **Định danh Entity (Entity IDs)**: Đảm bảo mọi ID trong Entity (chẳng hạn như `int? id`) thay đổi sang các kiểu ID phù hợp nhất với Backend. Ví dụ: một số Backend dùng chuỗi UUID thay vì số nguyên tự động tăng (Auto-increment).

## 2. Cập nhật Tầng Data (Phần chiếm nhiều khối lượng nhất)
Đây là khu vực mà hầu hết các hạng mục tích hợp cần phải thực thi.

### a. Thay thế các DAO SQLite cục bộ bằng API Clients
- Thay vì dùng [DatabaseHelper](file:///d:/Semester%208/PRM393/vaccination_record/lib/data/local/database_helper.dart#8-168) và các DAO ở bản địa cục bộ (như `UserDao`, `VaccinationDao`), bạn sẽ cần xây dựng các nguồn dữ liệu nối mạng **(Remote Data Sources)** (chẳng hạn: `UserRemoteDataSource`, `VaccinationRemoteDataSource`).
- Khai thác thư viện `http` (có sẵn trong [pubspec.yaml](file:///d:/Semester%208/PRM393/vaccination_record/pubspec.yaml)) hoặc tích hợp thư viện `dio` để thực hiện giao tiếp qua REST API.
- Ví dụ tham khảo: Hàm `createVaccinationRecord(record)` sẽ đổi từ chuỗi lưu SQL `INSERT INTO vaccination_records` thành một tác vụ gọi HTTP, chẳng hạn `http.post('/api/vaccination-records')`.

### b. Triển khai Class Interface mới trong Repository 
- Xây mới mô hình class triển khai, chẳng hạn đưa `AuthRepositoryApiImpl` kế thừa `AuthRepository`.
- Những class triển khai (Impl) này sẽ thực hiện thao tác gọi từ Remote Data Source thay vì dùng Local DAOs truyền thống.
- **Tính năng Hỗ trợ Ngoại tuyến - Offline Mode (Khuyên dùng)**: Bạn hoàn toàn có thể xây dựng Repository theo quy trình đọc/ghi lấy từ nền tảng SQLite trả dữ liệu cho UI, đồng thời fetch gọi Remote API để chạy ngầm nạp lại (sync) bản ghi mới nhất về lại cho CSDL SQLite.

### c. Serialization & Data Models (Serialize dữ liệu API)
- Bạn phải code thêm các phương thức JSON, bao gồm `fromJson` và `toJson` đối với các mô hình Entity (Hoặc xây dựng Data Model rồi mapping sang Entity) nhằm hỗ trợ chuyển đổi dữ liệu Json từ Backend trả về. Chẳng hạn: `VaccinationRecordModel.fromJson(json)`.

## 3. Lớp Giao diện & Biến trạng thái (Presentation & States)
UI hiện đang lấy dữ liệu thông qua các view models (Nhờ `ChangeNotifierProvider`). Vì View Models gọi hàm qua đối tượng Repository đã được trừu tượng hóa, nó mặc định không quan tâm Data đó xuất phát ở đâu. Thế nhưng còn vài chỗ phải lưu ý chỉnh:
- **Trạng thái đang tải (Loading States)**: Xử lý Network tốn nhiều chu kỳ phản hồi từ server hơn là xử lý bộ nhớ bằng SQLite. Phải đảm bảo logic các ViewModel quản lý đúng cờ biến `isLoading` nhằm cho UI render vòng xoay `CircularProgressIndicator` khi hệ thống đang đợi HTTP responses trả về.
- **Hệ thống xử lý lỗi (Error Handling)**: Tín hiệu báo có nhiều rủi ro lỗi (lỗi thiết lập 500 mạng đứt quãng, lỗi Server timeout, hoặc gặp mã 401 bị sai định dạng Token/Auth). ViewModel cần có khối Try-Catch, tiếp nhận bắt `HttpException` và tạo các cảnh báo `SnackBar` hiển thị lên UI cho Người dùng nhìn thấy.
- **Tiêm phụ thuộc (Dependency Injection)**: Tại file [main.dart](file:///d:/Semester%208/PRM393/vaccination_record/lib/main.dart), các điểm bơm truyền kết nối file Repository từ đầu vào sẽ chuyển từ Local DAOs sang class Remote Repositories:
  ```dart
  // Bản cũ (Dùng Local Storage)
  // final repo = AuthRepositoryImpl(UserDao());
  
  // Bản mới (Dùng nền tảng Remote API Services)
  // final apiService = ApiService(baseUrl: "https://my-backend.com/api");
  // final repo = AuthRepositoryRemoteImpl(apiService);
  ```

## 4. Luồng xử lý phân quyền đăng nhập (Chuẩn JWT / Authorization)
- **Đăng nhập (Login Flow)**: Nạp Tên đăng nhập / Số điện thoại và Mật khẩu gửi cho API máy chủ. Hệ thống API nhận thành công thì tiến hành phản hồi ra Token API (Cấp kèm với đó là Refresh Token).
- **Lưu trữ mã Token an toàn (Token Storage)**: Phải bảo vệ JWT trong vùng lưu trữ an toàn, nhờ vào tính năng của thư viện `flutter_secure_storage` hay `shared_preferences`.
- **API Interceptors (Người nhận dạng tiền xử lý HTTP)**: Đa phần các lệnh gọi fetch dữ liệu API Backend sau này (Chẳng hạn gọi chi tiết bảng Family Members hay danh sách thông tin Lịch hẹn của hồ sơ) sẽ đều cần ghép khóa Token định danh đã mã hóa vào file Header chuẩn: `Authorization: Bearer <token>`.

## Danh mục Check-list Tổng Quan (Summary)
1. [ ] Làm lập trình Backend cho Endpoint hệ thống: Quản lý Luồng Đăng ký/đăng nhập (Auth), Dữ Liệu Members, Vaccination Records và Appointments.
2. [ ] Thêm thư mục Core `core/network` với tích hợp gói `http` hoặc `dio`.
3. [ ] Xây dựng Remote Data Sources dành cho tất cả các domain entity cốt lõi.
4. [ ] Build Code Class Repository Impl nối kết lấy tài nguyên từ nhóm Remote Data Sources nói trên.
5. [ ] Config cơ chế Deserialize với các phương thức Json dành cho những file Data Models.
6. [ ] Cấu hình ngã rẽ vào file gốc App đầu vào [main.dart](file:///d:/Semester%208/PRM393/vaccination_record/lib/main.dart) chuyển Dependency Injection (DI) trỏ ngầm thay thế bằng Remote Repositories hết toàn bộ.
7. [ ] Load bộ cài `flutter_secure_storage` cấu hình quản trị thiết lập và lưu trữ phân quyền ẩn Auth Tokens.
8. [ ] Tiến hành Test Lỗi Giao diện bao trùm toàn ứng dụng, cấu hình rà kiểm trạng thái Loading Data & Tín hiệu Báo Lỗi (Error network connection) hợp lí ở view.
