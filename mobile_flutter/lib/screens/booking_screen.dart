import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_flutter/models/booking_model.dart';
import 'package:mobile_flutter/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/providers/auth_provider.dart';
import 'package:mobile_flutter/utils/sliver_app_bar_delegate.dart';

// Remove local Court class definition if it exists at the bottom to avoid conflicts
// using the one from booking_model.dart

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService _apiService = ApiService();
  final List<Court> _courts = [];
  final List<Booking> _bookings = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  Court? _selectedCourt;
  bool _isRecurring = false;
  String _recurrenceRule = 'Weekly';
  List<String> _selectedDays = [];
  bool _isLoading = false;
  bool _isVip = false;

  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final Map<String, Color> _courtColors = {
    'Sân 1': Colors.blue,
    'Sân 2': Colors.green,
    'Sân 3': Colors.orange,
    'Sân 4': Colors.purple,
  };

  final List<String> _timeSlots = [
    '06:00', '06:30', '07:00', '07:30', '08:00', '08:30',
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30', '20:00', '20:30',
    '21:00', '21:30', '22:00'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
    _checkVipStatus();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load courts (keep hardcoded or fetch from API)
      setState(() {
        _courts.addAll([
          Court(
            id: '1', 
            name: 'Sân 1', 
            pricePerHour: 200000, 
            isActive: true,
            // description: 'Sân tiêu chuẩn, có mái che', // Add description to model if needed
          ),
          Court(
            id: '2', 
            name: 'Sân 2', 
            pricePerHour: 200000, 
            isActive: true,
          ),
          Court(
            id: '3', 
            name: 'Sân 3', 
            pricePerHour: 180000, 
            isActive: true,
          ),
          Court(
            id: '4', 
            name: 'Sân 4', 
            pricePerHour: 180000, 
            isActive: true,
          ),
        ]);
      });

      // Load bookings from persistence
      final prefs = await SharedPreferences.getInstance();
      final savedBookings = prefs.getStringList('saved_bookings');
      
      if (savedBookings != null) {
        setState(() {
          _bookings.clear();
          _bookings.addAll(
            savedBookings.map((jsonStr) => Booking.fromJson(jsonDecode(jsonStr))).toList()
          );
        });
      } else {
        // Initial dummy data if no saved bookings
        _bookings.addAll([
          Booking(
            id: '1',
            courtId: '1',
            memberId: '1',
            startTime: DateTime.now().add(const Duration(hours: 2)),
            endTime: DateTime.now().add(const Duration(hours: 4)),
            totalPrice: 400000,
            status: 'Confirmed',
          ),
        ]);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = _bookings.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList('saved_bookings', bookingsJson);
    } catch (e) {
      print('Error saving bookings: $e');
    }
  }

  Future<void> _checkVipStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    setState(() {
      _isVip = user?.tier.toLowerCase() == 'diamond' || 
               user?.tier.toLowerCase() == 'gold';
    });
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    return _bookings.where((booking) {
      return booking.startTime.year == day.year &&
             booking.startTime.month == day.month &&
             booking.startTime.day == day.day;
    }).toList();
  }

  Map<DateTime, List<Booking>> _getBookingsForCalendar() {
    Map<DateTime, List<Booking>> events = {};
    
    for (var booking in _bookings) {
      final day = DateTime(booking.startTime.year, booking.startTime.month, booking.startTime.day);
      if (events[day] == null) {
        events[day] = [];
      }
      events[day]!.add(booking);
    }
    
    return events;
  }

  bool _isTimeSlotBooked(String timeSlot, Court court) {
    if (_selectedDay == null) return false;
    
    final timeParts = timeSlot.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final slotDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      hour,
      minute,
    );
    
    final slotEndDateTime = slotDateTime.add(const Duration(minutes: 30));
    
    return _bookings.any((booking) {
      if (booking.courtId != court.id) return false;
      
      final bookingStart = booking.startTime;
      final bookingEnd = booking.endTime;
      
      return (slotDateTime.isBefore(bookingEnd) && slotEndDateTime.isAfter(bookingStart));
    });
  }

  Future<void> _createBooking() async {
    if (_selectedDay == null || 
        _selectedStartTime == null || 
        _selectedEndTime == null || 
        _selectedCourt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final duration = endMinutes - startMinutes;
    if (duration < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian tối thiểu là 30 phút'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (duration > 240) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian tối đa là 4 giờ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      
      final endDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );

      final durationHours = duration / 60;
      final totalPrice = durationHours * _selectedCourt!.pricePerHour;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      if ((user?.walletBalance ?? 0) < totalPrice) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Số dư ví không đủ. Cần ${NumberFormat('#,###').format(totalPrice)} VND'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 2));

      final newBooking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        courtId: _selectedCourt!.id,
        memberId: 'current_user',
        startTime: startDateTime,
        endTime: endDateTime,
        totalPrice: totalPrice,
        status: 'Confirmed',
        isRecurring: _isRecurring,
        recurrenceRule: _isRecurring ? _recurrenceRule : null,
      );

      setState(() {
        _bookings.add(newBooking);
        _isLoading = false;
        
        _selectedStartTime = null;
        _selectedEndTime = null;
        _selectedCourt = null;
        _isRecurring = false;
        _selectedDays.clear();
      });

      // Deduct from wallet
      final newBalance = (user?.walletBalance ?? 0) - totalPrice;
      if (user != null) {
        authProvider.updateUser(user.copyWith(walletBalance: newBalance));
      }

      // Save bookings
      await _saveBookings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đặt sân thành công! Tổng tiền: ${NumberFormat('#,###').format(totalPrice)} VND'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt sân: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBookingForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'ĐẶT SÂN MỚI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Chọn sân:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _courts.length,
                      itemBuilder: (context, index) {
                        final court = _courts[index];
                        final isSelected = _selectedCourt?.id == court.id;
                        final isBooked = _selectedDay != null && 
                            _timeSlots.any((slot) => _isTimeSlotBooked(slot, court));
                        
                        return GestureDetector(
                          onTap: isBooked ? null : () {
                            setState(() {
                              _selectedCourt = court;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.blue 
                                    : isBooked 
                                        ? Colors.red 
                                        : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    court.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${NumberFormat('#,###').format(court.pricePerHour)} VND/h',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (court.description != null)
                                    Text(
                                      court.description!,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  if (isBooked)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Text(
                                        'Đã đặt',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ngày đặt:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy').format(_selectedDay!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thời gian bắt đầu:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                    builder: (context, child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true,
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedStartTime = time;
                                      _selectedEndTime = TimeOfDay(
                                        hour: time.hour + 1,
                                        minute: time.minute,
                                      );
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedStartTime != null
                                            ? _selectedStartTime!.format(context)
                                            : 'Chọn giờ',
                                        style: TextStyle(
                                          color: _selectedStartTime != null 
                                              ? Colors.black 
                                              : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.access_time, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thời gian kết thúc:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _selectedStartTime ?? TimeOfDay.now(),
                                    builder: (context, child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                          alwaysUse24HourFormat: true,
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (time != null) {
                                    setState(() {
                                      _selectedEndTime = time;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedEndTime != null
                                            ? _selectedEndTime!.format(context)
                                            : 'Chọn giờ',
                                        style: TextStyle(
                                          color: _selectedEndTime != null 
                                              ? Colors.black 
                                              : Colors.grey,
                                        ),
                                      ),
                                      const Icon(Icons.access_time, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (_selectedStartTime != null && _selectedEndTime != null && _selectedCourt != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Thời lượng:'),
                                Text(
                                  '${((_selectedEndTime!.hour * 60 + _selectedEndTime!.minute) - (_selectedStartTime!.hour * 60 + _selectedStartTime!.minute)) ~/ 60} giờ ${((_selectedEndTime!.hour * 60 + _selectedEndTime!.minute) - (_selectedStartTime!.hour * 60 + _selectedStartTime!.minute)) % 60} phút',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tổng tiền:'),
                                Text(
                                  '${NumberFormat('#,###').format(_calculateTotalPrice())} VND',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    if (_isVip)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _isRecurring,
                                onChanged: (value) {
                                  setState(() {
                                    _isRecurring = value ?? false;
                                  });
                                },
                              ),
                              const Text(
                                'Đặt lịch định kỳ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const Text(
                                'VIP',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          
                          if (_isRecurring)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tần suất:'),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _recurrenceRule,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Daily',
                                      child: Text('Hàng ngày'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Weekly',
                                      child: Text('Hàng tuần'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Monthly',
                                      child: Text('Hàng tháng'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _recurrenceRule = value!;
                                    });
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                if (_recurrenceRule == 'Weekly')
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Chọn các ngày trong tuần:'),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: _weekDays.map((day) {
                                          final isSelected = _selectedDays.contains(day);
                                          return FilterChip(
                                            label: Text(day),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedDays.add(day);
                                                } else {
                                                  _selectedDays.remove(day);
                                                }
                                              });
                                            },
                                            selectedColor: Colors.blue[100],
                                            checkmarkColor: Colors.blue,
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        ],
                      ),
                    
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createBooking,
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle),
                                SizedBox(width: 8),
                                Text(
                                  'XÁC NHẬN ĐẶT SÂN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateTotalPrice() {
    if (_selectedStartTime == null || _selectedEndTime == null || _selectedCourt == null) {
      return 0;
    }
    
    final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
    final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;
    final durationHours = (endMinutes - startMinutes) / 60;
    
    return durationHours * _selectedCourt!.pricePerHour;
  }

  Widget _buildTimeSlotGrid() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Vui lòng chọn ngày'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn khung giờ:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.green[100],
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text('Trống', style: TextStyle(fontSize: 12)),
            
            const SizedBox(width: 16),
            
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red[100],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text('Đã đặt', style: TextStyle(fontSize: 12)),
            
            const SizedBox(width: 16),
            
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.blue[200],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text('Đang chọn', style: TextStyle(fontSize: 12)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = _timeSlots[index];
            final isBooked = _selectedCourt != null && 
                _isTimeSlotBooked(timeSlot, _selectedCourt!);
            final isSelected = _selectedStartTime != null && 
                '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}' == timeSlot;
            
            return GestureDetector(
              onTap: isBooked ? null : () {
                final timeParts = timeSlot.split(':');
                final selectedTime = TimeOfDay(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                );
                
                if (_selectedStartTime == null) {
                  setState(() {
                    _selectedStartTime = selectedTime;
                  });
                } else if (_selectedEndTime == null) {
                  final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
                  final endMinutes = selectedTime.hour * 60 + selectedTime.minute;
                  
                  if (endMinutes > startMinutes) {
                    setState(() {
                      _selectedEndTime = selectedTime;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thời gian kết thúc phải sau thời gian bắt đầu'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  setState(() {
                    _selectedStartTime = selectedTime;
                    _selectedEndTime = null;
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isBooked
                      ? Colors.red[100]
                      : isSelected
                          ? Colors.blue[200]
                          : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isBooked 
                        ? Colors.red 
                        : isSelected 
                            ? Colors.blue 
                            : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    timeSlot,
                    style: TextStyle(
                      color: isBooked ? Colors.red : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookingList() {
    final bookingsForDay = _getBookingsForDay(_selectedDay!);
    
    if (bookingsForDay.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có lịch đặt sân',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookingsForDay.length,
      itemBuilder: (context, index) {
        final booking = bookingsForDay[index];
        final court = _courts.firstWhere(
          (c) => c.id == booking.courtId,
          orElse: () => Court(id: '', name: 'Unknown', pricePerHour: 0, isActive: false),
        );
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _courtColors[court.name]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _courtColors[court.name] ?? Colors.grey),
              ),
              child: Center(
                child: Text(
                  court.name.split(' ')[1],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _courtColors[court.name],
                  ),
                ),
              ),
            ),
            title: Text(court.name),
            subtitle: Text(
              '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,###').format(booking.totalPrice)} VND',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: booking.status == 'Confirmed' ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: booking.status == 'Confirmed' ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    // Show all bookings sorted by date desc
    final allBookings = List<Booking>.from(_bookings)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (allBookings.isEmpty) {
      return const Center(
        child: Text('Chưa có lịch sử đặt sân'),
      );
    }

    return ListView.builder(
      itemCount: allBookings.length,
      itemBuilder: (context, index) {
        final booking = allBookings[index];
        final court = _courts.firstWhere(
          (c) => c.id == booking.courtId,
          orElse: () => Court(id: '', name: 'Sân ${booking.courtId}', pricePerHour: 0, isActive: false),
        );
        final isPast = booking.endTime.isBefore(DateTime.now());

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          color: isPast ? Colors.grey[100] : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy').format(booking.startTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPast ? Colors.grey : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPast ? 'Đã hoàn thành' : 'Sắp tới',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sports_tennis, color: Colors.blue),
                  title: Text(court.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  trailing: Text(
                    '${NumberFormat('#,###').format(booking.totalPrice)} đ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final events = _getBookingsForCalendar();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt sân'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Thông tin thành viên'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Họ tên: ${user.fullName}'),
                        Text('Hạng: ${user.tier}'),
                        Text('Số dư: ${NumberFormat('#,###').format(user.walletBalance ?? 0)} VND'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading && _courts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(16),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TableCalendar(
                                firstDay: DateTime.now(),
                                lastDay: DateTime.now().add(const Duration(days: 90)),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                    _selectedStartTime = null;
                                    _selectedEndTime = null;
                                    _selectedCourt = null;
                                  });
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() {
                                    _focusedDay = focusedDay;
                                  });
                                },
                                eventLoader: (day) => events[day] ?? [],
                                calendarStyle: CalendarStyle(
                                  selectedDecoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  markersAutoAligned: true,
                                  markerDecoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  markerSize: 5,
                                ),
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  titleTextStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  leftChevronIcon: const Icon(Icons.chevron_left),
                                  rightChevronIcon: const Icon(Icons.chevron_right),
                                ),
                                daysOfWeekStyle: const DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                                  weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.blue[50],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ngày: ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedCourt != null)
                                      Text(
                                        'Sân: ${_selectedCourt!.name}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                                if (user != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Text(
                                      '${NumberFormat('#,###').format(user.walletBalance)} VND',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: SliverAppBarDelegate(
                        const TabBar(
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: [
                            Tab(text: 'Danh sách sân'),
                            Tab(text: 'Lịch đã đặt'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Danh sách sân:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _courts.map((court) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _courtColors[court.name]?.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _courtColors[court.name] ?? Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _courtColors[court.name],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${court.name} - ${NumberFormat('#,###').format(court.pricePerHour)} VND/h'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          _buildTimeSlotGrid(),
                          const SizedBox(height: 24),
                          if (_selectedCourt != null || _selectedStartTime != null || _selectedEndTime != null)
                            Card(
                              color: Colors.grey[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Thông tin đã chọn:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (_selectedCourt != null)
                                      Row(
                                        children: [
                                          const Text('Sân: '),
                                          Text(
                                            _selectedCourt!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (_selectedStartTime != null)
                                      Row(
                                        children: [
                                          const Text('Bắt đầu: '),
                                          Text(
                                            _selectedStartTime!.format(context),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (_selectedEndTime != null)
                                      Row(
                                        children: [
                                          const Text('Kết thúc: '),
                                          Text(
                                            _selectedEndTime!.format(context),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (_selectedCourt != null && _selectedStartTime != null && _selectedEndTime != null)
                                      Row(
                                        children: [
                                          const Text('Tổng tiền: '),
                                          Text(
                                            '${NumberFormat('#,###').format(_calculateTotalPrice())} VND',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildBookingList(), // Corrected to use daily booking list
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildHistoryList(),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showBookingForm,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Đặt sân'),
      ),
    );
  }
}