# Johar (Suraksha Saathi)

AR safety training, assessment, and cryptographic offline certification for industrial workers in Jharkhand's mines, steel plants, and mica processing units.

> **Full Documentation**: See root [README.md](../README.md) for complete technical architecture, Ed25519 offline QR certificate details, Ol Chiki speech synthesis, and setup guides.

---

## Quick Start

```bash
# 1. Install dependencies and generate localizations
flutter pub get
flutter gen-l10n

# 2. Run unit tests
flutter test

# 3. Run application on connected Android device
flutter run
```

---

## Highlights

- **Offline-First Architecture**: All training modules bundled inside the app (`assets/modules/*.json`) with atomic local JSON storage (`LocalStore`).
- **Offline Cryptographic Certificates**: Ed25519-signed QR codes verifiable anywhere without internet connection.
- **Tri-Lingual & Ol Chiki Speech**: English, Hindi, and Santali (Ol Chiki script) with matra-aware transliteration for native speech synthesis.
- **Strict Guardrails**: 70% pass threshold with mandatory critical question checks.
- **ISO 7010 Design System**: Color-coded safety visual tokens optimized for low-literacy workers in bright outdoor mine conditions.
