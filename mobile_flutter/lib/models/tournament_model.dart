class Tournament {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String format;
  final double entryFee;
  final double prizePool;
  final String status;
  final String description;
  final int maxParticipants;
  final int currentParticipants;
  final String organizer;

  Tournament({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    required this.description,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.organizer,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      startDate: DateTime.parse(json['startDate']?.toString() ?? DateTime.now().toString()),
      endDate: DateTime.parse(json['endDate']?.toString() ?? DateTime.now().toString()),
      format: json['format'] ?? 'Knockout',
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      status: json['status'] ?? 'Open',
      description: json['description'] ?? '',
      maxParticipants: json['maxParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      organizer: json['organizer'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'format': format,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'status': status,
      'description': description,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'organizer': organizer,
    };
  }
}