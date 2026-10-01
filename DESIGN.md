# PadosiPro — Design & Architecture Document

## 1. System Architecture

PadosiPro is architected as an offline-resilient, mobile-first lifestyle management client communicating with a lightweight, asynchronous REST backend.

```
┌────────────────────────────────┐        HTTP / JSON         ┌─────────────────────────────────┐
│       Flutter Mobile App       │ ─────────────────────────► │       FastAPI REST Backend      │
│  Riverpod 2 · GoRouter · Dio   │ ◄───────────────────────── │  SQLAlchemy 2.0 · SQLite/Postgres│
└────────────────────────────────┘      Bearer JWT (Auth)     └─────────────────────────────────┘
                │                                                              │
         TokenStorage                                                   aiosmtplib (SMTP)
  (FlutterSecureStorage: AES-256)                                     Email OTP Notification
```

### Mobile & Cross-Platform Client Layer (Flutter 3.x)
- **Multi-Platform Target**: 100% native Android application as primary target (with pre-compiled APK), with out-of-the-box support for Windows Desktop and Web using Flutter's unified engine.
- **State Management**: **Riverpod 2** (`StateNotifierProvider` & `FutureProvider`) provides immutable, compile-time safe dependency injection and clear state separation without UI coupling.
- **Routing**: **GoRouter 14** manages declarative URL-based routing with reactive redirection driven by an auth stream. Deep linking and modal routes are cleanly separated.
- **Networking**: **Dio 5** with an automated retry and token rotation interceptor. Secure local credential storage is backed by Android Keystore (`flutter_secure_storage`).
- **UI/UX Philosophy**: Faithful to `app.padosipro.com` with a refined, tactile light theme inspired by Classy Professional Service. Micro-animations (dynamic hexagon OTP nodes, animated size category expansions, tactile button presses) elevate user delight without latency.

### Backend Layer (FastAPI + SQLAlchemy 2.0 Async)
- **Runtime**: Python 3.11+ running on Uvicorn with `asyncio`.
- **Database Engine**: Async SQLite (`sqlite+aiosqlite`) for zero-dependency local review, with native support for PostgreSQL via environment variable configuration.
- **Validation**: Pydantic v2 schemas enforce strict input boundaries and return structured error codes.

---

## 2. Key Architectural Decisions & Security Trade-offs

### Cryptographic OTP & Password Storage
- **Passwords**: Hashed with **bcrypt** (cost factor 12) via native C-bindings. Plaintext passwords never touch persistence.
- **Email OTPs**: Single-use 6-digit codes stored **exclusively as SHA-256 digests**. An attacker gaining read-only DB access cannot retrieve or forge OTPs.
- **Brute-Force & Rate Limiting**: Each OTP is constrained by a 10-minute TTL, a maximum of 5 failed attempts before permanent invalidation, and a 30-second cooldown window to prevent email provider abuse.

### Dual-Token JWT Auth with Server-Side Refresh Rotation
- Access tokens expire after 60 minutes.
- Refresh tokens are cryptographically random, stored as SHA-256 hashes in the DB, and rotated upon every use. When a refresh token is used, it is revoked and replaced, detecting token re-use attacks.

### Why "Business Name" is Optional
PadosiPro serves both **residential households** (who request personal errands, elderly care, and home cleaning) and **home-based entrepreneurs / small business owners** (who request logistics, GST filings, and workforce management). Making `business_name` mandatory would introduce unnecessary friction for individual households. Making it optional accommodates both user segments naturally.

---

## 3. Scope & Conscious Trade-offs (What Was Left Out)

1. **Nested Service Sub-trees**: The web application contains multi-level hierarchical trees for specific sub-categories. To keep the mobile UX intuitive and lightweight on small screens, a clean **one-level accordion** pattern was chosen.
2. **Third-Party OAuth / Firebase**: Avoided to ensure the project can be spun up completely offline and reviewed with zero third-party vendor lock-in or proprietary keys.
3. **WebSockets for Live Chat**: The Lifestyle Manager chat is designed with an HTTP polling / placeholder interface; full two-way WebSocket messaging was deferred to production.

---

## 4. What We Would Do Next (With Another Week)

1. **Real-time Lifestyle Manager Chat**: Build WebSocket-powered chat with media attachments and voice notes to communicate directly with the assigned LM.
2. **Push Notifications**: Integrate APNs and FCM for real-time request status updates ("Assigned", "In Progress", "Completed with Proof").
3. **Database Migration Pipeline**: Integrate Alembic auto-migrations in CI/CD for zero-downtime schema upgrades.
4. **End-to-End Mobile Integration Tests**: Write Flutter integration tests simulating user signup, OTP verification, service selection, and submission on real devices.
