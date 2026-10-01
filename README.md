# PadosiPro — Full-Stack Take-Home Assignment

> **Lifestyle Management Platform** — Native Android Mobile Client (Flutter 3.x) + Asynchronous REST API Backend (Python 3.11 · FastAPI · SQLAlchemy 2.0 Async · SQLite/Postgres).

---

## 📌 Executive Summary & Assessment Checklist

This repository implements the complete end-to-end customer journey specified in the **PadosiPro Full-Stack Developer Take-Home Assignment (Brief version 1.0, September 2026)**.

| Area | Requirement | Status | Implementation Details |
|---|---|---|---|
| **Part A: Backend** | Single-command local startup | ✅ Complete | Docker Compose (`docker compose up --build`) & manual virtualenv setup |
| | Register with email & password | ✅ Complete | Passwords hashed strictly with native `bcrypt` (never plain or reversible) |
| | Email OTP verification | ✅ Complete | 6-digit code, 10-minute validity, single-use, 5 failed attempt limit, 30s resend cooldown. Stored **exclusively as SHA-256 hash**. Console/Ethereal mailer fallback |
| | Login for verified users | ✅ Complete | Rejects unverified accounts; issues dual JWT token pair (Access + rotated Refresh token) |
| | User Profile | ✅ Complete | Saves Name, Indian Mobile (`+91`, 10 digits), Address, and optional Business Name |
| | Task Catalogue | ✅ Complete | Seeded with **15 categories and 61 tasks** modeled directly on `app.padosipro.com` and `seed.py` |
| | Task Selection & Storage | ✅ Complete | Saves and retrieves user-selected tasks and active requests (`/users/me/requests`) |
| | Server-side validation | ✅ Complete | Strict Pydantic v2 schemas with structured error codes and human-readable feedback |
| **Part B: Mobile** | Native framework | ✅ Complete | 100% native Flutter 3.x (no WebViews); responsive on all screen sizes |
| | Register Screen | ✅ Complete | Email, password, confirm password, and phone number with inline regex validation |
| | Verify Email (OTP) | ✅ Complete | Interactive 6-digit PIN input with morphing hexagon nodes, rotating neon edges, 30s countdown timer, and clear error banners |
| | Login Screen | ✅ Complete | Returning user flow; session persistence via hardware-backed Keystore (`FlutterSecureStorage`) |
| | First-login Profile Setup | ✅ Complete | Automatically presented after initial verification; collects Name, Phone, Address/Society, and Business Name |
| | Task Selection Screen | ✅ Complete | Categories with real-time search, multi-select, and 3-step confirmation (Service ➔ Urgency ➔ Notes) |
| | Dashboard / Home | ✅ Complete | Displays active requests, Lifestyle Manager concierge, 15 text-based categories, popular tasks, and profile dropdown |
| | Error / Loading / Empty states | ✅ Complete | Shimmer skeletons, inline loading indicators, error banners, and zero dead ends |
| | Logout | ✅ Complete | Confirmation modal, token revocation, local storage clearance, and safe redirect to login |
| **Part C: Engineering** | Test suite | ✅ Complete | **25 pytest backend integration tests** covering OTP expiry, attempt lockouts, and auth rules; Flutter test suite passing |
| | Documentation & Design | ✅ Complete | Comprehensive setup guide below and one-page [`DESIGN.md`](./DESIGN.md) architectural rationale |
| | Pre-built Release APK | ✅ Complete | Ready-to-install standalone APK located at [`apk/padosipro-release.apk`](./apk/padosipro-release.apk) (and `mobile/build/app/outputs/flutter-apk/app-release.apk`) |

---

## 🚀 Quick Start Guide (Under 5 Minutes)

### Step 1: Start the Backend API

You can start the backend either with **Docker Compose (Recommended)** or **Manual Python Virtual Environment**.

#### Option A: Docker Compose (One Command)

> **Note**: Ensure the Docker daemon is active on your host. On Linux: `sudo systemctl start docker`. On macOS/Windows: Open Docker Desktop.

From the project root:

```bash
docker compose up --build
```

- **Backend API**: `http://localhost:8000`
- **Interactive Swagger Docs**: `http://localhost:8000/docs`
- **Health Check**: `http://localhost:8000/health`
- **Database**: Automatically runs migrations and seeds all 15 categories and 61 tasks.

#### Option B: Manual Setup (Without Docker)

**On Linux / macOS:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env

# Seed categories and tasks into SQLite
python3 -m src.seed

# Start Uvicorn development server
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

**On Windows (Command Prompt / PowerShell):**
```cmd
cd backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env

REM Seed categories and tasks into SQLite
python -m src.seed

REM Start Uvicorn development server
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

---

### Step 2: Run the Mobile App (Flutter)

#### ⚡ Quick Option: Single Command Launcher
We provide automated launcher scripts that handle ADB port tunneling and launch the app in a single step:
- **On Linux / macOS**: Run `./run_app.sh`
- **On Windows**: Double-click or run `run_app.bat`

Or run manually using the scenario matching your testing setup:

#### 📱 Scenario 1: Physical Android Device via USB (Recommended & Easiest)
If your phone is plugged in via USB (e.g. with `scrcpy` or USB debugging):

```bash
# 1. Forward port 8000 over USB cable to eliminate any Wi-Fi/firewall issues:
adb reverse tcp:8000 tcp:8000

# 2. Run the Flutter app:
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

#### 💻 Scenario 2: Android Emulator
Android emulators access host machine's `localhost` via the special loopback alias `10.0.2.2`:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

#### 📶 Scenario 3: Physical Android Device over Local Wi-Fi (LAN)
Find your computer's local IP address (`ip addr show` or `hostname -I` on Linux/macOS, `ipconfig` on Windows, e.g. `192.168.1.50`):

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<YOUR_COMPUTER_LAN_IP>:8000/api/v1
```

#### 📦 Scenario 4: Install Pre-Built Standalone Release APK
A production release APK is already compiled and provided in the root directory:
- **Location**: [`apk/padosipro-release.apk`](./apk/padosipro-release.apk) (52 MB)
- Also at: `mobile/build/app/outputs/flutter-apk/app-release.apk`

To install directly to a connected device:
```bash
adb reverse tcp:8000 tcp:8000
adb install apk/padosipro-release.apk
```

To build a fresh APK with your specific server IP:
```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:8000/api/v1
```

#### 🌐 Scenario 5: Google Chrome / Desktop Web Browser
Preview the full application journey directly in your web browser:
```bash
cd mobile
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

#### 🖥️ Scenario 6: Windows Desktop Application
Run natively on Windows with full desktop window framing:
```cmd
cd mobile
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

---

## 🔑 OTP & Email Verification in Local Development

When testing locally:
1. Unless custom SMTP credentials are provided in `.env`, the backend prints the generated 6-digit OTP **directly to the backend terminal console** in prominent, easily copyable formatting:
   ```
   ==================================================
   [LOCAL DEV OTP] Code for test@example.com: 123456
   ==================================================
   ```
2. When testing with Ethereal email, a preview URL is automatically logged to view the rendered HTML email in your browser.
3. For production, configure standard SMTP in `backend/.env` (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`).

---

## 🧪 Automated Test Suites

### Backend Unit & Integration Tests (25 Tests Passing)

The backend includes a comprehensive pytest suite covering critical authentication, security, and OTP logic:

```bash
cd backend
source venv/bin/activate
pytest -v
```

**Key Areas Verified:**
- `test_register_and_otp_generation`: User creation, bcrypt hashing, single-use SHA-256 OTP dispatch.
- `test_otp_expiry`: Verifies that OTPs past the 10-minute TTL are rejected.
- `test_otp_rate_limiting`: Verifies 30-second resend cooldown.
- `test_otp_max_attempts`: Locks out and permanently invalidates OTP after 5 consecutive incorrect attempts.
- `test_login_unverified_user_rejected`: Unverified accounts cannot authenticate and are redirected to verification.
- `test_token_rotation_and_revocation`: Access token validation and refresh token single-use rotation.
- `test_task_catalogue_and_requests`: Retrieval of all 15 categories, task creation, and active request queries.

### Mobile Flutter Analyzer & Tests

```bash
cd mobile
flutter analyze     # 0 errors, 0 warnings
flutter test        # All widget and state tests passing
```

---

## 📡 Complete REST API Reference

All requests and responses use JSON format with standard HTTP status codes.

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Public | Register new account with email, password, and optional phone |
| `POST` | `/api/v1/auth/send-otp` | Public | Generate & dispatch a secure 6-digit OTP |
| `POST` | `/api/v1/auth/verify-otp` | Public | Validate OTP; marks user verified and returns JWT token pair |
| `POST` | `/api/v1/auth/login` | Public | Authenticate verified user with email & password |
| `POST` | `/api/v1/auth/refresh` | Public | Rotate refresh token and issue fresh access token |
| `POST` | `/api/v1/auth/logout` | Public | Revoke session refresh token |
| `GET`  | `/api/v1/auth/me` | Bearer JWT | Retrieve current authenticated user record |
| `GET`  | `/api/v1/users/me` | Bearer JWT | Retrieve user profile (Name, Phone, Address, Business) |
| `PUT`  | `/api/v1/users/me/profile` | Bearer JWT | Update user profile and address details |
| `GET`  | `/api/v1/tasks` | Public | Fetch complete catalogue (15 categories & 61 tasks) |
| `POST` | `/api/v1/users/me/requests` | Bearer JWT | Submit a new service request (Category, Service, Timing, Notes) |
| `GET`  | `/api/v1/users/me/requests/active` | Bearer JWT | Fetch user's latest active service request |
| `GET`  | `/health` | Public | Service liveness probe |

---

## 🎨 User Journey & UI Architecture

The mobile app follows a seamless, intuitive flow modeled after `app.padosipro.com` with a refined, tactile light-mode aesthetic:

```
┌──────────────┐      New User      ┌────────────────┐     6-Digit OTP      ┌───────────────┐
│  Login Page  │ ─────────────────► │  Register Page │ ───────────────────► │   OTP Page    │
└──────┬───────┘                    └────────────────┘                      └───────┬───────┘
       │                                                                            │
       │ Returning User                                                             │ Verified
       ▼                                                                            ▼
┌──────────────┐                        Active Request                      ┌───────────────┐
│  Home Page   │ ◄───────────────────────────────────────────────────────── │ Profile Setup │
└──────┬───────┘                                                            └───────────────┘
       │                                                                            │
       │ "What are you looking for?"                                                │ First-time
       ▼                                                                            ▼
┌──────────────┐                     ┌────────────────┐                     ┌───────────────┐
│  Task Select │ ──────────────────► │ Request Timing │ ──────────────────► │ Request Notes │
└──────────────┘   Choose Service    └────────────────┘    Select Urgency   └───────────────┘
```

1. **Login & Register**:
   - Smooth horizontal slide transitions with aligned logos and titles.
   - Signature `SwipeConfirmButton` unified pill handle with micro-animations.
2. **OTP Verification**:
   - 6 boxes smoothly morph into a hexagon arrangement upon entering the 6th digit.
   - Active neon perimeter edges rotate clockwise around the node perimeter (never overlapping behind the boxes).
   - Real-time countdown timer with 30s resend cooldown.
3. **First-Login Profile Setup**:
   - Collects Full Name, Indian Mobile (`+91`, 10 digits), Society / Community, Flat / Unit, and optional Business Name.
4. **Interactive Dashboard**:
   - **Pinned Header**: Location selector (society / address details sheet) and Profile dropdown menu with **Profile** and **Logout** options.
   - **Active Request Tracker**: Live status chip (`Pickups & Deliveries`, `We are looking at it`, `View Details`).
   - **15 Categories**: Wide cards with icons, category titles, and text-based descriptions directly from `seed.py`.
   - **Popular Everyday Tasks**: Vibrant cards with ratings, timing urgency chips, and one-tap booking.
   - **"Explore by Need"**: Fast text-based chips for everyday household tasks.

---

## 🔒 Security Architecture Highlights

- **Password Hashing**: Native `bcrypt` algorithm with work factor 12. Plaintext passwords are never stored or logged.
- **OTP Protection**: 6-digit OTPs are digested with **SHA-256** prior to database persistence. Even with direct database read access, OTPs cannot be recovered.
- **Brute-Force Lockout**: Server limits incorrect attempts to 5 per OTP; exceeding this threshold permanently revokes the code.
- **Dual-Token Rotation**: 60-minute access token combined with a 7-day single-use refresh token rotated on every refresh call.
- **Client Storage**: Tokens are stored using AES-256 hardware encryption via Android Keystore (`flutter_secure_storage`).

For complete architectural trade-offs, scope decisions, and next steps, read [**`DESIGN.md`**](./DESIGN.md).
