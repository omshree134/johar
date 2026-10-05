import 'package:cloud_firestore/cloud_firestore.dart';

/// A server-signed or on-device signed certificate, cached on the phone so the QR works offline.
class CertificateRecord {
  CertificateRecord({
    required this.certId,
    required this.workerId,
    required this.moduleId,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
    required this.status,
  });

  final String certId;
  final String workerId;
  final String moduleId;
  final String token; // the exact string encoded in the QR: SS1.<payload>.<signature>
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String status; // active | revoked

  Map<String, dynamic> toJson() => {
        'certId': certId,
        'workerId': workerId,
        'moduleId': moduleId,
        'token': token,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status,
      };

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is num) {
      final n = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(n > 10000000000 ? n : n * 1000);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  factory CertificateRecord.fromJson(Map<String, dynamic> j) => CertificateRecord(
        certId: j['certId'] as String? ?? '',
        workerId: j['workerId'] as String? ?? '',
        moduleId: j['moduleId'] as String? ?? '',
        token: j['token'] as String? ?? '',
        issuedAt: _parseDate(j['issuedAt']),
        expiresAt: _parseDate(j['expiresAt']),
        status: j['status'] as String? ?? 'active',
      );

  factory CertificateRecord.fromFirestore(String id, Map<String, dynamic> d) => CertificateRecord(
        certId: id,
        workerId: d['workerId'] as String? ?? '',
        moduleId: d['moduleId'] as String? ?? '',
        token: d['token'] as String? ?? '',
        issuedAt: _parseDate(d['issuedAt']),
        expiresAt: _parseDate(d['expiresAt']),
        status: d['status'] as String? ?? 'active',
      );
}
