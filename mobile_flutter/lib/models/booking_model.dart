class Booking {
  final String id;
  final String courtId;
  final String memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final String? transactionId;
  final bool? isRecurring;
  final String? recurrenceRule;
  final String? parentBookingId;

  Booking({
    required this.id,
    required this.courtId,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    this.totalPrice = 0,
    this.status = 'Pending',
    this.transactionId,
    this.isRecurring,
    this.recurrenceRule,
    this.parentBookingId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id']?.toString() ?? '',
      courtId: json['courtId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      startTime: DateTime.parse(json['startTime']?.toString() ?? DateTime.now().toString()),
      endTime: DateTime.parse(json['endTime']?.toString() ?? DateTime.now().toString()),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      transactionId: json['transactionId']?.toString(),
      isRecurring: json['isRecurring'],
      recurrenceRule: json['recurrenceRule'],
      parentBookingId: json['parentBookingId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courtId': courtId,
      'memberId': memberId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalPrice': totalPrice,
      'status': status,
      'transactionId': transactionId,
      'isRecurring': isRecurring,
      'recurrenceRule': recurrenceRule,
      'parentBookingId': parentBookingId,
    };
  }
}

class Court {
  final String id;
  final String name;
  final int pricePerHour;
  final bool isActive;
  final String? description;

  Court({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.isActive,
    this.description,
  });
}