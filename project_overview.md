# Sổ Tiêm Chủng (Vaccination Record App) - Tổng quan dự án

## 1. Mô tả
**Sổ Tiêm Chủng** là một ứng dụng di động và web được xây dựng bằng Flutter, thiết kế để giúp người dùng theo dõi và quản lý lịch tiêm chủng cho bản thân và các thành viên trong gia đình. Ứng dụng sử dụng phương pháp **Kiến trúc Sạch (Clean Architecture)** (gồm 3 tầng: Domain, Data, Presentation) và sử dụng **Provider** để quản lý trạng thái (state management). Hiện tại, việc lưu trữ dữ liệu được xử lý hoàn toàn qua cơ sở dữ liệu **SQLite** ở máy cục bộ (sử dụng gói `sqflite` cho thiết bị di động/desktop, `sqflite_common_ffi_web` cho môi trường web).

## 2. Các thực thể chính (Core Entities)
Tầng Domain (Nghiệp vụ cốt lõi) xoay quanh một số thực thể chính sau:
- **User (Người dùng)**: Tài khoản chính (yêu cầu tên, số điện thoại, mật khẩu, ngày sinh, giới tính).
- **Member (Thành viên)**: Các thành viên gia đình được liên kết với một `User`. Bản thân người dùng cũng được lưu dưới dạng một thành viên với `relationship = 'Chủ hộ'`.
- **VaccinationRecord (Hồ sơ tiêm chủng)**: Đại diện cho một sự kiện tiêm chủng cụ thể của một `Member`, bao gồm các thông tin chi tiết như tên vắc-xin, liều lượng, ngày tiêm, ngày nhắc lịch, địa điểm tiêm, ghi chú, và trạng thái đã hoàn thành (isCompleted) hay chưa.
- **Appointment (Lịch hẹn)**: Thể hiện một lịch đăng ký tiêm chủng tại một cơ sở/phòng khám, chứa thời gian hẹn và trạng thái (VD: pending - đang chờ).
- **VaccineInfo (Thông tin vắc-xin)**: Dữ liệu (tĩnh hoặc động) chứa thông tin các loại vắc-xin.

## 3. Kiến trúc & Quản lý trạng thái (State Management)
- **Tầng Domain (Nghiệp vụ cốt lõi)**: Chứa các Entity (Thực thể) và các định nghĩa trừu tượng của Repository (ví dụ: `AuthRepository`, `VaccinationRepository`).
- **Tầng Data (Dữ liệu)**: Chứa [DatabaseHelper](file:///d:/Semester%208/PRM393/vaccination_record/lib/data/local/database_helper.dart#8-168) - nơi khởi tạo các bảng SQLite (`users`, `members`, `vaccination_records`, `appointments`). Tầng này sẽ định nghĩa class triển khai các Repository sử dụng DAO (Data Access Objects).
- **Tầng Presentation (Giao diện hiển thị)**: Được xây dựng bằng các thành phần Widget của Flutter. Tầng này dùng `ChangeNotifierProvider` từ thư viện `provider` để nạp các ViewModel (như `AuthViewModel`, `VaccinationViewModel`, `HouseholdViewModel`, `AppointmentViewModel`, `AIViewModel`, `SettingsViewModel`).

## 4. Các luồng nghiệp vụ chính
### a. Luồng Đăng nhập / Đăng ký (Authentication Flow)
- Người dùng mở ứng dụng.
- Họ có thể đăng ký tài khoản bằng Số điện thoại và Mật khẩu. Dữ liệu này được lưu xuống bảng `users` trong SQLite.
- Lúc đăng nhập, ứng dụng đối chiếu thông tin với SQLite. Nếu thành công sẽ thiết lập phiên đăng nhập cho `AuthViewModel`.

### b. Luồng Quản lý Thành viên Gia đình (Household Management Flow)
- Sau khi tạo tài khoản User, một `Member` mặc định sẽ được tạo đồng thời, đại diện cho "Chủ hộ".
- Người dùng có thể thêm các thành viên khác (bố mẹ, vợ/chồng, con cái). Các member này được gắn với người dùng thông qua `userId` trong bảng `members`.
- `HouseholdViewModel` có nhiệm vụ gọi data và quản lý danh sách thành viên của người dùng hiện tại.

### c. Luồng Theo dõi Lịch Tiêm chủng (Vaccination Tracking Flow)
- Người dùng chọn một `Member` và tạo mới một [VaccinationRecord](file:///d:/Semester%208/PRM393/vaccination_record/lib/domain/entities/vaccination_record.dart#1-83).
- Hồ sơ có thể được đánh dấu là `isCompleted` (Đã tiêm).
- Trạng thái mũi tiêm tự động được tính toán dựa vào `date` và thời điểm hiện tại để trả ra: "Đã tiêm", "Hôm nay", "Quá hạn", "Sắp đến hạn" hoặc "Kế hoạch".
- Tính năng Nhắc lịch (Reminders) dùng `flutter_local_notifications` để cảnh báo cho những mũi tiêm sắp đến hạn.
- Dữ liệu này được điều phối bởi `VaccinationViewModel`.

### d. Đặt Lịch Tiêm (Appointment Booking)
- Người dùng có thể đặt `Appointment` cho một loại vắc-xin cụ thể tại một cơ sở/phòng tiêm.
- `AppointmentViewModel` xử lý việc tạo mới và lấy danh sách lịch hẹn từ bảng `appointments`.

### e. Tích hợp AI / Đề xuất
- Ứng dụng dùng thư viện `google_generative_ai` thông qua `AIViewModel` để tự động đưa ra các thông tin kiến thức và những đề xuất tư vấn thông minh bám sát vắc-xin thực tế.

## 5. Các tích hợp bên thứ ba (Third-party)
- `flutter_local_notifications` và `timezone`: Quản lý báo thức và nhắc nhở cục bộ trên thiết bị.
- `shared_preferences`: Cấu hình / trạng thái (chẳng hạn như ghi nhớ phiên đăng nhập trước đó hoặc thiết lập chủ đề - theme).
- `google_generative_ai`: Chạy các tính năng Generative AI.
