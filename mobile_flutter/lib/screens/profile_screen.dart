import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mobile_flutter/models/user_model.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _rankHistory = [];

  @override
  void initState() {
    super.initState();
    _loadRankHistory();
  }

  Future<void> _loadRankHistory() async {
    // Giả lập dữ liệu lịch sử rank
    setState(() {
      _rankHistory = [
        {'date': '2024-01-01', 'rank': 1200, 'change': '+50'},
        {'date': '2024-02-01', 'rank': 1250, 'change': '+30'},
        {'date': '2024-03-01', 'rank': 1280, 'change': '-20'},
        {'date': '2024-04-01', 'rank': 1260, 'change': '+40'},
        {'date': '2024-05-01', 'rank': 1300, 'change': '+60'},
      ];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Gọi API cập nhật profile
        await Future.delayed(const Duration(seconds: 1)); // Giả lập API call
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.getCurrentUser();
        
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu mới không khớp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi API đổi mật khẩu
      await Future.delayed(const Duration(seconds: 1)); // Giả lập API call
      
      setState(() {
        _isChangingPassword = false;
        _isLoading = false;
        _passwordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đổi mật khẩu thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return Colors.cyan;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey[400]!;
      default:
        return Colors.brown;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond':
        return Icons.diamond;
      case 'gold':
        return Icons.monetization_on;
      case 'silver':
        return Icons.money;
      default:
        return Icons.person;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          if (!_isEditing && !_isChangingPassword)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _fullNameController.text = user.fullName;
                  _phoneController.text = user.phone ?? '';
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar và thông tin cơ bản
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null) as ImageProvider?,
                          child: _selectedImage == null && user.avatarUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (!_isEditing)
                      Column(
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            Text(
                              user.phone!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    
                    if (_isEditing)
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập họ và tên';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _selectedImage = null;
                                    });
                                  },
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text('Lưu'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Hạng thành viên và rank
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin thành viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(
                          _getTierIcon(user.tier),
                          color: _getTierColor(user.tier),
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hạng: ${user.tier}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Ngày tham gia: ${DateFormat('dd/MM/yyyy').format(user.joinDate)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Rank DUPR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      '1300',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '+60 điểm so với tháng trước',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Đổi mật khẩu
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bảo mật',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isChangingPassword)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isChangingPassword = true;
                              });
                            },
                            child: const Text('Đổi mật khẩu'),
                          ),
                      ],
                    ),
                    
                    if (_isChangingPassword)
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu hiện tại',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu hiện tại';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu mới',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập mật khẩu mới';
                              }
                              if (value.length < 6) {
                                return 'Mật khẩu phải có ít nhất 6 ký tự';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Xác nhận mật khẩu mới',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            obscureText: true,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isChangingPassword = false;
                                    _passwordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Xác nhận'),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Lịch sử rank
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lịch sử Rank DUPR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_rankHistory.isEmpty)
                      const Center(
                        child: Text(
                          'Chưa có dữ liệu rank',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _rankHistory.map((history) {
                          final change = int.tryParse(history['change'].replaceAll('+', '').replaceAll('-', '')) ?? 0;
                          final isPositive = history['change'].startsWith('+');
                          
                          return ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  history['rank'].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(history['date']),
                            trailing: Text(
                              history['change'],
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thống kê',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatItem(
                          title: 'Tổng trận',
                          value: '45',
                          color: Colors.blue,
                        ),
                        _buildStatItem(
                          title: 'Thắng',
                          value: '30',
                          color: Colors.green,
                        ),
                        _buildStatItem(
                          title: 'Thua',
                          value: '15',
                          color: Colors.red,
                        ),
                        _buildStatItem(
                          title: 'Tỷ lệ thắng',
                          value: '66.7%',
                          color: Colors.amber,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Nút đăng xuất - SỬA LẠI
            ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                // Chuyển về màn hình login
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ĐĂNG XUẤT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}