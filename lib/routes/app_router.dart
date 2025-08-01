import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/product_details_screen.dart';
import '../features/products/product_listing_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/admin/admin_dashboard.dart'; // Import for AdminDashboard
import '../shared/models/product_model.dart'; // Required for ProductModel in router
import '../shared/providers/auth_provider.dart';
import '../shared/providers/product_provider.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;
      
      // Don't redirect while loading
      if (isLoading) return null;
      
      final location = state.matchedLocation;
      
      // Allow splash and onboarding screens
      if (location == '/splash' || location == '/onboarding') {
        return null;
      }
      
      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && _isProtectedRoute(location)) {
        return '/login';
      }
      
      // Redirect to appropriate dashboard based on user role if authenticated and trying to access auth routes
      if (isAuthenticated && _isAuthRoute(location)) {
        // Check if user is admin and redirect accordingly
        if (authProvider.isAdmin) {
          return '/admin';
        } else {
          return '/home';
        }
      }
      
      return null;
    },
    routes: [
      // Splash Route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding Route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: Text('Forgot Password Screen - Coming Soon'),
          ),
        ),
      ),
      
      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const ProductListingScreen(showCategoriesOnly: true),
      ),
      
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListingScreen(),
      ),
      
      GoRoute(
        path: '/product-details',
        name: 'product-details',
        builder: (context, state) {
          final productId = state.extra as String?;
          if (productId == null) {
            return const Scaffold(
              body: Center(child: Text('Product not found')),
            );
          }
          
          return Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              return FutureBuilder<ProductModel?>(
                future: productProvider.getProductById(productId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  } else if (!snapshot.hasData || snapshot.data == null) {
                    return const Scaffold(
                      body: Center(child: Text('Product not found')),
                    );
                  }
                  
                  return ProductDetailsScreen(product: snapshot.data!);
                },
              );
            },
          );
        },
      ),
      
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Admin Routes
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      
      // Error Route
      GoRoute(
        path: '/error',
        name: 'error',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.extra?.toString() ?? 'Unknown error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.matchedLocation}" could not be found.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  static GoRouter get router => _router;

  // Helper methods
  static bool _isProtectedRoute(String location) {
    const protectedRoutes = [
      '/home',
      '/categories',
      '/products',
      '/product-details',
      '/cart',
      '/orders',
      '/profile',
      '/admin',
    ];
    
    return protectedRoutes.any((route) => location.startsWith(route));
  }

  static bool _isAuthRoute(String location) {
    const authRoutes = [
      '/login',
      '/signup',
      '/forgot-password',
    ];
    
    return authRoutes.contains(location);
  }

  // Navigation helpers
  static void goToSplash(BuildContext context) {
    context.go('/splash');
  }

  static void goToOnboarding(BuildContext context) {
    context.go('/onboarding');
  }

  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToSignUp(BuildContext context) {
    context.go('/signup');
  }

  static void goToHome(BuildContext context) {
    context.go('/home');
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToCart(BuildContext context) {
    context.go('/cart');
  }

  static void goToOrders(BuildContext context) {
    context.go('/orders');
  }

  static void goToProductDetails(BuildContext context, String productId) {
    context.go('/product-details', extra: productId);
  }

  static void goToAdmin(BuildContext context) {
    context.go('/admin');
  }

  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}
