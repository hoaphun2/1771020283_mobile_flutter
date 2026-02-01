import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_flutter/models/user_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _token;
  
  // ĐỔI IP THÀNH ĐÚNG ĐỊA CHỈ CỦA BẠN
  static final String apiUrl = kIsWeb
      ? 'http://103.77.172.200:5001/api'
      : dotenv.env['API_URL'] ?? 'http://10.0.2.2:5069'; // Android emulator
  
  final String _baseUrl = kIsWeb
      ? 'http://103.77.172.200:5001/api'
      : 'http://10.0.2.2:5069/api'; // Sử dụng địa chỉ trực tiếp

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Thêm interceptor để debug
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        print('Sending request to: ${options.baseUrl}${options.path}');
        print('Request data: ${options.data}');
        return handler.next(options);
      },
      onError: (error, handler) async {
        print('Dio Error: ${error.message}');
        print('Response: ${error.response?.data}');
        print('Status: ${error.response?.statusCode}');
        return handler.next(error);
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  // Đăng nhập - SỬA LẠI
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      print('=== LOGIN ATTEMPT ===');
      print('Base URL: $_baseUrl');
      print('Request data: ${request.toJson()}');
      
      // THỬ CẢ 2 CÁCH GỬI DỮ LIỆU
      final Map<String, dynamic> requestData = {
        'username': request.email,  // Backend yêu cầu username
        'email': request.email,     // Gửi cả email để backup
        'password': request.password,
      };
      
      print('Sending data: $requestData');
      
      final response = await _dio.post(
        '/auth/login', 
        data: requestData,
        options: Options(
          validateStatus: (status) => status! < 500, // Cho phép 400 để debug
        )
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        return AuthResponse.fromJson(response.data);
      } else {
        throw Exception('Đăng nhập thất bại: ${response.data?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        print('Dio error response: ${e.response?.data}');
        throw Exception('Lỗi kết nối: ${e.message} - ${e.response?.data?['message']}');
      }
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Đăng ký - SỬA LẠI
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      print('=== REGISTER ATTEMPT ===');
      print('Request data: ${request.toJson()}');
      
      final response = await _dio.post('/auth/register', data: request.toJson());
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(response.data);
      }
      throw Exception('Đăng ký thất bại: ${response.data?['message']}');
    } catch (e) {
      print('Register error: $e');
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Test kết nối
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/auth');
      print('Connection test: ${response.data}');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }

  // ... phần còn lại giữ nguyên


  // Lấy thông tin user hiện tại
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
      throw Exception('Không thể lấy thông tin người dùng');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Lấy danh sách thành viên
  Future<List<User>> getMembers({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get('/members', queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        List<User> members = [];
        for (var item in response.data['data']) {
          members.add(User.fromJson(item));
        }
        return members;
      }
      throw Exception('Không thể lấy danh sách thành viên');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  // Nạp tiền vào ví
  Future<bool> deposit(double amount, String imagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'amount': amount,
        'image': await MultipartFile.fromFile(imagePath, filename: 'deposit.jpg'),
      });

      final response = await _dio.post('/wallet/deposit', data: formData);
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi khi nạp tiền: $e');
    }
  }

  // Lấy lịch sử giao dịch
  Future<List<dynamic>> getWalletTransactions() async {
    try {
      final response = await _dio.get('/wallet/transactions');
      if (response.statusCode == 200) {
        return response.data['data'] ?? [];
      }
      throw Exception('Không thể lấy lịch sử giao dịch');
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}