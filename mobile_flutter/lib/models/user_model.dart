class User {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final double? walletBalance;
  final String tier;
  final DateTime joinDate;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.walletBalance,
    required this.tier,
    required this.joinDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'Member',
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'Standard',
      joinDate: DateTime.parse(json['joinDate']?.toString() ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'walletBalance': walletBalance,
      'tier': tier,
      'joinDate': joinDate.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    String? role,
    double? walletBalance,
    String? tier,
    DateTime? joinDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      tier: tier ?? this.tier,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}

class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String? phone;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
    };
  }
}

class WalletTransaction {
  final String id;
  final String memberId;
  final double amount;
  final String type;
  final String status;
  final String? relatedId;
  final String description;
  final DateTime createdDate;

  WalletTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.relatedId,
    required this.description,
    required this.createdDate,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      relatedId: json['relatedId']?.toString(),
      description: json['description'] ?? '',
      createdDate: DateTime.parse(json['createdDate']?.toString() ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'type': type,
      'status': status,
      'relatedId': relatedId,
      'description': description,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class NotificationModel {
  final String id;
  final String receiverId;
  final String message;
  final String type;
  final String? linkUrl;
  bool isRead;
  final DateTime createdDate;

  NotificationModel({
    required this.id,
    required this.receiverId,
    required this.message,
    required this.type,
    this.linkUrl,
    required this.isRead,
    required this.createdDate,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'Info',
      linkUrl: json['linkUrl'],
      isRead: json['isRead'] ?? false,
      createdDate: DateTime.parse(json['createdDate']?.toString() ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'linkUrl': linkUrl,
      'isRead': isRead,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}