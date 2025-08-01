class AppConstants {
  // App Info
  static const String appName = 'Eggstra Farms Ltd';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Premium Agricultural Products Mobile App';
  
  // Company Info
  static const String companyName = 'Eggstra Farms Ltd';
  static const String companyWebsite = 'https://eggstrafarmsghana.com';
  static const String companyEmail = 'info@eggstrafarmsghana.com';
  static const String companyPhone = '+233 123 456 789';
  static const String companyAddress = 'Accra, Ghana';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String cartCollection = 'cart';
  static const String reviewsCollection = 'reviews';
  
  // Storage Paths
  static const String productImagesPath = 'products/images';
  static const String userAvatarsPath = 'users/avatars';
  static const String categoryImagesPath = 'categories/images';
  
  // User Roles
  static const String adminRole = 'admin';
  static const String customerRole = 'customer';
  
  // Order Status
  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderProcessing = 'processing';
  static const String orderShipped = 'shipped';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';
  
  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';
  
  // Product Categories
  static const List<String> productCategories = [
    'Eggs',
    'Poultry',
    'Dairy',
    'Vegetables',
    'Fruits',
    'Grains',
    'Organic',
    'Fresh Produce',
  ];
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Image Constraints
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1080;
  
  // Validation
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxReviewLength = 1000;
  
  // Currency
  static const String defaultCurrency = 'GHS';
  static const String currencySymbol = '₵';
  
  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred. Please try again.';
  static const String authError = 'Authentication error. Please login again.';
  static const String permissionError = 'Permission denied. Please contact support.';
  
  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registerSuccess = 'Registration successful!';
  static const String logoutSuccess = 'Logout successful!';
  static const String profileUpdateSuccess = 'Profile updated successfully!';
  static const String orderPlacedSuccess = 'Order placed successfully!';
  static const String cartUpdateSuccess = 'Cart updated successfully!';
  
  // Shared Preferences Keys
  static const String isFirstLaunchKey = 'isFirstLaunch';
  static const String userTokenKey = 'userToken';
  static const String userDataKey = 'user_data';
  static const String cartDataKey = 'cart_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  static const String onboardingCompleted = 'onboarding_completed';
}
