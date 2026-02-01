# 🎾 CLB Pickleball Vọt Thủ Phổ Núi - Mobile App

Ứng dụng di động chính thức dành cho Câu lạc bộ Pickleball, được xây dựng bằng **Flutter**, giúp hội viên dễ dàng quản lý thông tin, tài chính và kết nối với nhau.

![Banner](https://img.shields.io/badge/Flutter-Create-blue?logo=flutter) ![Banner](https://img.shields.io/badge/Platform-Android-green?logo=android)

## 🚀 Tính Năng Chính

*   **🔐 Xác thực người dùng**:
    *   Đăng nhập & Đăng ký hội viên mới.
    *   Tự động lưu phiên đăng nhập (Auto Login).
    *   Cơ chế bảo mật Token (JWT).

*   **👛 Ví Điện Tử & Thanh Toán**:
    *   **Nạp tiền**: Cho phép nạp tiền vào tài khoản bằng cách upload hình ảnh chuyển khoản.
    *   **Lịch sử giao dịch**: Xem lại chi tiết các lần nạp/rút/thanh toán.
    *   **Số dư thực**: Cập nhật số dư ví ngay lập tức sau khi giao dịch.

*   **👥 Cộng Đồng**:
    *   Xem danh sách thành viên trong CLB.
    *   Xem thông tin xếp hạng/Tier của hội viên.

*   **📲 Tiện ích khác**:
    *   Màn hình Splash Screen giới thiệu chuyên nghiệp.
    *   Giao diện người dùng hiện đại, thân thiện (Material 3).
    *   Hỗ trợ Dark Mode/Light Mode (Tùy chỉnh).

## 🛠️ Công Nghệ Sử Dụng

*   **Frontend**: Flutter (Dart SDK >=3.0.0).
*   **State Management**: Provider.
*   **Networking**: Dio (Xử lý API request & Interceptors).
*   **Local Storage**: Flutter Secure Storage & Shared Preferences.
*   **Backend Connection**: Kết nối RESTful API tới Server .NET Core (VPS Online).

## 📦 Hướng Dẫn Cài Đặt (Cho Người Dùng)

1.  Tải file cài đặt **`.apk`** mới nhất từ liên kết được cung cấp.
2.  Mở file trên điện thoại Android và chọn **"Cài đặt"** (Install).
    *   *Lưu ý: Nếu điện thoại hỏi quyền cài đặt từ nguồn không xác định, hãy chọn "Cho phép".*
3.  Sau khi cài đặt xong, mở ứng dụng và **Đăng nhập** để bắt đầu sử dụng.

## 🔧 Hướng Dẫn Chạy Source Code (Cho Dev)

Nếu bạn muốn chạy dự án này trên máy tính cá nhân:

**Yêu cầu:** Flutter SDK đã được cài đặt.

1.  **Clone dự án về máy:**
    ```bash
    git clone https://github.com/username/project.git
    cd mobile_flutter
    ```

2.  **Cài đặt các thư viện phụ thuộc:**
    ```bash
    flutter pub get
    ```

3.  **Cấu hình API:**
    *   Mặc định App đang trỏ về VPS Online. 
    *   Nếu muốn chạy Localhost, sửa file `lib/services/api_service.dart`.

4.  **Chạy ứng dụng:**
    ```bash
    flutter run
    ```

## 📸 Hình Ảnh Demo

| Màn hình Splash | Màn hình Đăng nhập | Trang chủ |
| :---: | :---: | :---: |
| *(Thêm ảnh Splash)* | *(Thêm ảnh Login)* | *(Thêm ảnh Home)* |

---
**Thông tin liên hệ:**
*   Email: admin@pcm.com
*   SĐT: 0123.456.789
