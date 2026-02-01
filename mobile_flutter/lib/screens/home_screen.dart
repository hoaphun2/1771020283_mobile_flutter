import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/services/notification_service.dart';
import 'package:mobile_flutter/screens/profile_screen.dart';
import 'package:mobile_flutter/screens/wallet_screen.dart';
import 'package:mobile_flutter/screens/booking_screen.dart';
import 'package:mobile_flutter/screens/tournament_screen.dart';
import 'package:mobile_flutter/screens/members_screen.dart';
import 'package:mobile_flutter/screens/notifications_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BookingScreen(),
    const TournamentScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CLB Pickleball Vọt Thủ Phổ Núi'),
        actions: [
          if (user != null)
            Consumer<NotificationService>(
              builder: (context, notificationService, child) {
                return Badge(
                  label: Text(notificationService.unreadCount.toString()),
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          if (user?.role == 'Admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MembersScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.fullName ?? 'Khách'),
              accountEmail: Text(user?.email ?? 'chưa đăng nhập'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: user?.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                          width: 60,
                          height: 60,
                        ),
                      )
                    : Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : 'K',
                        style: const TextStyle(fontSize: 24),
                      ),
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Trang chủ'),
              selected: _currentIndex == 0,
              onTap: () {
                setState(() {
                  _currentIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Đặt sân'),
              selected: _currentIndex == 1,
              onTap: () {
                setState(() {
                  _currentIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Giải đấu'),
              selected: _currentIndex == 2,
              onTap: () {
                setState(() {
                  _currentIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Ví điện tử'),
              selected: _currentIndex == 3,
              onTap: () {
                setState(() {
                  _currentIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Cá nhân'),
              selected: _currentIndex == 4,
              onTap: () {
                setState(() {
                  _currentIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            if (user?.role == 'Admin')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Quản lý thành viên'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MembersScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                // Mở màn hình cài đặt
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Trợ giúp'),
              onTap: () {
                // Mở màn hình trợ giúp
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                await authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Đặt sân',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Giải đấu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ví',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thông tin ví
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
                    'Số dư ví',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${user?.walletBalance?.toStringAsFixed(0) ?? '0'} VND',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WalletScreen(),
                            ),
                          );
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
                          // Xem lịch sử
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Lịch sử'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Thông tin thành viên
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
                  if (user != null)
                    Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: const Text('Hạng thành viên'),
                          trailing: Chip(
                            label: Text(
                              user.tier,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getTierColor(user.tier),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.join_full, color: Colors.blue),
                          title: const Text('Ngày tham gia'),
                          trailing: Text(
                            '${user.joinDate.day}/${user.joinDate.month}/${user.joinDate.year}',
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.attach_money, color: Colors.blue),
                          title: const Text('Tổng chi tiêu'),
                          trailing: Text(
                            '${user.walletBalance?.toStringAsFixed(0) ?? '0'} VND',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Thống kê nhanh
          const Text(
            'Hoạt động gần đây',
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
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                icon: Icons.calendar_today,
                color: Colors.blue,
                title: 'Lịch đặt',
                value: '0',
              ),
              _buildStatCard(
                icon: Icons.emoji_events,
                color: Colors.amber,
                title: 'Giải đấu',
                value: '0',
              ),
              _buildStatCard(
                icon: Icons.emoji_events,
                color: Colors.green,
                title: 'Thắng',
                value: '0',
              ),
              _buildStatCard(
                icon: Icons.timeline,
                color: Colors.purple,
                title: 'Rank',
                value: '0',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Lịch sắp tới
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
                    'Lịch sắp tới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Không có lịch sắp tới',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Mở đặt sân
                      },
                      child: const Text('Đặt sân ngay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}