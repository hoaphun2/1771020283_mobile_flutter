import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:mobile_flutter/models/user_model.dart';
import 'package:intl/intl.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final ApiService _apiService = ApiService();
  final List<User> _members = [];
  final List<User> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedTier = 'Tất cả';
  String _selectedSort = 'Mới nhất';
  
  final List<String> _tiers = ['Tất cả', 'Standard', 'Silver', 'Gold', 'Diamond'];
  final List<String> _sortOptions = ['Mới nhất', 'A-Z', 'Rank cao nhất', 'Chi tiêu nhiều nhất'];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Giả lập API call
      await Future.delayed(const Duration(seconds: 2));

      // Tạo dữ liệu mẫu
      List<User> sampleMembers = [];
      for (int i = 1; i <= 20; i++) {
        sampleMembers.add(User(
          id: i.toString(),
          email: 'member$i@gmail.com',
          fullName: 'Nguyễn Văn $i',
          phone: '098765432${i.toString().padLeft(2, '0')}',
          avatarUrl: null,
          role: i == 1 ? 'Admin' : 'Member',
          walletBalance: 2000000 + i * 400000,
          tier: _getTierForIndex(i),
          joinDate: DateTime.now().subtract(Duration(days: i * 30)),
        ));
      }

      setState(() {
        _members.addAll(sampleMembers);
        _filteredMembers.addAll(sampleMembers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh sách thành viên: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTierForIndex(int index) {
    if (index <= 5) return 'Standard';
    if (index <= 10) return 'Silver';
    if (index <= 15) return 'Gold';
    return 'Diamond';
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

  void _filterMembers() {
    List<User> filtered = List.from(_members);

    // Lọc theo search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) {
        return member.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               member.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (member.phone ?? '').contains(_searchQuery);
      }).toList();
    }

    // Lọc theo tier
    if (_selectedTier != 'Tất cả') {
      filtered = filtered.where((member) => member.tier == _selectedTier).toList();
    }

    // Sắp xếp
    switch (_selectedSort) {
      case 'Mới nhất':
        filtered.sort((a, b) => b.joinDate.compareTo(a.joinDate));
        break;
      case 'A-Z':
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'Rank cao nhất':
        filtered.sort((a, b) => (b.walletBalance ?? 0).compareTo(a.walletBalance ?? 0));
        break;
      case 'Chi tiêu nhiều nhất':
        filtered.sort((a, b) => (b.walletBalance ?? 0).compareTo(a.walletBalance ?? 0));
        break;
    }

    setState(() {
      _filteredMembers.clear();
      _filteredMembers.addAll(filtered);
    });
  }

  void _showMemberDetail(User member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Avatar và tên
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[200],
                    child: member.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              member.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 80,
                              height: 80,
                            ),
                          )
                        : Icon(
                            _getTierIcon(member.tier),
                            size: 40,
                            color: _getTierColor(member.tier),
                          ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          member.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        if (member.phone != null && member.phone!.isNotEmpty)
                          Text(
                            member.phone!,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Thông tin thành viên
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Hạng thành viên', member.tier, _getTierColor(member.tier)),
                      _buildDetailRow('Số dư ví', '${NumberFormat('#,###').format(member.walletBalance ?? 0)} VND', Colors.green),
                      _buildDetailRow('Ngày tham gia', DateFormat('dd/MM/yyyy').format(member.joinDate), Colors.blue),
                      _buildDetailRow('Vai trò', member.role, Colors.purple),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Thống kê
              const Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatCard('Tổng trận', '45', Colors.blue),
                  _buildStatCard('Thắng', '30', Colors.green),
                  _buildStatCard('Thua', '15', Colors.red),
                  _buildStatCard('Tỷ lệ', '66.7%', Colors.amber),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Nhắn tin
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message, size: 20),
                          SizedBox(width: 8),
                          Text('Nhắn tin'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Xem chi tiết
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.remove_red_eye, size: 20),
                          SizedBox(width: 8),
                          Text('Xem thêm'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
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
      ),
    );
  }

  Widget _buildMemberCard(User member) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTierColor(member.tier).withOpacity(0.2),
          child: Icon(
            _getTierIcon(member.tier),
            color: _getTierColor(member.tier),
          ),
        ),
        title: Text(
          member.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.email),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTierColor(member.tier).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getTierColor(member.tier),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    member.tier,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTierColor(member.tier),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (member.role == 'Admin')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${NumberFormat('#,###').format(member.walletBalance ?? 0)} VND',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(member.joinDate),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () => _showMemberDetail(member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    
    if (currentUser?.role != 'Admin') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Bạn không có quyền truy cập',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search và filter
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm thành viên...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterMembers();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Filter và sort
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTier,
                        decoration: InputDecoration(
                          labelText: 'Hạng thành viên',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        items: _tiers.map((tier) {
                          return DropdownMenuItem(
                            value: tier,
                            child: Text(tier),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTier = value!;
                          });
                          _filterMembers();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSort,
                        decoration: InputDecoration(
                          labelText: 'Sắp xếp',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        items: _sortOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSort = value!;
                          });
                          _filterMembers();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Thống kê
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Tổng thành viên', _members.length.toString(), Colors.blue),
                _buildSummaryCard('VIP', _members.where((m) => m.tier == 'Diamond' || m.tier == 'Gold').length.toString(), Colors.amber),
                _buildSummaryCard('Online', '15', Colors.green),
              ],
            ),
          ),
          
          // Danh sách thành viên
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không tìm thấy thành viên nào',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          return _buildMemberCard(_filteredMembers[index]);
                        },
                      ),
          ),
          
          // Tổng số
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số: ${_filteredMembers.length} thành viên',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tổng ví: ${NumberFormat('#,###').format(_filteredMembers.fold<int>(0, (sum, member) => sum + ((member.walletBalance ?? 0).toInt())))} VND',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Column(
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
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}