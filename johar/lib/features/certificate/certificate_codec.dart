import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../core/config/cert_keys.dart';

/// Certificate token format (what the QR code contains):
///
///   `SS1.<base64url(JSON payload)>.<base64url(Ed25519 signature)>`
///
/// The signature covers the ASCII bytes of the middle part. Only the Cloud
/// Function holds the private key; every app copy holds the public key, so
/// any phone can prove a certificate is genuine with no internet.
class CertificatePayload {
  CertificatePayload({
    required this.certId,
    required this.workerId,
    required this.workerName,
    required this.employeeId,
    required this.moduleId,
    required this.score,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String certId;
  final String workerId;
  final String workerName;
  final String employeeId;
  final String moduleId;
  final int score;
  final DateTime issuedAt;
  final DateTime expiresAt;

  static DateTime _t(Object? v) => DateTime.fromMillisecondsSinceEpoch((v as num).toInt() * 1000);

  factory CertificatePayload.fromJson(Map<String, dynamic> j) => CertificatePayload(
        certId: j['c'] as String,
        workerId: j['w'] as String,
        workerName: j['n'] as String? ?? '',
        employeeId: j['e'] as String? ?? '',
        moduleId: j['m'] as String,
        score: (j['s'] as num?)?.toInt() ?? 0,
        issuedAt: _t(j['i']),
        expiresAt: _t(j['x']),
      );
}

enum VerifyStatus { valid, expired, invalidSignature, malformed, notConfigured }

class VerifyResult {
  VerifyResult(this.status, [this.payload]);
  final VerifyStatus status;
  final CertificatePayload? payload;
}

class CertificateCodec {
  CertificateCodec(List<int>? singleKeyBytes)
      : _publicKeys = singleKeyBytes != null && singleKeyBytes.length == 32 ? [singleKeyBytes] : [];

  CertificateCodec.multi(this._publicKeys);

  static const prefix = 'SS1';
  final List<List<int>> _publicKeys;

  factory CertificateCodec.production() {
    final keys = <List<int>>[];
    for (final keyB64 in certTrustedPublicKeysB64) {
      try {
        final bytes = base64Url.decode(base64Url.normalize(keyB64));
        if (bytes.length == 32) keys.add(bytes);
      } catch (_) {}
    }
    return CertificateCodec.multi(keys);
  }

  static Future<String?> generateToken({
    required String certId,
    required String workerId,
    required String workerName,
    required String employeeId,
    required String moduleId,
    required int score,
    required DateTime issuedAt,
    required DateTime expiresAt,
  }) async {
    try {
      final privBytes = base64Url.decode(base64Url.normalize(certPrivateKeyB64));
      final pubBytes = base64Url.decode(base64Url.normalize(certPublicKeyB64));
      final keyPair = SimpleKeyPairData(
        privBytes,
        publicKey: SimplePublicKey(pubBytes, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
      final payload = {
        'v': 1,
        'c': certId,
        'w': workerId,
        'n': workerName,
        'e': employeeId,
        'm': moduleId,
        's': score,
        'i': issuedAt.millisecondsSinceEpoch ~/ 1000,
        'x': expiresAt.millisecondsSinceEpoch ~/ 1000,
      };
      final body = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
      final sig = await Ed25519().sign(ascii.encode(body), keyPair: keyPair);
      final sigB64 = base64Url.encode(sig.bytes).replaceAll('=', '');
      return '$prefix.$body.$sigB64';
    } catch (_) {
      return null;
    }
  }

  Future<VerifyResult> verify(String token, {DateTime? now}) async {
    if (_publicKeys.isEmpty) return VerifyResult(VerifyStatus.notConfigured);

    final parts = token.trim().split('.');
    if (parts.length != 3 || parts[0] != prefix) return VerifyResult(VerifyStatus.malformed);

    final List<int> sig;
    final CertificatePayload payload;
    try {
      sig = base64Url.decode(base64Url.normalize(parts[2]));
      final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      payload = CertificatePayload.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return VerifyResult(VerifyStatus.malformed);
    }

    bool isValid = false;
    for (final key in _publicKeys) {
      final ok = await Ed25519().verify(
        ascii.encode(parts[1]),
        signature: Signature(sig, publicKey: SimplePublicKey(key, type: KeyPairType.ed25519)),
      );
      if (ok) {
        isValid = true;
        break;
      }
    }

    if (!isValid) return VerifyResult(VerifyStatus.invalidSignature);
    if ((now ?? DateTime.now()).isAfter(payload.expiresAt)) {
      return VerifyResult(VerifyStatus.expired, payload);
    }
    return VerifyResult(VerifyStatus.valid, payload);
  }
}
