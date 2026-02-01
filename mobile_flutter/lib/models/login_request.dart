class LoginRequest {
  final String email;  // Backend muốn username nhưng Flutter dùng email
  final String password;

  LoginRequest({required this.email, required this.password});

  // Sửa toJson() để gửi đúng format backend muốn
  Map<String, dynamic> toJson() => {
    'username': email,  // Sửa từ 'email' thành 'username'
    'password': password,
  };
}