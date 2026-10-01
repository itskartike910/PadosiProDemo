# PadosiPro Mobile App 📱

> **Native Android Mobile Application for PadosiPro — Lifestyle Management Platform.**  
> Built with **Flutter 3.x · Dart 3.x · Riverpod 2.x · GoRouter 14.x · Dio 5.x · Flutter Secure Storage**.

---

## 📋 Table of Contents

- [Overview & Experience](#-overview--experience)
- [Design System & Aesthetics](#-design-system--aesthetics)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Folder Structure](#-folder-structure)
- [User Journey & App Screens](#-user-journey--app-screens)
- [State Management & Navigation](#-state-management--navigation)
- [Networking & Communication Scenarios](#-networking--communication-scenarios)
- [Testing & Code Quality](#-testing--code-quality)
- [Building for Production (APK)](#-building-for-production-apk)

---

## 🌟 Overview & Experience

The **PadosiPro** mobile application connects households with a dedicated personal **Lifestyle Manager**. Whether handling daily errands, home repairs, senior companionship, or staff recruitment, PadosiPro delivers a high-touch lifestyle management experience directly natively on Android.

### Key Highlights

- **Refined Light-Mode Aesthetic**: Pristine light theme (`#F8FAF9`) inspired by *Classy Professional Service*, featuring clean white cards, subtle borders, and deep pine teal (`#1E5E52`).
- **Interactive Morphing OTP Screen**: 6 boxes morph into a symmetrical hexagon upon typing the 6th digit, featuring glowing clockwise-rotating neon perimeter edges and a 30s resend timer.
- **Pinned Top Navigation**: Always-visible location selector (with society and address details bottom sheet) and a profile avatar with a dropdown menu for **Profile** and **Logout**.
- **15 Real Categories with Subtitles**: Category cards displaying icons, titles, and text-based descriptions directly from `backend/src/seed.py`.
- **Streamlined 3-Step Request Flow**: Service selection ➔ Urgency level (Standard, Same Day, Express, Scheduled) ➔ Contextual notes.
- **Active Request Tracker**: Live card on the dashboard showing assigned task status and modal details.

---

## 🎨 Design System & Aesthetics

### Color Palette (Light Mode)

| Token | Hex Value | Purpose |
|---|---|---|
| `AppColors.primary` | `#1E5E52` | Brand Pine Teal — primary buttons, icons, active highlights |
| `AppColors.primaryDark` | `#123D35` | Deep teal for active button gradients and borders |
| `AppColors.secondary` | `#00B4CC` | Electric Cyan — status badges, trust pills |
| `AppColors.accent` | `#FF8C42` | Vivid Orange — urgency chips, category accents |
| `AppColors.accentGold` | `#FFD700` | Electric Gold — star ratings, featured tasks |
| `AppColors.accentGreen` | `#05CC78` | Neon Mint — success states, verified badges |
| `AppColors.accentPurple` | `#8B5CF6` | Electric Violet — errand badges, gradient accents |
| `AppColors.background` | `#F8FAF9` | Pristine light background |
| `AppColors.surface` | `#FFFFFF` | Pure white cards and sheets |
| `AppColors.divider` | `#E2ECE8` | Subtle border lines |
| `AppColors.textHeading` | `#102A24` | Deep pine dark for high-contrast titles |
| `AppColors.textSecondary` | `#5A756E` | Muted teal-slate for subtitles and captions |

### Typography

Loaded cleanly via `google_fonts`:
- **Headings & Titles**: `GoogleFonts.sora()` — Modern, friendly geometric typography with bold character.
- **Body & Controls**: `GoogleFonts.outfit()` — Highly legible sans-serif optimized for mobile data density.

### Signature UI Components

- **`SwipeConfirmButton` / `PrimaryButton`**: Pill-shaped action button with arrow icon, auto-slide animation on tap, and inline circular progress spinner during network requests.
- **`AppTextField`**: Reusable text input with prefix/suffix icons, subtle border states, and inline error styling.
- **`_FeaturePill`**: Trust pills for verified pros, safety, and support.

---

## 🏗️ Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────────┐
│                       Flutter UI Layer                      │
│     (Pages · Shared Widgets · Custom Themes · Animations)   │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                    State Management (Riverpod 2)             │
│        (authProvider · apiClientProvider · tokenStorage)    │
└──────────────┬───────────────────────────────┬──────────────┘
               │                               │
┌──────────────▼──────────────┐ ┌──────────────▼──────────────┐
│   Navigation (GoRouter 14)  │ │      Networking (Dio 5)      │
│  (Auth Guard · Dynamic Flow)│ │  (JWT Interceptor · Refresh)│
└─────────────────────────────┘ └──────────────┬──────────────┘
                                               │
                                ┌──────────────▼──────────────┐
                                │    FlutterSecureStorage     │
                                │  (Hardware Keystore AES-256)│
                                └─────────────────────────────┘
```

| Layer | Dependency | Description |
|---|---|---|
| **Framework** | Flutter 3.x / Dart 3.x | High-performance compiled native mobile app |
| **State Management** | `flutter_riverpod: ^2.6.1` | Declarative, compile-time safe dependency injection |
| **Navigation** | `go_router: ^14.8.1` | Declarative routing with auth state redirect guards |
| **Networking** | `dio: ^5.8.0` | HTTP client with automatic JWT injection & 401 retry interceptor |
| **Secure Storage** | `flutter_secure_storage: ^9.2.4` | Keystore-backed storage for access and refresh tokens |
| **Typography** | `google_fonts: ^6.2.1` | Sora and Outfit font families |

---

## 📂 Folder Structure

```
mobile/
├── android/                   # Native Android configuration, Gradle files & app icons
├── assets/                    # Static assets & icons (ppro.png)
├── lib/
│   ├── core/
│   │   ├── constants/         # AppColors, AppSizes, AppStrings
│   │   ├── networking/        # ApiClient (Dio), TokenStorage, Interceptors
│   │   ├── routing/           # AppRouter, route definitions & auth guards
│   │   └── theme/             # AppTheme (Light mode, Sora + Outfit typography)
│   ├── features/
│   │   ├── auth/              # Login, Register, OTP verification & AuthProvider
│   │   ├── home/              # Dashboard, Category carousels, Popular tasks, Concierge
│   │   ├── profile/           # Profile details & First-login ProfileSetupPage
│   │   └── tasks/             # TaskSelectionPage, RequestTimingPage, RequestNotesPage
│   ├── shared/
│   │   └── widgets/           # PrimaryButton, SwipeConfirmButton, AppTextField, AppLogo
│   └── main.dart              # App entry point with ProviderScope
├── test/
│   └── widget_test.dart       # Widget and smoke tests
└── pubspec.yaml
```

---

## 🌐 Networking & Communication Scenarios

The mobile client accepts a configurable backend URL using `--dart-define=API_BASE_URL=...`. Choose the configuration matching your environment:

### Scenario 1: Physical Android Device via USB (`adb reverse` - Recommended)
This method tunnels all network traffic through the USB cable, eliminating any Wi-Fi or firewall issues:

```bash
# 1. Reverse port 8000:
adb reverse tcp:8000 tcp:8000

# 2. Run Flutter app:
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

### Scenario 2: Android Emulator
Use the standard Android emulator host loopback address:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

### Scenario 3: Physical Device over Local Wi-Fi (LAN)
Find your development machine's local IP (e.g. `10.193.75.20` or `192.168.1.100`):

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:8000/api/v1
```

---

## 🧪 Testing & Code Quality

Verify that the codebase is completely clean with zero analyzer warnings:

```bash
# Static analysis:
flutter analyze
# Output: No issues found!

# Run widget tests:
flutter test
# Output: All tests passed!
```

---

## 📦 Building for Production (APK)

A pre-built release APK is available directly at:
- [`apk/padosipro-release.apk`](../apk/padosipro-release.apk) (52 MB)
- `mobile/build/app/outputs/flutter-apk/app-release.apk`

To build a fresh production APK with your custom API URL:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:8000/api/v1
```

To install directly to a connected device:

```bash
adb install apk/padosipro-release.apk
```
