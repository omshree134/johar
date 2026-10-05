import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:johar/core/config/cert_keys.dart';
import 'package:johar/features/certificate/certificate_codec.dart';

/// Mirrors buildToken() in firebase/functions/index.js.
Future<String> sign(Map<String, dynamic> payload, SimpleKeyPair kp) async {
  final body = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  final sig = await Ed25519().sign(ascii.encode(body), keyPair: kp);
  return 'SS1.$body.${base64Url.encode(sig.bytes).replaceAll('=', '')}';
}

void main() {
  late SimpleKeyPair kp;
  late CertificateCodec codec;
  final now = DateTime(2026, 10, 1);
  int epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> payload({DateTime? expires}) => {
        'v': 1,
        'c': 'abc12345-0000',
        'w': 'worker-1',
        'n': 'सुनीता मुर्मू',
        'e': 'BCCL-4471',
        'm': 'fire',
        's': 88,
        'i': epoch(now.subtract(const Duration(days: 1))),
        'x': epoch(expires ?? now.add(const Duration(days: 364))),
      };

  setUp(() async {
    kp = await Ed25519().newKeyPair();
    codec = CertificateCodec((await kp.extractPublicKey()).bytes);
  });

  test('genuine certificate is valid', () async {
    final r = await codec.verify(await sign(payload(), kp), now: now);
    expect(r.status, VerifyStatus.valid);
    expect(r.payload!.workerName, 'सुनीता मुर्मू');
    expect(r.payload!.moduleId, 'fire');
  });

  test('edited score is rejected', () async {
    final token = await sign(payload(), kp);
    final parts = token.split('.');
    final forged = Map<String, dynamic>.from(payload())..['s'] = 100;
    final forgedBody = base64Url.encode(utf8.encode(jsonEncode(forged))).replaceAll('=', '');
    final r = await codec.verify('SS1.$forgedBody.${parts[2]}', now: now);
    expect(r.status, VerifyStatus.invalidSignature);
  });

  test('certificate signed by another key is rejected', () async {
    final other = await Ed25519().newKeyPair();
    final r = await codec.verify(await sign(payload(), other), now: now);
    expect(r.status, VerifyStatus.invalidSignature);
  });

  test('expired certificate is reported as expired', () async {
    final r = await codec.verify(await sign(payload(expires: now.subtract(const Duration(days: 1))), kp), now: now);
    expect(r.status, VerifyStatus.expired);
  });

  test('random QR codes are malformed', () async {
    expect((await codec.verify('https://example.com')).status, VerifyStatus.malformed);
    expect((await codec.verify('SS1.@@@.###')).status, VerifyStatus.malformed);
  });

  test('app without a configured key says so', () async {
    expect((await CertificateCodec(null).verify('SS1.a.b')).status, VerifyStatus.notConfigured);
  });

  test('production generateToken verifies with CertificateCodec.production', () async {
    final token = await CertificateCodec.generateToken(
      certId: 'abc12345-0000',
      workerId: 'worker-1',
      workerName: 'सुनीता मुर्मू',
      employeeId: 'BCCL-4471',
      moduleId: 'fire',
      score: 88,
      issuedAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 364)),
    );
    expect(token, isNotNull);
    final res = await CertificateCodec.production().verify(token!, now: now);
    expect(res.status, VerifyStatus.valid);
    expect(res.payload!.workerName, 'सुनीता मुर्मू');
  });

  test('check keys match', () async {
    final privBytes = base64Url.decode(base64Url.normalize(certPrivateKeyB64));
    final kp = await Ed25519().newKeyPairFromSeed(privBytes);
    final pubKey = await kp.extractPublicKey();
    final pubB64 = base64Url.encode(pubKey.bytes).replaceAll('=', '');
    expect(pubB64, certPublicKeyB64);
  });
}
