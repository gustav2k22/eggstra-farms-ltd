# Eggstra Farms Ltd - Mobile Application

![Eggstra Farms Logo](assets/images/logo.png)

## 📱 Overview

Eggstra Farms Ltd is a premium Flutter e-commerce application for agricultural products. The app provides a seamless shopping experience for customers looking to purchase high-quality farm products while offering robust management tools for administrators.

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
Suleiman Ahmed Ibn Ahmed (http://github.com/gustav2k19)
Amos kwame asante(https://github.com/AMOSKWAMEASANTE/AMOSKWAMEASANTE.git)
Asante Amoah Emmanuel Kofi (https://github.com/Kofi-Jr7/Kofi-Jr7.git)
---

© 2025 Eggstra Farms Ltd. All rights reserved.
