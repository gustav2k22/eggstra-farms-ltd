import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Eggstra Farms',
      description: 'Ghana\'s premier farm-to-table experience. Fresh, organic, and delivered with love from our farm to your family.',
      animationAsset: 'assets/animations/farming.json',
      icon: Icons.agriculture,
      color: AppColors.primary,
      isWelcome: true,
    ),
    OnboardingPage(
      title: 'Farm Fresh Excellence',
      description: 'Our free-range chickens roam green pastures, producing the freshest eggs and finest poultry you\'ve ever tasted.',
      animationAsset: 'assets/animations/quality.json',
      icon: Icons.verified,
      color: AppColors.secondary,
      features: [
        'Free-range chickens',
        '100% organic feed',
        'No antibiotics or hormones',
        'Daily fresh collection'
      ],
    ),
    OnboardingPage(
      title: 'Swift & Reliable Delivery',
      description: 'From farm gate to your plate in record time. Our cold-chain delivery ensures maximum freshness.',
      animationAsset: 'assets/animations/delivery.json',
      icon: Icons.local_shipping,
      color: AppColors.accent,
      features: [
        'Same-day delivery available',
        'Temperature-controlled transport',
        'GPS tracking',
        'Contactless delivery options'
      ],
    ),
    OnboardingPage(
      title: 'Choose Your Journey',
      description: 'How would you like to experience Eggstra Farms today?',
      animationAsset: 'assets/animations/choice.json',
      icon: Icons.person,
      color: AppColors.primary,
      isRoleSelection: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompleted, true);
    
    // Navigate to login screen
    if (mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _pages[_currentPage].color.withValues(alpha: 26),
              _pages[_currentPage].color.withValues(alpha: 13),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    // Skip Button
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildPageIndicator(index),
                  ),
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    if (_currentPage > 0)
                      TextButton.icon(
                        onPressed: _previousPage,
                        icon: const Icon(Icons.arrow_back_ios),
                        label: const Text('Previous'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                      )
                    else
                      const SizedBox(width: 100),

                    // Next/Get Started Button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.rocket_launch
                                : Icons.arrow_forward_ios,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.isRoleSelection) {
      return _buildRoleSelectionPage(page);
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced Animation Section
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1200),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: page.isWelcome ? 280 : 250,
                    height: page.isWelcome ? 280 : 250,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          page.color.withValues(alpha: 38),
                          page.color.withValues(alpha: 13),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(page.isWelcome ? 140 : 125),
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulsing background
                          TweenAnimationBuilder(
                            duration: const Duration(seconds: 2),
                            tween: Tween<double>(begin: 0.8, end: 1.1),
                            builder: (context, double pulseValue, child) {
                              return Transform.scale(
                                scale: pulseValue,
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: page.color.withValues(alpha: 26),
                                    borderRadius: BorderRadius.circular(90),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Main animation
                          Lottie.asset(
                            page.animationAsset,
                            width: page.isWelcome ? 220 : 200,
                            height: page.isWelcome ? 220 : 200,
                            fit: BoxFit.contain,
                            repeat: true,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [page.color, page.color.withValues(alpha: 179)],
                                  ),
                                  borderRadius: BorderRadius.circular(60),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.color.withValues(alpha: 77),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  page.icon,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Enhanced Title with Animation
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    page.title,
                    style: TextStyle(
                      fontSize: page.isWelcome ? 32 : 28,
                      fontWeight: FontWeight.bold,
                      color: page.color,
                      height: 1.2,
                      letterSpacing: page.isWelcome ? 1.2 : 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Enhanced Description
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, 15 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    page.description,
                    style: TextStyle(
                      fontSize: page.isWelcome ? 18 : 16,
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontWeight: page.isWelcome ? FontWeight.w500 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Features Section with Staggered Animation
          if (page.features != null)
            _buildFeaturesSection(page),
        ],
      ),
    ),
    );
  }

  Widget _buildFeaturesSection(OnboardingPage page) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withValues(alpha: 26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: page.features!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final feature = entry.value;
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 600 + (index * 200)),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, double itemValue, child) {
                      return Transform.translate(
                        offset: Offset(20 * (1 - itemValue), 0),
                        child: Opacity(
                          opacity: itemValue,
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index < page.features!.length - 1 ? 16 : 0,
                            ),
                            child: _buildFeatureItem(
                              _getFeatureIcon(feature),
                              feature,
                              _getFeatureDescription(feature),
                              page.color,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleSelectionPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Title
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 77),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        page.title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page.description,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Role Selection Cards
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1000),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      // Customer Card
                      _buildRoleCard(
                        title: 'I\'m a Customer',
                        subtitle: 'Shop fresh farm products',
                        description: 'Browse our premium selection of eggs, poultry, and organic produce delivered fresh to your doorstep.',
                        icon: Icons.shopping_bag,
                        color: AppColors.primary,
                        gradient: [AppColors.primary, AppColors.primaryLight],
                        features: [
                          'Browse fresh products',
                          'Easy ordering & payment',
                          'Track your deliveries',
                          'Exclusive customer deals'
                        ],
                        onTap: () => _selectRole('customer'),
                      ),

                      const SizedBox(height: 24),

                      // Admin Card
                      _buildRoleCard(
                        title: 'I\'m an Admin',
                        subtitle: 'Manage farm operations',
                        description: 'Access administrative tools to manage products, orders, customers, and farm operations efficiently.',
                        icon: Icons.admin_panel_settings,
                        color: AppColors.secondary,
                        gradient: [AppColors.secondary, AppColors.accent],
                        features: [
                          'Manage products & inventory',
                          'Process orders & payments',
                          'Customer management',
                          'Analytics & reports'
                        ],
                        onTap: () => _selectRole('admin'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ))  ;
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 51), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 26),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectRole(String role) async {
    // Save selected role
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
    
    // Check if widget is still mounted before using BuildContext
    if (!mounted) return;
    
    // Show selection feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome ${role == 'admin' ? 'Admin' : 'Customer'}! Let\'s get started.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: role == 'admin' ? AppColors.secondary : AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Complete onboarding after a short delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Check if widget is still mounted before completing onboarding
    if (mounted) {
      _completeOnboarding();
    }
  }

  IconData _getFeatureIcon(String feature) {
    if (feature.toLowerCase().contains('chicken') || feature.toLowerCase().contains('range')) {
      return Icons.pets;
    } else if (feature.toLowerCase().contains('organic') || feature.toLowerCase().contains('feed')) {
      return Icons.eco;
    } else if (feature.toLowerCase().contains('delivery') || feature.toLowerCase().contains('transport')) {
      return Icons.local_shipping;
    } else if (feature.toLowerCase().contains('gps') || feature.toLowerCase().contains('track')) {
      return Icons.gps_fixed;
    } else if (feature.toLowerCase().contains('temperature') || feature.toLowerCase().contains('cold')) {
      return Icons.ac_unit;
    } else if (feature.toLowerCase().contains('contactless') || feature.toLowerCase().contains('same')) {
      return Icons.schedule;
    }
    return Icons.check_circle;
  }

  String _getFeatureDescription(String feature) {
    final descriptions = {
      'Free-range chickens': 'Happy chickens roaming freely in natural pastures',
      '100% organic feed': 'No chemicals, just pure natural nutrition',
      'No antibiotics or hormones': 'Clean, healthy poultry you can trust',
      'Daily fresh collection': 'Eggs collected fresh every morning',
      'Same-day delivery available': 'Order today, enjoy tonight',
      'Temperature-controlled transport': 'Maintaining perfect freshness',
      'GPS tracking': 'Know exactly where your order is',
      'Contactless delivery options': 'Safe and convenient delivery',
    };
    return descriptions[feature] ?? 'Premium quality guaranteed';
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _pages[_currentPage].color
            : _pages[_currentPage].color.withValues(alpha: 77),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String animationAsset;
  final IconData icon;
  final Color color;
  final List<String>? features;
  final bool isWelcome;
  final bool isRoleSelection;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.animationAsset,
    required this.icon,
    required this.color,
    this.features,
    this.isWelcome = false,
    this.isRoleSelection = false,
  });
}
