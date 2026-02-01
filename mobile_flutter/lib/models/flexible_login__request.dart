class FlexibleLoginRequest {
  final String email;
  final String password;

  FlexibleLoginRequest({required this.email, required this.password});

  // Có thể gửi cả 2 trường để đảm bảo tương thích
  Map<String, dynamic> toJson() => {
    'username': email,
    'email': email,  // Gửi cả 2
    'password': password,
  };
}