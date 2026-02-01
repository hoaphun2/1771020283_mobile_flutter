import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Map<String, dynamic>> _transactions = [];
  // Store local transactions to persist across refreshes
  final List<Map<String, dynamic>> _localTransactions = [];
  int _selectedTab = 0;
  String _selectedBank = 'Vietcombank';
  bool _showFastProcessingNote = true;
  double _walletBalance = 0;
  
  final List<Map<String, dynamic>> _banks = [
    {'name': 'Vietcombank', 'icon': '🏦', 'account': '1234567890', 'owner': 'CLB VỌT THỦ PHỔ NÚI'},
    {'name': 'Techcombank', 'icon': '💳', 'account': '0987654321', 'owner': 'CLB VỌT THỦ PHỔ NÚI'},
    {'name': 'MB Bank', 'icon': '🏛️', 'account': '1122334455', 'owner': 'CLB VỌT THỦ PHỔ NÚI'},
    {'name': 'BIDV', 'icon': '🏢', 'account': '6677889900', 'owner': 'CLB VỌT THỦ PHỔ NÚI'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _generateUserId();
    _loadWalletBalance();
  }

  String _userId = '';

  void _generateUserId() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000;
    setState(() {
      _userId = 'VTPN${now.millisecondsSinceEpoch ~/ 1000}${random.toString().padLeft(4, '0')}';
    });
  }

  // Hàm tải số dư ví từ provider
  Future<void> _loadWalletBalance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Fix: Chỉ tải lại từ server nếu chưa có thông tin user để tránh mất dữ liệu local giả lập
    if (authProvider.currentUser == null) {
      await authProvider.getCurrentUser();
    }
    
    if (mounted) {
      setState(() {
         // AuthProvider now handles loading the persisted balance automatically
        _walletBalance = authProvider.currentUser?.walletBalance ?? 0;
      });
    }
  }

  // Hàm cập nhật số dư ví - SỬA LẠI PHẦN NÀY
  Future<void> _updateWalletBalance(double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Giả lập API cập nhật số dư
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() {
          _walletBalance += amount;
        });
        
        // Cập nhật vào provider nếu có phương thức update
        // Kiểm tra xem authProvider có phương thức updateWalletBalance không
        if (authProvider.currentUser != null) {
          // Gọi API cập nhật số dư thực tế
          // await _apiService.updateWalletBalance(_walletBalance);
          
          // Nếu provider có phương thức cập nhật user, sử dụng nó
          // Hoặc tạo user mới với số dư đã cập nhật
          final updatedUser = authProvider.currentUser!.copyWith(
            walletBalance: _walletBalance,
          );
          
          // Cập nhật người dùng với thông tin mới
          authProvider.updateUser(updatedUser);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi cập nhật số dư: $e');
      }
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _transactions = [
          ..._localTransactions, // Add local transactions first
          {
            'id': '1',
            'type': 'Deposit',
            'amount': 1000000,
            'description': 'Nạp tiền từ Vietcombank',
            'status': 'Success',
            'createdDate': '2024-02-01 14:30:00',
            'transactionId': 'TXN123456',
          },
          {
            'id': '2',
            'type': 'Payment',
            'amount': -200000,
            'description': 'Thanh toán đặt sân 1',
            'status': 'Success',
            'createdDate': '2024-02-01 10:15:00',
            'transactionId': 'TXN123457',
          },
          {
            'id': '3',
            'type': 'Deposit',
            'amount': 500000,
            'description': 'Nạp tiền từ MoMo',
            'status': 'Success',
            'createdDate': '2024-01-31 16:45:00',
            'transactionId': 'TXN123458',
          },
          {
            'id': '4',
            'type': 'Payment',
            'amount': -300000,
            'description': 'Thanh toán giải đấu',
            'status': 'Success',
            'createdDate': '2024-01-30 09:20:00',
            'transactionId': 'TXN123459',
          },
          {
            'id': '5',
            'type': 'Reward',
            'amount': 100000,
            'description': 'Thưởng thành viên VIP',
            'status': 'Success',
            'createdDate': '2024-01-29 11:10:00',
            'transactionId': 'TXN123460',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải lịch sử: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chụp ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm xử lý khi tiền đã về tài khoản
  void _processDepositSuccess(double amount, String transactionId, String description) {
    // 1. Cập nhật số dư ví
    _updateWalletBalance(amount);
    
    // 2. Cập nhật giao dịch từ Pending -> Success
    final transactionIndex = _transactions.indexWhere((t) => t['transactionId'] == transactionId);
    
    if (transactionIndex != -1) {
      setState(() {
        _transactions[transactionIndex]['status'] = 'Success';
        _transactions[transactionIndex]['description'] = description;
      });
    }
    
    // 3. Hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '✅ NẠP TIỀN THÀNH CÔNG!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Số dư đã được cộng: ${NumberFormat('#,###').format(amount)} VND',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // 4. Thông báo đã thêm vào lịch sử
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao dịch đã được thêm vào lịch sử'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _submitDeposit() async {
    if (_amountController.text.isEmpty || double.tryParse(_amountController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    if (amount < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền tối thiểu là 50,000 VND'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Đối với web, không yêu cầu ảnh
    if (_selectedImage == null && _selectedTab == 0 && !kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh chuyển khoản'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Hiển thị Dialog xử lý tự động
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 24),
                const Text(
                  'Đang kết nối cổng thanh toán...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hệ thống đang tự động kiểm tra giao dịch',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Tạo transactionId mới
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      final description = _noteController.text.isNotEmpty 
          ? _noteController.text 
          : 'Nạp tiền từ $_selectedBank';
      
      // Giả lập thời gian kết nối và xử lý
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      
      // Đóng dialog loading
      Navigator.of(context).pop();

      // Cập nhật giao dịch thành công ngay lập tức
      final newTransaction = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': 'Deposit',
        'amount': amount,
        'description': description,
        'status': 'Success', // Thành công luôn
        'createdDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'transactionId': transactionId,
      };

      setState(() {
        _localTransactions.insert(0, newTransaction); // Save to local storage
        _transactions.insert(0, newTransaction);
        
        // Cập nhật số dư ví ngay lập tức
        _walletBalance += amount;
      });

      // Saving to SharedPreferences is now handled inside authProvider.updateUser

      // Cập nhật vào provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final updatedUser = authProvider.currentUser!.copyWith(
          walletBalance: _walletBalance,
        );
        authProvider.updateUser(updatedUser);
      }
      
      // Xóa form
      _amountController.clear();
      _noteController.clear();
      setState(() {
        _selectedImage = null;
      });

      // Hiển thị Dialog thành công
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 64),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'NẠP TIỀN THÀNH CÔNG',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.green
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Số tiền ${NumberFormat('#,###').format(amount)} VND',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Đã được cộng vào tài khoản của bạn',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Đóng', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

    } catch (e) {
      // Nếu có lỗi, đóng dialog loading trước
      if (mounted) Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await FlutterClipboard.copy(text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép vào clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _launchBankApp(String bank) async {
    String url = '';
    
    switch (bank) {
      case 'Vietcombank':
        url = 'https://vietcombank.com.vn/';
        break;
      case 'MoMo':
        url = 'https://momo.vn/';
        break;
      case 'ZaloPay':
        url = 'https://zalopay.vn/';
        break;
      case 'VNPay':
        url = 'https://vnpay.vn/';
        break;
      default:
        url = 'https://your-bank.com/';
    }
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở ứng dụng $bank'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi mở ứng dụng: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBankTransferTab() {
    final selectedBankInfo = _banks.firstWhere((bank) => bank['name'] == _selectedBank);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    const Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'HƯỚNG DẪN NẠP TIỀN NHANH',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Thông tin nạp tiền nhanh
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade50, Colors.green.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              const Text(
                                '⏱️ XỬ LÝ CỰC NHANH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.black87, fontSize: 14),
                              children: [
                                TextSpan(text: 'Hệ thống tự động nhận diện và cộng tiền '),
                                TextSpan(
                                  text: 'NGAY LẬP TỨC',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                TextSpan(text: ' (thường chỉ trong '),
                                TextSpan(
                                  text: 'vài giây đến 1 phút',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ') sau khi chuyển khoản thành công.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Thời gian "5-10 phút" được đề cập là để đảm bảo xử lý trong mọi trường hợp.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Chọn ngân hàng:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _banks.map((bank) {
                        final isSelected = _selectedBank == bank['name'];
                        return ChoiceChip(
                          label: Text('${bank['icon']} ${bank['name']}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedBank = bank['name'];
                              });
                            }
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin chuyển khoản',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Ngân hàng:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                selectedBankInfo['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Số tài khoản:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Text(
                                    selectedBankInfo['account'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () => _copyToClipboard(selectedBankInfo['account']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tên chủ tài khoản:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  Text(
                                    selectedBankInfo['owner'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () => _copyToClipboard(selectedBankInfo['owner']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Nội dung chuyển khoản bắt buộc
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '📌 NỘI DUNG CHUYỂN KHOẢN (BẮT BUỘC):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _userId,
                                        style: const TextStyle(
                                          fontFamily: 'Courier',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.red,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.blue),
                                      onPressed: () => _copyToClipboard(_userId),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Sao chép chính xác để hệ thống TỰ ĐỘNG nhận diện',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          ElevatedButton.icon(
                            onPressed: () => _launchBankApp(_selectedBank),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('MỞ ỨNG DỤNG NGÂN HÀNG'),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Số tiền (VND)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixText: 'VND',
                        hintText: '50,000 VND tối thiểu',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                        prefixIcon: const Icon(Icons.note),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Ví dụ: Nạp tiền cho thành viên ABC',
                      ),
                      maxLines: 2,
                    ),
                    
                    // Chỉ hiển thị phần upload ảnh khi không phải web
                    if (!kIsWeb) ...[
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Ảnh chuyển khoản (bắt buộc)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Chọn ảnh'),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takePhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Chụp ảnh'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_selectedImage != null)
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📌 Lưu ý quan trọng:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildNoteItem('Vui lòng nhập ĐÚNG nội dung chuyển khoản và số tiền.'),
                          _buildNoteItem('Thời gian "5-10 phút" là để đảm bảo trong mọi trường hợp.'),
                          _buildNoteItem('Đa số giao dịch hoàn thành trong vài giây.'),
                          _buildNoteItem('Nếu sau 15 phút chưa thấy tiền, vui lòng liên hệ hỗ trợ.'),
                          if (!kIsWeb) _buildNoteItem('Ảnh chuyển khoản phải rõ nét, đầy đủ thông tin.'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'GỬI YÊU CẦU NẠP TIỀN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tùy chọn tắt thông báo nhanh
                    Row(
                      children: [
                        Checkbox(
                          value: _showFastProcessingNote,
                          onChanged: (value) {
                            setState(() {
                              _showFastProcessingNote = value ?? true;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Hiển thị thông báo xử lý nhanh (tiền về ngay)',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.orange)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'Quét QR Code để nạp tiền',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: 'VTPN|$_userId|${Provider.of<AuthProvider>(context).currentUser?.email ?? ''}',
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Mã thành viên của bạn:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _userId,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () => _copyToClipboard(_userId),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Thêm thông tin xử lý nhanh cho QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ Nạp tiền cực nhanh:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('• Hệ thống tự động xử lý ngay lập tức'),
                          Text('• Tiền về ví chỉ trong vài giây'),
                          Text('• Không cần chờ đợi xác nhận thủ công'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📱 Hướng dẫn nạp tiền:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('1. Mở ứng dụng MoMo, ZaloPay, VNPay, hoặc ngân hàng của bạn'),
                          Text('2. Chọn tính năng "Quét mã QR"'),
                          Text('3. Quét mã QR bên trên'),
                          Text('4. Nhập số tiền và xác nhận thanh toán'),
                          Text('5. Tiền sẽ tự động vào ví trong 1-2 phút'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Ứng dụng hỗ trợ:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildPaymentAppCard('MoMo', Colors.purple),
                        _buildPaymentAppCard('ZaloPay', Colors.blue),
                        _buildPaymentAppCard('VNPay', Colors.red),
                        _buildPaymentAppCard('Vietcombank', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAppCard(String name, Color color) {
    return GestureDetector(
      onTap: () => _launchBankApp(name),
      child: Container(
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final amount = transaction['amount'] ?? 0;
    final type = transaction['type'] ?? '';
    final description = transaction['description'] ?? '';
    final createdDate = transaction['createdDate'] ?? '';
    final status = transaction['status'] ?? '';
    final transactionId = transaction['transactionId'] ?? '';
    
    Color amountColor = Colors.black;
    IconData icon = Icons.attach_money;
    Color statusColor = Colors.grey;
    String statusText = 'Chờ xử lý';
    
    if (type == 'Deposit' || type == 'Reward') {
      amountColor = Colors.green;
      icon = Icons.add_circle;
    } else if (type == 'Payment' || type == 'Withdraw') {
      amountColor = Colors.red;
      icon = Icons.remove_circle;
    }
    
    if (status == 'Success') {
      statusColor = Colors.green;
      statusText = 'Thành công';
    } else if (status == 'Pending') {
      statusColor = Colors.orange;
      statusText = 'Chờ xử lý';
    } else if (status == 'Failed') {
      statusColor = Colors.red;
      statusText = 'Thất bại';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: amountColor),
          ),
          child: Icon(icon, color: amountColor, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              transactionId,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        subtitle: Text(createdDate),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${amount > 0 ? '+' : ''}${NumberFormat('#,###').format(amount)} VND',
              style: TextStyle(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Sử dụng _walletBalance thay vì user?.walletBalance
    final displayBalance = _walletBalance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví điện tử'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTransactions();
              _loadWalletBalance();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue[50],
            child: Column(
              children: [
                const Text(
                  'Số dư khả dụng',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    '${NumberFormat('#,###').format(displayBalance)} VND',
                    key: ValueKey<double>(displayBalance),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nạp tiền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTab = 2;
                        });
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Lịch sử'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            color: Colors.white,
            child: TabBar(
              controller: TabController(
                length: 3,
                initialIndex: _selectedTab,
                vsync: Navigator.of(context),
              ),
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: 'Chuyển khoản'),
                Tab(text: 'QR Code'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          
          Expanded(
            child: _selectedTab == 0
                ? _buildBankTransferTab()
                : _selectedTab == 1
                    ? _buildQRCodeTab()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Thống kê tháng này',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatCard(
                                          'Tổng nạp',
                                          '${NumberFormat('#,###').format(_calculateTotalDeposit())} VND',
                                          Colors.green,
                                        ),
                                        _buildStatCard(
                                          'Tổng chi',
                                          '${NumberFormat('#,###').format(_calculateTotalPayment())} VND',
                                          Colors.red,
                                        ),
                                        _buildStatCard(
                                          'Giao dịch',
                                          '${_transactions.length}',
                                          Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: 'Tất cả',
                                    decoration: InputDecoration(
                                      labelText: 'Loại giao dịch',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                                      DropdownMenuItem(value: 'Deposit', child: Text('Nạp tiền')),
                                      DropdownMenuItem(value: 'Payment', child: Text('Thanh toán')),
                                      DropdownMenuItem(value: 'Reward', child: Text('Thưởng')),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: 'Tất cả',
                                    decoration: InputDecoration(
                                      labelText: 'Trạng thái',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Tất cả', child: Text('Tất cả')),
                                      DropdownMenuItem(value: 'Success', child: Text('Thành công')),
                                      DropdownMenuItem(value: 'Pending', child: Text('Chờ xử lý')),
                                      DropdownMenuItem(value: 'Failed', child: Text('Thất bại')),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : _transactions.isEmpty
                                    ? const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.receipt, size: 64, color: Colors.grey),
                                            SizedBox(height: 16),
                                            Text(
                                              'Chưa có giao dịch nào',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: _transactions.map((transaction) {
                                          return _buildTransactionItem(transaction);
                                        }).toList(),
                                      ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Hàm tính tổng nạp tiền
  double _calculateTotalDeposit() {
    double total = 0;
    for (var transaction in _transactions) {
      if ((transaction['type'] == 'Deposit' || transaction['type'] == 'Reward') && 
          transaction['status'] == 'Success') {
        total += (transaction['amount'] as num).toDouble();
      }
    }
    return total;
  }

  // Hàm tính tổng chi tiêu
  double _calculateTotalPayment() {
    double total = 0;
    for (var transaction in _transactions) {
      if (transaction['type'] == 'Payment' && transaction['status'] == 'Success') {
        total += (transaction['amount'] as num).toDouble().abs();
      }
    }
    return total;
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}