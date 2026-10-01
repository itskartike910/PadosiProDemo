# PadosiPro Backend API 🚀

> **High-performance, asynchronous REST API for PadosiPro — Lifestyle Management Platform.**  
> Powered by **Python 3.11+ · FastAPI · SQLAlchemy 2.0 (Async) · Pydantic v2 · SQLite / PostgreSQL · Docker Compose**.

---

## 📋 Table of Contents

- [Overview & Architecture](#-overview--architecture)
- [Assessment Requirements Compliance (Part A)](#-assessment-requirements-compliance-part-a)
- [Project Layout](#-project-layout)
- [Data Models & Relational Schema](#-data-models--relational-schema)
- [Authentication & Security Architecture](#-authentication--security-architecture)
- [How to Run with Docker (Step-by-Step)](#-how-to-run-with-docker-step-by-step)
- [Manual Local Setup (Without Docker)](#-manual-local-setup-without-docker)
- [Client-Backend Communication Scenarios](#-client-backend-communication-scenarios)
- [API Reference & Endpoints](#-api-reference--endpoints)
- [Environment Variables & Configuration](#-environment-variables--configuration)
- [Testing & Quality Assurance (25 Tests Passing)](#-testing--quality-assurance-25-tests-passing)
- [Database Switching (PostgreSQL / SQLite)](#-database-switching-postgresql--sqlite)

---

## 🏛️ Overview & Architecture

The PadosiPro backend is the core business engine connecting residents to dedicated Lifestyle Managers and on-demand household services. Built with FastAPI and modern asynchronous Python, it delivers sub-millisecond response times, complete type safety, and zero external vendor lock-in.

```
┌────────────────────────────────────────────────────────┐
│               FastAPI Application Layer                │
│    (CORS · Global Exception Handler · Async Lifespan)  │
└───────────────────────────┬────────────────────────────┘
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Auth Module │    │  User Module │    │ Tasks Module │
│  · Register  │    │  · Profile   │    │  · 15 Cats   │
│  · Login     │    │  · Requests  │    │  · 61 Tasks  │
│  · Email OTP │    │  · Tasks     │    │  · Seed data │
│  · Refresh   │    │              │    │              │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│           SQLAlchemy 2.0 Async ORM Layer               │
│   (SQLite+aiosqlite for Dev · PostgreSQL for Prod)     │
└────────────────────────────────────────────────────────┘
```

---

## 📌 Assessment Requirements Compliance (Part A)

| Requirement | Implementation Detail | Status |
|---|---|---|
| **One-command execution** | `docker compose up --build` or `uvicorn src.main:app --host 0.0.0.0 --port 8000` | ✅ Met |
| **Password Storage** | Passwords hashed using native `bcrypt` (never plain or reversible) | ✅ Met |
| **Email OTP** | 6-digit code, 10 min TTL, single-use, 5 failed attempts limit, 30s resend cooldown. Stored **exclusively as SHA-256 hash**. Console fallback or real SMTP/Ethereal | ✅ Met |
| **Login Verified Only** | Only verified users receive JWT tokens. Unverified users receive `403 EMAIL_NOT_VERIFIED`, dispatching a fresh OTP to complete verification | ✅ Met |
| **Profile Storage** | Name, Indian Mobile (`+91`, 10 digits), Address (Society, Flat/Unit, Gate Notes), and Business Name | ✅ Met |
| **Optional Business Name Rationale** | Households use PadosiPro for domestic errands, whereas local entrepreneurs use it for logistics and staffing. Enforcing business name would add unnecessary friction for individual households | ✅ Met |
| **Task Catalogue** | Seeded with **15 categories and 61 tasks** modeled directly on `app.padosipro.com` | ✅ Met |
| **Task Selection & Requests** | Saves picked tasks (`/users/me/tasks`) and multi-step service requests (`/users/me/requests`) | ✅ Met |
| **Input Validation & Errors** | Strict Pydantic v2 schemas; unified JSON envelope `{ success: bool, data: ..., error: { code, message } }` | ✅ Met |

---

## 📂 Project Layout

```
backend/
├── src/
│   ├── main.py                  # FastAPI application entry point, lifecycle, CORS
│   ├── config.py                # Pydantic BaseSettings loading from .env
│   ├── database.py              # Async SQLAlchemy engine & session maker
│   ├── models.py                # ORM models: User, OtpCode, RefreshToken, Category, Task, UserTask, UserRequest
│   ├── security.py              # bcrypt password hashing, SHA-256 OTP hashing, JWT encoding/decoding
│   ├── mailer.py                # Async SMTP client with dev console fallback & Ethereal support
│   ├── responses.py             # Standardized JSON response envelopes (ok, created, error)
│   ├── seed.py                  # 15 categories & 61 lifestyle tasks from app.padosipro.com (idempotent)
│   └── modules/
│       ├── auth/
│       │   ├── router.py        # /auth endpoints (register, login, verify-otp, send-otp, refresh, logout, me)
│       │   └── schemas.py       # Pydantic schemas for auth requests/responses
│       ├── user/
│       │   ├── router.py        # /users endpoints (profile CRUD, selected tasks, active requests)
│       │   └── schemas.py       # Pydantic schemas for user profile updates
│       └── tasks/
│           ├── router.py        # /tasks catalogue endpoints
│           └── schemas.py       # Pydantic schemas for task categories
├── tests/
│   ├── conftest.py              # Pytest async fixtures, test database setup
│   ├── test_otp.py              # 14 unit tests: security, OTP math, cooldowns, attempts & JWT
│   └── test_auth_integration.py # 11 integration tests: register, verify, login, unverified lockouts, tasks
├── Dockerfile                   # Python 3.11-slim container with auto-seed and uvicorn startup
├── requirements.txt             # Locked Python dependencies
├── pytest.ini                   # Pytest configuration
├── .env.example                 # Sample configuration template
└── README.md                    # This documentation file
```

---

## 🗄️ Data Models & Relational Schema

```mermaid
erDiagram
    USERS ||--o{ OTP_CODES : "receives"
    USERS ||--o{ REFRESH_TOKENS : "owns"
    USERS ||--o{ USER_TASKS : "selects"
    USERS ||--o{ USER_REQUESTS : "creates"
    CATEGORIES ||--o{ TASKS : "contains"
    TASKS ||--o{ USER_TASKS : "assigned to"

    USERS {
        string id PK
        string email UK
        string password_hash
        string phone_number
        string name
        string address
        string society
        string flat_unit
        string gate_notes
        string business_name
        boolean is_email_verified
        boolean is_profile_complete
        datetime created_at
        datetime updated_at
    }

    OTP_CODES {
        string id PK
        string user_id FK
        string code_hash
        datetime expires_at
        int attempts
        boolean used
        datetime created_at
    }

    REFRESH_TOKENS {
        string id PK
        string user_id FK
        string token_hash UK
        datetime expires_at
        datetime created_at
    }

    CATEGORIES {
        string id PK
        string name
        string description
        string icon_name
        int display_order
    }

    TASKS {
        string id PK
        string category_id FK
        string name
        string description
        int display_order
    }

    USER_REQUESTS {
        string id PK
        string user_id FK
        string category_name
        string service_name
        string timing
        string notes
        string status
        datetime created_at
    }
```

---

## 🔒 Authentication & Security Architecture

### 1. Password Hashing (bcrypt)
All passwords submitted to `POST /api/v1/auth/register` are hashed using **bcrypt** with a cost factor of 12. Plaintext passwords never touch persistence or server logs.

### 2. Email OTP Security
- **Digest Storage**: The raw 6-digit OTP code is **never stored** in the database; only its cryptographic `SHA-256` digest is persisted. Direct database exfiltration yields no usable OTPs.
- **Single-Use**: Upon successful verification, the record is immediately marked `used = True`.
- **Expiry Window**: Constrained to a strict **10-minute** TTL.
- **Brute-Force Lockout**: Limited to **5 failed attempts**. On the 5th failed attempt, the code is permanently invalidated.
- **Resend Cooldown**: A **30-second cooldown** prevents email spamming or flooding.

### 3. Local Mail Catcher vs. SMTP
The backend supports two mail delivery modes configured in `.env`:
1. **Developer Console Fallback (Default)**: If SMTP credentials are not configured, OTP codes are logged directly to the server terminal with clear visual demarcation:
   ```
   ==================================================
   [LOCAL DEV OTP] Code for user@example.com: 482910
   ==================================================
   ```
2. **Real SMTP / Ethereal Mailpit**: By setting `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, and `SMTP_PASSWORD`, real HTML emails are dispatched via STARTTLS or captured by tools like Mailpit or Ethereal.

### 4. Dual-Token JWT Auth with Token Rotation
- **Access Token**: Short-lived (60 minutes), signed with `HS256`, containing user ID and email claims.
- **Refresh Token**: Long-lived (7 days), stored in the database as a SHA-256 hash.
- **Token Rotation**: Every call to `POST /api/v1/auth/refresh` revokes the submitted refresh token and issues a brand new access/refresh token pair, mitigating replay attacks.

---

## 🐳 How to Run with Docker (Step-by-Step)

The repository provides a production-grade `docker-compose.yml` and `Dockerfile` enabling single-command startup.

### 1. Ensure Docker Daemon is Running
- **Linux**: `sudo systemctl start docker`
- **macOS / Windows**: Start **Docker Desktop**.

### 2. Start the Backend Container
From the root repository directory (`/mnt/kartik/Documents/padosi-pro`):

```bash
docker compose up --build
```

### 3. What Happens Under the Hood
1. The `Dockerfile` builds a lightweight `python:3.11-slim` container.
2. Installs dependencies from `backend/requirements.txt`.
3. Mounts `./backend/padosipro.db` so all user registrations, OTP records, and service requests **persist on your host machine** even if the container stops.
4. Automatically runs `python -m src.seed` on container startup, seeding all 15 categories and 61 tasks.
5. Launches Uvicorn on port `8000`.

### 4. Verify Backend Health
Open another terminal:
```bash
curl http://localhost:8000/health
# Response: {"status":"ok","database":"connected"}
```

Visit the interactive Swagger UI in your browser:
**`http://localhost:8000/docs`**

### 5. Stopping the Container
```bash
docker compose down
```

---

## 💻 Manual Local Setup (Without Docker)

If you prefer running directly in Python:

### 1. Prerequisites
- Python 3.10+ (tested on Python 3.11, 3.12, 3.13, 3.14)
- `pip` package manager

### 2. Virtual Environment Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Initialize Configuration
```bash
cp .env.example .env
```

### 5. Seed Database & Start Server
```bash
# Seed 15 categories and 61 tasks (idempotent)
python3 -m src.seed

# Start development server with hot-reload
python3 -m uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 🌐 Client-Backend Communication Scenarios

The mobile client and backend must reliably communicate across every development environment. Use the scenario matching your hardware:

### 📱 Scenario 1: Physical Android Device via USB (`adb reverse` - Recommended)
The fastest, most reliable method. Tunnels all device traffic directly through the USB cable:

```bash
# 1. Forward port 8000 over the USB connection
adb reverse tcp:8000 tcp:8000

# 2. Run mobile app pointing to localhost
cd mobile
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```
*Benefits: Works 100% reliably regardless of Wi-Fi router isolation, campus firewalls, or VPNs.*

### 💻 Scenario 2: Android Emulator
The Android emulator uses `10.0.2.2` as an alias to reach the host machine's `localhost`:

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### 📶 Scenario 3: Physical Device over Local Wi-Fi (LAN)
Find your computer's local network IP (`hostname -I` or `ip addr show` on Linux, `ipconfig` on Windows, e.g. `192.168.1.50`):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://<YOUR_COMPUTER_LAN_IP>:8000/api/v1
```

### 📦 Scenario 4: Pre-Built Standalone Release APK
A production APK is already compiled and provided:
- Location: [`apk/padosipro-release.apk`](../apk/padosipro-release.apk) (52 MB)
- Also at: `mobile/build/app/outputs/flutter-apk/app-release.apk`

To install and run:
```bash
adb reverse tcp:8000 tcp:8000
adb install apk/padosipro-release.apk
```

---

## 📡 API Reference & Endpoints

Base URL: `http://localhost:8000/api/v1`  
Interactive Swagger Docs: `http://localhost:8000/docs`

### Authentication (`/api/v1/auth`)

#### 1. Register Account
- **Endpoint**: `POST /api/v1/auth/register`
- **Body**:
  ```json
  {
    "email": "user@example.com",
    "password": "Password123!",
    "confirm_password": "Password123!",
    "phone_number": "+919876543210"
  }
  ```
- **Response `201 Created`**:
  ```json
  {
    "success": true,
    "data": { "email": "user@example.com", "is_email_verified": false },
    "message": "Registration successful. Please verify your email with the OTP."
  }
  ```

#### 2. Verify Email OTP
- **Endpoint**: `POST /api/v1/auth/verify-otp`
- **Body**:
  ```json
  { "email": "user@example.com", "otp": "482910" }
  ```
- **Response `200 OK`**:
  ```json
  {
    "success": true,
    "data": {
      "access_token": "eyJhbGciOi...",
      "refresh_token": "d7a4f...",
      "token_type": "bearer",
      "user": {
        "id": "c1f72a6b-...",
        "email": "user@example.com",
        "name": null,
        "is_profile_complete": false
      }
    }
  }
  ```

#### 3. Login
- **Endpoint**: `POST /api/v1/auth/login`
- **Body**:
  ```json
  { "email": "user@example.com", "password": "Password123!" }
  ```
- **Response `200 OK`**: Returns JWT tokens if verified. If unverified, returns `403` with `{ "needs_verification": true }` and dispatches a fresh OTP.

#### 4. Resend / Send OTP
- **Endpoint**: `POST /api/v1/auth/send-otp`
- **Body**:
  ```json
  { "email": "user@example.com", "phone_number": "+919876543210" }
  ```
- **Response `200 OK`**: Enforces 30s resend cooldown.

#### 5. Refresh Access Token
- **Endpoint**: `POST /api/v1/auth/refresh`
- **Body**: `{ "refresh_token": "d7a4f..." }`
- **Response `200 OK`**: Rotates refresh token and returns new access token.

#### 6. Logout
- **Endpoint**: `POST /api/v1/auth/logout`
- **Body**: `{ "refresh_token": "d7a4f..." }`
- **Response `200 OK`**: Revokes session refresh token from database.

---

### User Profile & Requests (`/api/v1/users`)

#### 1. Get Profile
- **Endpoint**: `GET /api/v1/users/me`
- **Auth**: `Bearer <access_token>`

#### 2. Update Profile
- **Endpoint**: `PUT /api/v1/users/me/profile`
- **Auth**: `Bearer <access_token>`
- **Body**:
  ```json
  {
    "name": "Kartik Kumar",
    "phone_number": "+919876543210",
    "address": "4th Floor, Prestige Tower",
    "society": "Prestige Shantiniketan",
    "flat_unit": "Tower 3, Flat 402",
    "gate_notes": "Leave parcel with security",
    "business_name": "Kumar Tech Consulting"
  }
  ```

#### 3. Save Selected Tasks
- **Endpoint**: `POST /api/v1/users/me/tasks`
- **Auth**: `Bearer <access_token>`
- **Body**: `{ "task_ids": ["task-uuid-1", "task-uuid-2"] }`

#### 4. Submit Service Request
- **Endpoint**: `POST /api/v1/users/me/requests`
- **Auth**: `Bearer <access_token>`
- **Body**:
  ```json
  {
    "category_name": "Errands & Daily Tasks",
    "service_name": "Grocery Pickup & Delivery",
    "timing": "Standard (Within 24 Hours)",
    "notes": "Pick up 5 items from Nature's Basket"
  }
  ```

#### 5. Get Active Service Request
- **Endpoint**: `GET /api/v1/users/me/requests/active`
- **Auth**: `Bearer <access_token>`
- **Response `200 OK`**: Returns user's most recent active request.

---

### Tasks Catalogue (`/api/v1/tasks`)

#### 1. List All Categories & Tasks
- **Endpoint**: `GET /api/v1/tasks`
- **Auth**: None
- **Response `200 OK`**: Returns all 15 categories with their nested tasks and metadata.

---

## ⚙️ Environment Variables & Configuration

Create `backend/.env` from `.env.example`:

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"PadosiPro"` | Application identifier |
| `DATABASE_URL` | `sqlite+aiosqlite:///./padosipro.db` | Async database connection string |
| `JWT_SECRET_KEY` | `supersecretjwtkeyforpadosiproproduction2026` | HMAC-SHA256 signature key |
| `JWT_ALGORITHM` | `HS256` | JWT signing algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `60` | Validity duration of access JWT |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | `7` | Validity duration of refresh token |
| `OTP_EXPIRE_MINUTES` | `10` | Expiration window for 6-digit OTP |
| `OTP_MAX_ATTEMPTS` | `5` | Maximum failed verification attempts before lockout |
| `OTP_RESEND_COOLDOWN_SECONDS` | `30` | Minimum seconds between resend requests |
| `SMTP_HOST` | `""` | Outgoing SMTP server (empty = console mode) |
| `SMTP_PORT` | `587` | Outgoing SMTP port |
| `SMTP_USERNAME` | `""` | SMTP username |
| `SMTP_PASSWORD` | `""` | SMTP password |
| `SMTP_FROM_EMAIL` | `"noreply@padosipro.com"` | Envelope sender address |

---

## 🧪 Testing & Quality Assurance (25 Tests Passing)

The test suite validates security constraints, edge cases, and end-to-end API integration using pytest:

```bash
cd backend
source venv/bin/activate
pytest -v
```

### Test Coverage Highlights:
- **`test_otp.py` (14 unit tests)**:
  - 6-digit OTP generation and leading zero padding (`000000` to `999999`).
  - SHA-256 hash determinism and resistance to reversing.
  - Expiry calculation and expiration cutoff validation.
  - 30-second resend cooldown calculation.
  - 5-attempt brute-force limit and lockout enforcement.
  - JWT generation, payload claims, and signature tampering rejection.
- **`test_auth_integration.py` (11 integration tests)**:
  - User registration with bcrypt hashing.
  - Email OTP verification with JWT dual-token generation.
  - Rejection of unverified user login (`403` with OTP dispatch).
  - Resend OTP rate limit cooldown enforcement.
  - Refresh token rotation and single-use revocation.
  - Logout and token revocation.
  - Profile update and auto-completion status calculation.
  - Task catalogue seeding verification and active request creation.

---

## 🔄 Database Switching (PostgreSQL / SQLite)

The backend uses SQLAlchemy 2.0 Async ORM, allowing instant switching between SQLite and PostgreSQL without code changes:

### Using PostgreSQL:
1. Update `DATABASE_URL` in `.env`:
   ```env
   DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/padosipro
   ```
2. Install the asyncpg driver:
   ```bash
   pip install asyncpg
   ```
3. Run the server — tables and task catalogue will automatically initialize on startup.
