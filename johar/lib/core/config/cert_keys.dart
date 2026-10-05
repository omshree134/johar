/// Ed25519 PUBLIC key used to verify certificate QR codes offline.
const String certPublicKeyB64 = 'Clc0OWfREqD2OcnMAEELxg2mJH_A11-BdKX2yxqEZiQ';

/// Trusted public keys (current and legacy) for offline certificate verification.
const List<String> certTrustedPublicKeysB64 = [
  'Clc0OWfREqD2OcnMAEELxg2mJH_A11-BdKX2yxqEZiQ',
  'W1ZiQ98zHY_Azuhbq2ZZBSbLUhSeUCpLwlQBWDpTl9E',
];

/// Ed25519 PRIVATE key used for instant on-device certificate generation
/// when offline or when Firebase Cloud Functions are not yet deployed.
const String certPrivateKeyB64 = 'OCUd1jGYnRcWNQymIHZn-Fzu_7tH8Ex4wHhrSX2f73w';

/// Minimum total score (percent) to pass a module. Keep in sync with
/// PASS_MARK in firebase/functions/index.js.
const int kPassMark = 70;
