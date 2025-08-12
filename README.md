# Eggstra Farms Ltd - Mobile Application

![Eggstra Farms Logo](assets/images/logo.png)

<!-- Badges -->
<p align="left">
  <img src="https://img.shields.io/badge/Flutter-3.16%2B-blue" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.2%2B-blue" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-orange" alt="Firebase" />
  <img src="https://img.shields.io/badge/Cloudinary-Fallback%20Images-4c9ae8" alt="Cloudinary" />
  <img src="https://img.shields.io/badge/License-Private-lightgrey" alt="License" />
</p>

## 📱 Overview

Eggstra Farms Ltd is a premium Flutter e-commerce application for agricultural products. The app provides a seamless shopping experience for customers looking to purchase high-quality farm products while offering robust management tools for administrators.

### 🖼️ Screenshots

Place screenshots in `assets/readme/` and update the paths below. Example:

| Home | Product Details | Cart |
|---|---|---|
| ![Home](assets/readme/home.png) | ![Product](assets/readme/product.png) | ![Cart](assets/readme/cart.png) |

| Orders | Admin Dashboard | Order Management |
|---|---|---|
| ![Orders](assets/readme/orders.png) | ![Admin](assets/readme/admin.png) | ![OrderMgmt](assets/readme/order_mgmt.png) |

### 🌟 Key Features

- **User Authentication**: Secure login, registration, and profile management
- **Product Browsing**: Browse products by category with search and filtering
- **Shopping Cart**: Add products, manage quantities, and calculate totals
- **Checkout Process**: Multiple payment options and delivery address management
- **Order Tracking**: Real-time updates on order status and history
- **Admin Dashboard**: Comprehensive tools for product and order management

## 🏗️ Project Structure (For Non-Developers)

The app is organized into folders that represent different parts of the application:

- **`lib/core`**: Contains essential services and utilities that power the app
  - **`services`**: Handles communication with Firebase and business logic
  - **`constants`**: Stores app-wide settings like colors and text
  - **`themes`**: Controls how the app looks (colors, fonts, etc.)
  - **`utils`**: Provides helper functions used throughout the app

- **`lib/features`**: Contains different screens and functionality grouped by purpose
  - **`admin`**: Tools for administrators to manage the store
  - **`auth`**: Login and registration screens
  - **`cart`**: Shopping cart management
  - **`checkout`**: Payment and order completion
  - **`home`**: Main product browsing experience
  - **`onboarding`**: Introduction screens for first-time users
  - **`orders`**: Order history and tracking
  - **`products`**: Product details and management
  - **`profile`**: User profile management
  - **`settings`**: App configuration options
  - **`splash`**: Loading screen shown when app starts

- **`lib/shared`**: Reusable components used across multiple screens

## 🔄 How It Works (Non-Technical Explanation)

### Firebase Integration

The app uses Google's Firebase platform as its backend, which provides:

- **User Accounts**: Securely stores user credentials and profiles
- **Product Database**: Stores all product information and inventory
- **Order Processing**: Manages the lifecycle of customer orders
- **File Storage**: Stores product images and other media
- **Analytics**: Tracks app usage to improve user experience

### State Management Explained

The app uses a system called "Provider" to manage data across screens. Think of it as a central bulletin board where different parts of the app can post and read information. This ensures all screens show consistent, up-to-date information.

## 🛒 Product System

Products in the app have the following properties:

- **Basic Info**: Name, description, price, images
- **Categories**: Products are organized by type (e.g., Eggs, Vegetables)
- **Special Tags**: Organic, Featured, Discounted, etc.
- **Inventory Management**: Tracks available quantities
- **Ratings & Reviews**: Customer feedback and star ratings

## 📦 Order Processing Workflow

1. **Cart Creation**: User adds products to their shopping cart
2. **Checkout**: User provides delivery information and payment details
3. **Order Placement**: System creates an order and processes payment
4. **Status Updates**: Order progresses through various stages:
   - Pending → Processing → Shipped → Delivered (or Cancelled)
5. **Notifications**: User receives updates about their order status

## 👥 User Roles

### Customer Features
- Browse and search products
- Manage shopping cart
- Place orders and track delivery
- View order history
- Update profile and preferences

### Admin Features
- Dashboard with sales analytics and metrics
- Manage users (view, edit, activate/deactivate)
- Add, edit, and remove products
- Process and update orders
- View reports and business insights

## 💻 Technical Information (For Developers)

### Technology Stack

- **Flutter SDK**: v3.16.0
- **Dart**: v3.2.0
- **Firebase**: Authentication, Firestore, Storage, Analytics, Crashlytics

### Key Dependencies

- **Provider & Riverpod**: State management
- **GoRouter**: Navigation and routing
- **HTTP/Dio**: API communication
- **Hive & SharedPreferences**: Local storage
- **Firebase packages**: Backend integration
- **CachedNetworkImage**: Image handling
- **Lottie**: Animation effects

### Architecture

The app follows a service-oriented architecture with clear separation of concerns:

- **UI Layer**: Flutter widgets for user interface
- **State Layer**: Providers for state management
- **Service Layer**: Business logic and Firebase integration
- **Model Layer**: Data structures and entities

## 🧪 Testing

### Sample Accounts

- **Customer**: test@mail.com / password123
- **Admin**: admin@admin.com / admin123

### Sample Products

The app includes sample products across multiple categories with realistic data, including:

- Free-range organic eggs
- Fresh vegetables and fruits
- Dairy products
- Organic honey and preserves
- Farm-fresh meat

## 🤝 Contributing Guidelines (For Non-Developers)

Even if you're not a programmer, you can contribute to the project in several ways:

- **Content Creation**: Help write product descriptions or marketing materials
- **UI/UX Feedback**: Suggest improvements to the user experience
- **Testing**: Try the app and report any issues or bugs you find
- **Documentation**: Help improve these instructions or create user guides

To suggest changes:
1. Note the specific screen or feature you're referring to
2. Describe clearly what you think should be changed
3. If possible, include a screenshot highlighting the area
4. Submit your feedback through our project management system

## 📞 Contact Information

- **Development Team**:
1. Suleiman Ahmed Ibn Ahmed (http://github.com/gustav2k19)
2. Amos kwame asante(https://github.com/AMOSKWAMEASANTE/AMOSKWAMEASANTE.git)
3. Asante-Amoah Emmanuel Kofi (https://github.com/Kofi-Jr7/Kofi-Jr7.git)
4. Emmanuel Nana Agyemang (https://github.com/onlycylicon)
5. Abdul Rahim Salawudeen <https://github.com/Spacely-12>

  
© 2025 Eggstra Farms Ltd. All rights reserved.

---

## ✅ Updated 2025 Developer Guide (Comprehensive)

This section reflects the current, production-ready architecture after the migration from mock data to Firebase and the addition of Cloudinary as an image upload fallback.

### Table of Contents
- [Overview](#overview-2025)
- [Quick Start](#quick-start)
- [Environment & Configuration](#environment--configuration)
- [Firebase Setup](#firebase-setup)
- [Cloudinary Setup (Fallback Image Upload)](#cloudinary-setup-fallback-image-upload)
- [Running the App](#running-the-app)
- [Architecture](#architecture-2025)
- [Data Flow](#data-flow)
- [Key Features (Technical)](#key-features-technical)
- [Project Structure](#project-structure-2025)
- [Error Handling & Troubleshooting](#error-handling--troubleshooting)
- [Quality: Linting & Formatting](#quality-linting--formatting)
- [Security Notes](#security-notes)
- [Contributing](#contributing-2025)

### Overview (2025)
- Firebase is the single source of truth for all data (products, orders, reviews, users, activities).
- Firestore index errors are avoided by using client-side filtering/sorting where needed.
- Image uploads use Firebase Storage primarily, with Cloudinary as a robust fallback.
- State management uses `provider` with properly registered providers in `lib/main.dart`.
- Admin Order Management Screen has a modern UI with analytics, filters, and real-time updates.

### Quick Start
1) Prerequisites
   - Flutter SDK (3.16+ recommended)
   - Dart SDK (3.2+)
   - Android Studio/Xcode (for platforms you target)
   - Firebase project (Firestore, Authentication, Storage enabled)
   - Optional: Cloudinary account (for fallback uploads)

2) Clone & Install
```bash
git clone https://github.com/gustav2k22/eggstra-farms-ltd.git
cd eggstra-farms-ltd
flutter pub get
```

3) Configure Firebase (see next section) and ensure files are in the correct platform folders.

4) Optional: provide Cloudinary config via `--dart-define` (recommended)
```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud \
  --dart-define=CLOUDINARY_API_KEY=your_key \
  --dart-define=CLOUDINARY_API_SECRET=your_secret \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=eggstra \
  --dart-define=CLOUDINARY_UNSIGNED=true
```

5) Run
```bash
flutter run
```

### Environment & Configuration
The app reads Firebase configuration from the standard platform config files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Cloudinary configuration is currently defined in `lib/core/services/cloudinary_service.dart`.
- Fields: `cloudName`, `apiKey`, `apiSecret`, `upload_preset` (currently `'eggstra'`).
- For production, consider moving these to a secure config mechanism.

### Firebase Setup
1) Create a Firebase project and enable:
   - Authentication (Email/Password)
   - Firestore
   - Storage
   - (Optional) Analytics/Crashlytics

2) Add apps (Android/iOS/web) in the Firebase console and download config files:
   - Android: place `google-services.json` at `android/app/`
   - iOS: place `GoogleService-Info.plist` at `ios/Runner/`

3) Initialize FlutterFire (optional but recommended):
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4) Firestore Rules (example starting point; harden for production):
```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Cloudinary Setup (Fallback Image Upload)
1) Create a Cloudinary account and get:
   - Cloud name
   - API Key
   - API Secret

2) Create an unsigned upload preset named `eggstra` (or update the code to your preset).

3) In `lib/core/services/cloudinary_service.dart` ensure these are correct:
   - `cloudName`, `apiKey`, `apiSecret`, `_uploadUrl`, and `upload_preset`.
   - Signature generation now uses proper SHA1 via `package:crypto`.

### Running the App
```bash
flutter clean
flutter pub get
flutter run
```

Common run targets:
- Android emulator/physical device
- iOS simulator/device

### Architecture (2025)
- UI: Widgets in `lib/features/**` and shared widgets in `lib/shared/widgets/`.
- State: `provider`-based; `MultiProvider` registration in `lib/main.dart`.
- Services: Encapsulated Firebase/Cloudinary logic in `lib/core/services/`.
- Models: POJOs and mapping in `lib/core/models/`.

### Data Flow
- Read: Services expose streams or futures (e.g., `OrderService.getUserOrders()` returns user orders with client-side filtering to avoid composite indexes).
- Write: Services validate and write to Firestore/Storage, with activity logging where applicable.
- Images: Upload to Firebase Storage; on failure, fallback to Cloudinary; on failure again, fallback to local storage (graceful degradation).

### Key Features (Technical)
- Client-side filtering instead of Firestore composite indexes for queries combining `where + orderBy` to avoid index issues.
- Admin Order Management: real-time stream, statistics, search/filter, polished UI.
- Product reviews: Firebase-backed with rating aggregation.
- Activity tracking for admin dashboard.

### Project Structure (2025)
```
lib/
  core/
    models/
    services/
    utils/
    constants/
    themes/
  features/
    admin/
    auth/
    cart/
    checkout/
    home/
    onboarding/
    orders/
    products/
    profile/
    settings/
    splash/
  shared/
    widgets/
```

### Error Handling & Troubleshooting
- __StorageException: object-not-found__
  - Ensure Firebase Storage rules allow the operation and the path exists.
  - Verify the file path/key and that uploads are not canceled prematurely.

- __Cloudinary 401 Invalid Signature__
  - Fixed in code: signatures now use SHA1 with `package:crypto` and include `upload_preset` in the signature string.
  - Verify `upload_preset` exists and matches, API key/secret are correct.

- __Missing google_app_id (Analytics disabled)__
  - Ensure `google-services.json` / `GoogleService-Info.plist` are present at the correct locations.
  - Re-run `flutter clean && flutter pub get`.

- __ProviderNotFoundException__
  - Confirm providers are registered in `lib/main.dart` within `MultiProvider`.

- __Firestore index errors__
  - Handled by moving filtering/sorting to client-side for affected queries (no paid indexes required).

### Quality: Linting & Formatting
- Run analyzer: `flutter analyze`
- Fix common issues (unused imports, deprecated APIs). Some remaining warnings may be informational.
- Optional: add `melos` or custom scripts for CI.

### Security Notes
- Do not commit real secrets. Use environment configs or secure storage.
- The constant `defaultAdminKey` is preserved in the codebase where required. Restrict its usage and rotate if needed.
- Harden Firebase rules before production launch.

### Contributing (2025)
1) Create a feature branch.
2) Keep changes small and focused.
3) Run `flutter analyze` and ensure no new warnings.
4) Open a PR with a clear description, screenshots (if UI), and testing notes.

---

If you get stuck or want help setting up Firebase/Cloudinary, open an issue or reach out to the maintainers listed above.
