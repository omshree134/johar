class Worker {
  Worker({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.employer,
    required this.sector,
    required this.language,
    required this.createdAt,
    this.synced = false,
  });

  final String id; // uuid, generated on the phone
  final String name;
  final String employeeId;
  final String employer;
  final String sector; // coal | steel | mica
  final String language;
  final DateTime createdAt;
  bool synced;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'employeeId': employeeId,
        'employer': employer,
        'sector': sector,
        'language': language,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory Worker.fromJson(Map<String, dynamic> j) => Worker(
        id: j['id'] as String,
        name: j['name'] as String,
        employeeId: j['employeeId'] as String? ?? '',
        employer: j['employer'] as String? ?? '',
        sector: j['sector'] as String? ?? 'coal',
        language: j['language'] as String? ?? 'en',
        createdAt: DateTime.parse(j['createdAt'] as String),
        synced: j['synced'] as bool? ?? false,
      );

  /// Shape written to Firestore (no local-only fields).
  Map<String, dynamic> toFirestore(String deviceUid) => {
        'name': name,
        'employeeId': employeeId,
        'employer': employer,
        'sector': sector,
        'language': language,
        'createdAt': createdAt.toIso8601String(),
        'deviceUid': deviceUid,
      };
}
