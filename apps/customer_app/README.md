# Project Phoenix - Customer Mobile Application (Flutter)

Welcome to the Customer Mobile Application codebase for **Project Phoenix**, an enterprise-grade Field Service Management platform. 

This mobile application is built using a **Feature-First Clean Architecture** standard to ensure code is modular, decoupled, testable, and robust.

---

## Technical Stack & Packages

- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod) for high-performance reactive binding and DI.
- **Routing**: [go_router](https://pub.dev/packages/go_router) for declarative state-driven routing.
- **Local Database**: [sqflite](https://pub.dev/packages/sqflite) with custom helper for offline-first indexing and sync queue management.
- **Networking**: [dio](https://pub.dev/packages/dio) wrapper configured with automatic authorization JWT injection and 401 refresh token retry interceptors.
- **Localization**: English (EN) & Tamil (TA) localized translation catalog.
- **Accessibility**: Includes dedicated Senior Citizen Mode (enlarges text scale, increases touch sizes, simplifies layout parameters) and High Contrast Mode.

---

## Directory Structure

```
lib/
├── core/
│   ├── theme/          # UI Theme definitions, color schemes & settings notifier
│   ├── localization/   # Localizations delegate for English & Tamil translations
│   ├── routing/        # App routing configuration
│   ├── network/        # API Client client wrapper (Dio) with JWT refresh
│   └── database/       # SQLite db helper for caching and sync queue
├── features/
│   ├── auth/           # Login selection, Email/Password, OTP & forgot password forms
│   ├── home/           # Dashboard (Banners, search catalog, emergency toggles, grid)
│   ├── services/       # Catalog by categories, item detail, search query filters
│   ├── booking/        # Stepper wizard (Property, schedule slot, desc, voice transcription, summary)
│   ├── emergency/      # RED high-priority layout, quick dispatch allocation
│   ├── tracking/       # Live technician ETA progress steps and communications
│   ├── store/          # Product grid catalog, shopping cart notifier, checkout
│   ├── profile/        # Properties list, invoices billing, warranty cards, bookings history
│   └── help_ai/        # AI bot simulation chatbot, WhatsApp support, FAQ entries
└── main.dart
```

---

## Getting Started

1. Ensure you have Flutter SDK `>=3.10.0` installed.
2. Get packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```
4. Run unit tests:
   ```bash
   flutter test
   ```
