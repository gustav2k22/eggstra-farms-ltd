# Eggstra Farms Ltd - Mobile Application

![Eggstra Farms Logo](assets/images/logo.png)

<!-- Badges -->
<p align="left">
  <img src="https://img.shields.io/badge/Flutter-3.8%2B-blue" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.2%2B-blue" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-orange" alt="Firebase" />
  <img src="https://img.shields.io/badge/Cloudinary-Image%20Upload-4c9ae8" alt="Cloudinary" />
  <img src="https://img.shields.io/badge/Provider-State%20Management-green" alt="Provider" />
  <img src="https://img.shields.io/badge/License-Private-lightgrey" alt="License" />
</p>

## 📚 Table of Contents

- [Overview](#-overview)
- [App Report (Current Implementation Status)](#-app-report-current-implementation-status)
- [Key Features](#-key-features)
- [Screenshots](#-screenshots)
- [Architecture & Technology Stack](#-architecture--technology-stack)
- [Project Structure](#-project-structure)
- [Setup & Installation](#-setup--installation)
- [Firebase Configuration](#-firebase-configuration)
- [Cloudinary Setup](#-cloudinary-setup)
- [User Roles & Permissions](#-user-roles--permissions)
- [Core Features Deep Dive](#-core-features-deep-dive)
- [Testing & Sample Data](#-testing--sample-data)
- [Known Issues & Roadmap](#-known-issues--roadmap)
- [Contributing](#-contributing)
- [Contributors](#-contributors)

## 📱 Overview

Eggstra Farms Ltd is a comprehensive Flutter e-commerce mobile application designed for premium agricultural products. The app delivers a seamless shopping experience for customers while providing powerful administrative tools for farm management. Built with Firebase backend integration and modern Flutter architecture, it supports real-time data synchronization, secure authentication, and robust image management through Cloudinary integration.

## 📊 App Report (Current Implementation Status)

This section provides a detailed overview of the current implementation status, recent fixes, and system capabilities.

### ✅ **Completed Core Features**

#### **Authentication System**
- **Secure Login/Registration**: Email/password authentication with Firebase Auth
- **Role-based Access Control**: Customer and Admin roles with proper permission handling
- **Session Management**: Fixed login redirection bug by implementing proper auth state waiting
- **Admin Key Verification**: Secure admin account creation with verification system
- **Profile Management**: Complete user profile editing with image upload support

#### **Product Management System**
- **Full CRUD Operations**: Create, read, update, delete products with Firebase Firestore
- **Image Upload Pipeline**: Dual-system with Firebase Storage primary and Cloudinary fallback
- **Category Management**: Organized product categorization (Eggs, Poultry, Dairy, Vegetables, etc.)
- **Inventory Tracking**: Real-time stock quantity management
- **Product Features**: Organic labeling, featured products, discount pricing
- **Search & Filtering**: Advanced product search with category and price filters

#### **Enhanced Product Details**
- **Modern UI/UX**: Hero animations, pinch-to-zoom gallery, animated sections
- **Interactive Elements**: Expandable nutrition facts, related products carousel
- **Smart Pricing Display**: Shows both unit and total prices with discount calculations
- **Review System**: Customer reviews with rating aggregation (Firebase-backed)

#### **Shopping Cart & Checkout**
- **Cart Management**: Add/remove items, quantity adjustments, price calculations
- **Multiple Payment Methods**: Mobile Money (MTN, Vodafone, AirtelTigo), Cards, Bank Transfer, Cash on Delivery
- **Delivery Management**: Address collection, delivery time selection
- **Order Processing**: Complete order lifecycle from cart to delivery

#### **Admin Dashboard**
- **Real-time Analytics**: User count, product inventory, order statistics, revenue tracking
- **Order Management**: View, update, and track all orders with status management
- **User Management**: View and manage customer accounts, admin key management
- **Product Management**: Add/edit products with image upload and category management
- **Activity Logging**: Track admin actions and system activities

#### **Image Management System**
- **Cloudinary Integration**: Professional image upload, transformation, and delivery
- **Migration Utility**: Convert legacy local file paths to Cloudinary URLs
- **Fallback System**: Graceful degradation from Firebase Storage → Cloudinary → Local
- **Web/Mobile Compatibility**: Cross-platform image upload support

### 🔧 **Recent Bug Fixes & Improvements**
- **Authentication Flow**: Fixed dashboard redirection after login with proper auth state management
- **Product Creation**: Resolved Firebase persistence issues in admin product management
- **Image Display**: Fixed product and profile image rendering with Cloudinary URLs
- **UI Polish**: Eliminated duplicate product information display in details screen
- **Layout Fixes**: Resolved RenderFlex overflow issues in product details and bottom bar

### 🎯 **Current System Capabilities**
- **Real-time Data**: All product, order, and user data syncs in real-time via Firebase streams
- **Offline Support**: Local caching with SharedPreferences and Hive for offline functionality
- **Cross-platform**: Supports Android, iOS, and Web platforms
- **Scalable Architecture**: Provider-based state management with service-oriented backend
- **Security**: Firebase Security Rules, input validation, and secure image upload

## 🌟 Key Features

### **Customer Features**
- 🛍️ **Product Browsing**: Browse products by category with advanced search and filtering
- 🛒 **Shopping Cart**: Intuitive cart management with quantity controls and price calculations
- 💳 **Multiple Payment Options**: Mobile Money, Credit/Debit Cards, Bank Transfer, Cash on Delivery
- 📦 **Order Tracking**: Real-time order status updates from placement to delivery
- ⭐ **Reviews & Ratings**: Leave product reviews and view community ratings
- 👤 **Profile Management**: Update personal information and delivery addresses
- 🔍 **Advanced Search**: Search products by name, category, or features (organic, featured)

### **Admin Features**
- 📊 **Analytics Dashboard**: Real-time business metrics and performance indicators
- 👥 **User Management**: View and manage customer accounts and admin access
- 📦 **Product Management**: Complete product lifecycle management with image upload
- 🛍️ **Order Management**: Process orders, update status, and track deliveries
- 🖼️ **Image Migration**: Utility to migrate legacy images to Cloudinary
- 📈 **Activity Monitoring**: Track system activities and admin actions
- 🔑 **Admin Key Management**: Secure admin account creation and management

## 🖼️ Screenshots

*Screenshots will be added to showcase the app's modern UI and key features across different screens.*

| Customer App | Admin Dashboard |
|---|---|
| Home Screen with Product Categories | Analytics Dashboard |
| Product Details with Zoom Gallery | Order Management Interface |
| Shopping Cart & Checkout | Product Management Screen |

## 🏗️ Architecture & Technology Stack

### **Frontend Architecture**
- **Framework**: Flutter 3.8+ with Dart 3.2+
- **State Management**: Provider pattern with ChangeNotifier
- **Navigation**: GoRouter for declarative routing
- **UI Components**: Custom widgets with Material Design 3
- **Animations**: Built-in Flutter animations with Lottie support

### **Backend & Services**
- **Database**: Firebase Firestore (NoSQL document database)
- **Authentication**: Firebase Auth with email/password
- **File Storage**: Firebase Storage + Cloudinary fallback
- **Analytics**: Firebase Analytics & Crashlytics
- **Real-time Updates**: Firestore streams for live data sync

### **Key Dependencies**
```yaml
# Core Framework
flutter: sdk
provider: ^6.1.2          # State management
go_router: ^14.2.7        # Navigation

# Firebase Integration
firebase_core: ^2.32.0
firebase_auth: ^4.20.0
cloud_firestore: ^4.17.5
firebase_storage: ^11.7.7

# UI & Media
cached_network_image: ^3.3.1
photo_view: ^0.15.0       # Image zoom gallery
lottie: ^3.1.2           # Animations
shimmer: ^3.0.0          # Loading states

# Local Storage
shared_preferences: ^2.2.3
hive: ^2.2.3
path_provider: ^2.1.3

# Networking & Utils
http: ^1.2.2
dio: ^5.4.3+1
image_picker: ^1.1.2
```

## 📁 Project Structure

```
eggstra-farms-ltd/
├── lib/
│   ├── core/                    # Core application logic
│   │   ├── constants/           # App constants and colors
│   │   ├── models/             # Data models (shared)
│   │   ├── services/           # Business logic services
│   │   │   ├── firebase_service.dart
│   │   │   ├── cloudinary_service.dart
│   │   │   ├── product_service.dart
│   │   │   ├── order_service.dart
│   │   │   ├── payment_service.dart
│   │   │   └── image_migration_service.dart
│   │   ├── themes/             # App theming
│   │   └── utils/              # Utility functions
│   │
│   ├── features/               # Feature-based organization
│   │   ├── admin/              # Admin dashboard & management
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── user_management_screen.dart
│   │   │   ├── product_management_screen.dart
│   │   │   ├── order_management_screen.dart
│   │   │   └── image_migration_screen.dart
│   │   ├── auth/               # Authentication
│   │   │   ├── login_screen.dart
│   │   │   └── signup_screen.dart
│   │   ├── cart/               # Shopping cart
│   │   ├── checkout/           # Payment & checkout
│   │   ├── home/               # Customer home
│   │   ├── orders/             # Order tracking
│   │   ├── products/           # Product browsing & details
│   │   ├── profile/            # User profile
│   │   ├── settings/           # App settings
│   │   └── splash/             # App initialization
│   │
│   ├── shared/                 # Shared components
│   │   ├── models/             # Data models
│   │   ├── providers/          # State providers
│   │   ├── services/           # Shared services
│   │   └── widgets/            # Reusable UI components
│   │
│   ├── routes/                 # Navigation configuration
│   └── main.dart              # App entry point
│
├── assets/                     # Static assets
│   ├── images/                # App images & logo
│   ├── icons/                 # Custom icons
│   ├── animations/            # Lottie animations
│   └── fonts/                 # Custom fonts
│
├── android/                   # Android platform code
├── ios/                       # iOS platform code
├── web/                       # Web platform code
└── pubspec.yaml              # Dependencies & configuration
```

## 🚀 Setup & Installation

### **Prerequisites**
- Flutter SDK 3.8 or higher
- Dart SDK 3.2 or higher
- Android Studio / VS Code with Flutter extensions
- Firebase project with enabled services
- Git for version control

### **Installation Steps**

1. **Clone the Repository**
```bash
git clone https://github.com/gustav2k22/eggstra-farms-ltd.git
cd eggstra-farms-ltd
```

2. **Install Dependencies**
```bash
flutter pub get
```

3. **Configure Firebase** (see Firebase Configuration section)

4. **Configure Cloudinary** (see Cloudinary Setup section)

5. **Run the Application**
```bash
flutter run
```

## 🔥 Firebase Configuration

### **1. Create Firebase Project**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable the following services:
   - **Authentication** (Email/Password provider)
   - **Firestore Database**
   - **Storage**
   - **Analytics** (optional)
   - **Crashlytics** (optional)

### **2. Add Platform Apps**

**For Android:**
1. Add Android app in Firebase console
2. Download `google-services.json`
3. Place it in `android/app/` directory

**For iOS:**
1. Add iOS app in Firebase console
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory

### **3. Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products are readable by all authenticated users
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Orders are readable by owner and admins
    match /orders/{orderId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
    }
  }
}
```

## ☁️ Cloudinary Setup

### **1. Create Cloudinary Account**
1. Sign up at [Cloudinary](https://cloudinary.com/)
2. Get your credentials:
   - Cloud Name
   - API Key
   - API Secret

### **2. Create Upload Preset**
1. Go to Settings → Upload presets
2. Create unsigned preset named `eggstra`
3. Configure allowed formats: jpg, png, webp

### **3. Configure in App**
Update `lib/core/services/cloudinary_service.dart`:
```dart
class CloudinaryService {
  static const String cloudName = 'your_cloud_name';
  static const String apiKey = 'your_api_key';
  static const String apiSecret = 'your_api_secret';
  static const String uploadPreset = 'eggstra';
}
```

## 👥 User Roles & Permissions

### **Customer Role**
- Browse and search products
- Manage shopping cart
- Place and track orders
- Leave product reviews
- Update profile information
- View order history

### **Admin Role**
- Access admin dashboard
- Manage all users
- Add/edit/delete products
- Process and update orders
- View analytics and reports
- Manage admin keys
- Access image migration tools

### **Role-based Navigation**
The app automatically redirects users based on their role:
- **Customers** → Home screen with product browsing
- **Admins** → Admin dashboard with management tools

## 🔧 Core Features Deep Dive

### **Authentication System**
- **Secure Registration**: Email validation, password strength requirements
- **Login with Remember Me**: Persistent sessions with secure token storage
- **Admin Key Verification**: Special verification process for admin accounts
- **Profile Management**: Update personal information and profile pictures

### **Product Management**
- **Rich Product Data**: Name, description, price, images, categories, nutrition info
- **Image Upload**: Multi-image support with automatic optimization
- **Inventory Tracking**: Real-time stock quantity management
- **Category Organization**: Structured product categorization
- **Search & Filtering**: Advanced search with multiple filter options

### **Shopping Experience**
- **Interactive Product Details**: Zoom gallery, expandable sections, related products
- **Smart Cart Management**: Quantity controls, price calculations, persistent storage
- **Multiple Payment Methods**: Mobile Money, Cards, Bank Transfer, Cash on Delivery
- **Order Tracking**: Real-time status updates from placement to delivery

### **Admin Dashboard**
- **Real-time Analytics**: Live metrics for users, products, orders, and revenue
- **Order Management**: Process orders, update status, track deliveries
- **User Management**: View customer accounts, manage admin access
- **Product Management**: Full CRUD operations with image upload
- **Activity Monitoring**: Track all admin actions and system activities

## 🧪 Testing & Sample Data

### **Test Accounts**
```
Customer Account:
Email: customer@test.com
Password: password123

Admin Account:
Email: admin@eggstra.com
Password: admin123
Admin Key: EGGSTRA_ADMIN_2024
```

### **Sample Product Categories**
- **Eggs**: Free-range, Organic, Brown, White
- **Poultry**: Chicken, Duck, Turkey
- **Dairy**: Milk, Cheese, Yogurt, Butter
- **Vegetables**: Tomatoes, Onions, Peppers, Leafy Greens
- **Fruits**: Seasonal fruits and berries
- **Grains**: Rice, Wheat, Corn, Oats

## 🐛 Known Issues & Roadmap

### **Current Known Issues**
- **Firestore Composite Index**: Some complex queries may require manual index creation
- **Image Migration**: Legacy products may still reference local file paths
- **Offline Mode**: Limited offline functionality for order placement

### **Upcoming Features**
- **Push Notifications**: Order status updates and promotional notifications
- **Advanced Analytics**: Detailed sales reports and customer insights
- **Multi-language Support**: Localization for local languages
- **Payment Integration**: Direct integration with mobile money APIs
- **Delivery Tracking**: GPS-based real-time delivery tracking

## 🤝 Contributing

### **Development Workflow**
1. **Fork the Repository**
2. **Create Feature Branch**: `git checkout -b feature/your-feature-name`
3. **Make Changes**: Follow coding standards and add tests
4. **Run Tests**: `flutter test` and `flutter analyze`
5. **Submit Pull Request**: With clear description and screenshots

### **Code Standards**
- Follow Dart/Flutter style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Ensure null safety compliance
- Run `flutter analyze` before committing

### **Bug Reports**
When reporting bugs, include:
- Device information and OS version
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots or error logs
- App version and build number

## 👨‍💻 Contributors

### **Development Team**
1. **Suleiman Ahmed Ibn Ahmed**
   - GitHub: [@gustav2k19](https://github.com/gustav2k19)

2. **Amos Kwame Asante**
   - GitHub: [@AMOSKWAMEASANTE](https://github.com/AMOSKWAMEASANTE/AMOSKWAMEASANTE.git)

3. **Asante-Amoah Emmanuel Kofi**
   - GitHub: [@Kofi-Jr7](https://github.com/Kofi-Jr7/Kofi-Jr7.git)

4. **Emmanuel Nana Agyemang**
   - GitHub: [@onlycylicon](https://github.com/onlycylicon)

5. **Abdul Rahim Salawudeen**
   - GitHub: [@Spacely-12](https://github.com/Spacely-12)

---

## 📄 License & Copyright

© 2025 Eggstra Farms Ltd. All rights reserved.

---
