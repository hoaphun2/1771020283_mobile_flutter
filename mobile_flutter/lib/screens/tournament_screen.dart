import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_flutter/models/tournament_model.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final ApiService _apiService = ApiService();
  final List<Tournament> _tournaments = [];
  final List<Tournament> _myTournaments = [];
  Tournament? _selectedTournament;
  bool _isLoading = false;
  int _selectedTab = 0;
  final List<String> _tabs = ['Tất cả', 'Đang mở', 'Đang diễn ra', 'Đã kết thúc'];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Giả lập API call
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _tournaments.addAll([
          Tournament(
            id: '1',
            name: 'Summer Open 2024',
            startDate: DateTime.now().add(const Duration(days: 10)),
            endDate: DateTime.now().add(const Duration(days: 12)),
            format: 'Knockout',
            entryFee: 500000,
            prizePool: 10000000,
            status: 'Registering',
            description: 'Giải đấu mùa hè dành cho mọi thành viên',
            maxParticipants: 32,
            currentParticipants: 24,
            organizer: 'CLB Vọt Thủ Phổ Núi',
          ),
          Tournament(
            id: '2',
            name: 'Winter Cup 2024',
            startDate: DateTime.now().add(const Duration(days: 30)),
            endDate: DateTime.now().add(const Duration(days: 32)),
            format: 'RoundRobin',
            entryFee: 300000,
            prizePool: 5000000,
            status: 'Open',
            description: 'Giải đấu thân thiện mùa đông',
            maxParticipants: 16,
            currentParticipants: 8,
            organizer: 'CLB Vọt Thủ Phổ Núi',
          ),
          Tournament(
            id: '3',
            name: 'Champions League 2024',
            startDate: DateTime.now().subtract(const Duration(days: 10)),
            endDate: DateTime.now().subtract(const Duration(days: 5)),
            format: 'Hybrid',
            entryFee: 1000000,
            prizePool: 25000000,
            status: 'Finished',
            description: 'Giải đấu chuyên nghiệp cấp cao',
            maxParticipants: 16,
            currentParticipants: 16,
            organizer: 'CLB Vọt Thủ Phổ Núi',
          ),
        ]);
        
        _myTournaments.add(_tournaments[2]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải giải đấu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Tournament> _getFilteredTournaments() {
    switch (_selectedTab) {
      case 0:
        return _tournaments;
      case 1:
        return _tournaments.where((t) => t.status == 'Open' || t.status == 'Registering').toList();
      case 2:
        return _tournaments.where((t) => t.status == 'Ongoing').toList();
      case 3:
        return _tournaments.where((t) => t.status == 'Finished').toList();
      default:
        return _tournaments;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.green;
      case 'Registering':
        return Colors.blue;
      case 'Ongoing':
        return Colors.orange;
      case 'Finished':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Open':
        return 'Mở đăng ký';
      case 'Registering':
        return 'Đang đăng ký';
      case 'Ongoing':
        return 'Đang diễn ra';
      case 'Finished':
        return 'Đã kết thúc';
      default:
        return status;
    }
  }

  Future<void> _joinTournament(Tournament tournament) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để tham gia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if ((user.walletBalance ?? 0) < tournament.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Số dư ví không đủ. Cần ${NumberFormat('#,###').format(tournament.entryFee)} VND'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Giả lập API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Cập nhật thông tin user
      await authProvider.getCurrentUser();
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng ký tham gia thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng ký: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTournamentCard(Tournament tournament) {
    final isParticipating = _myTournaments.any((t) => t.id == tournament.id);
    final isFinished = tournament.status == 'Finished';
    final isFull = tournament.currentParticipants >= tournament.maxParticipants;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedTournament = tournament;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      tournament.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tournament.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(tournament.status),
                      ),
                    ),
                    child: Text(
                      _getStatusText(tournament.status),
                      style: TextStyle(
                        color: _getStatusColor(tournament.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                tournament.description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(tournament.startDate),
                  ),
                  const SizedBox(width: 8),
                  const Text('-'),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(tournament.endDate),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${tournament.currentParticipants}/${tournament.maxParticipants}',
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.attach_money, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormat('#,###').format(tournament.entryFee),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              LinearProgressIndicator(
                value: tournament.currentParticipants / tournament.maxParticipants,
                backgroundColor: Colors.grey[200],
                color: Colors.blue,
              ),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giải thưởng: ${NumberFormat('#,###').format(tournament.prizePool)} VND',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  if (!isFinished && !isParticipating && !isFull)
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _joinTournament(tournament),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      child: const Text('Tham gia'),
                    ),
                  
                  if (isParticipating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Text(
                        'Đã tham gia',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  if (isFull && !isParticipating)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Text(
                        'Đã đầy',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentDetail() {
    if (_selectedTournament == null) {
      return const Center(
        child: Text('Chọn một giải đấu để xem chi tiết'),
      );
    }
    
    final tournament = _selectedTournament!;
    final isParticipating = _myTournaments.any((t) => t.id == tournament.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedTournament = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  tournament.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(tournament.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _getStatusColor(tournament.status)),
            ),
            child: Text(
              _getStatusText(tournament.status),
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(tournament.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Thông tin cơ bản
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
                    'Thông tin giải đấu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Thể thức:', tournament.format),
                  _buildInfoRow('Phí đăng ký:', '${NumberFormat('#,###').format(tournament.entryFee)} VND'),
                  _buildInfoRow('Tổng giải thưởng:', '${NumberFormat('#,###').format(tournament.prizePool)} VND'),
                  _buildInfoRow('Thời gian:', '${DateFormat('dd/MM/yyyy').format(tournament.startDate)} - ${DateFormat('dd/MM/yyyy').format(tournament.endDate)}'),
                  _buildInfoRow('Số lượng:', '${tournament.currentParticipants}/${tournament.maxParticipants} đội'),
                  _buildInfoRow('Ban tổ chức:', tournament.organizer),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mô tả
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
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(tournament.description),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Cây đấu (nếu có)
          if (tournament.status == 'Ongoing' || tournament.status == 'Finished')
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
                      'Cây đấu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Giả lập cây đấu đơn giản
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Cây đấu sẽ hiển thị tại đây',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Danh sách tham gia
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
                    'Danh sách tham gia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Giả lập danh sách
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text((index + 1).toString()),
                        ),
                        title: Text('Đội ${index + 1}'),
                        subtitle: Text('Thành viên A, Thành viên B'),
                        trailing: Text(
                          'Rank: ${1200 + index * 50}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Nút tham gia/đăng ký
          if (!isParticipating && tournament.status == 'Registering')
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _joinTournament(tournament),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ĐĂNG KÝ THAM GIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTournaments = _getFilteredTournaments();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
      ),
      body: _selectedTournament == null
          ? Column(
              children: [
                // Tabs
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(_tabs[index]),
                          selected: _selectedTab == index,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTab = index;
                            });
                          },
                          selectedColor: Colors.blue,
                          labelStyle: TextStyle(
                            color: _selectedTab == index ? Colors.white : Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Thông tin giải của tôi
                if (_myTournaments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Giải đấu của tôi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _myTournaments.length,
                            itemBuilder: (context, index) {
                              final tournament = _myTournaments[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tournament.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat('dd/MM').format(tournament.startDate),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                                            const SizedBox(width: 4),
                                            Text(
                                              NumberFormat('#,###').format(tournament.prizePool),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.amber,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Danh sách giải đấu
                Expanded(
                  child: _isLoading && _tournaments.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTournaments.isEmpty
                          ? const Center(
                              child: Text(
                                'Không có giải đấu nào',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredTournaments.length,
                              itemBuilder: (context, index) {
                                return _buildTournamentCard(filteredTournaments[index]);
                              },
                            ),
                ),
              ],
            )
          : _buildTournamentDetail(),
    );
  }
}