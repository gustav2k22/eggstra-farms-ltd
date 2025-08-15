import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/models/product_model.dart';

import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/search_bar_widget.dart';
import '../../shared/widgets/enhanced_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Eggs',
    'Poultry',
    'Organic',
    'Fresh',
    'Dairy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    // Ensure products are loaded from Firebase when HomeScreen starts
    // This wires up the product streams in ProductProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.initializeProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  // Get filtered products from Firebase based on search query and category
  List<ProductModel> _getFilteredProducts(List<ProductModel> products) {
    List<ProductModel> filteredProducts = List.from(products);

    // Filter by category if not 'All'
    if (_selectedCategory != 'All') {
      filteredProducts = filteredProducts.where((product) =>
        product.category == _selectedCategory
      ).toList();
    }
    
    // Filter by search query if not empty
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filteredProducts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: AppConstants.appName,
        showCart: true,
        onCartPressed: () {
          context.go('/cart');
        },
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh products by triggering a rebuild
              setState(() {});
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
            // Welcome Section
            SliverToBoxAdapter(
              child: _buildWelcomeSection(),
            ),
            
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchBarWidget(
                  onChanged: _onSearchChanged,
                  hint: 'Search fresh products...',
                ),
              ),
            ),
            
            // Categories
            SliverToBoxAdapter(
              child: _buildCategoriesSection(),
            ),
            
            // Featured Products Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Featured Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/products');
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Products Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Get products filtered by search query and category
                    final filteredProducts = _getFilteredProducts(productProvider.products);
                    if (index >= filteredProducts.length) return null;
                    
                    final product = filteredProducts[index];
                    
                    return ProductCard(
                      productId: product.id,
                      name: product.name,
                      price: product.price,
                      imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                      category: product.category,
                      rating: product.rating,
                      isOrganic: product.isOrganic,
                      onTap: () {
                        // Use GoRouter instead of Navigator for consistent navigation
                        context.push(
                          '/product-details',
                          extra: product.id,
                        );
                      },
                    );
                  },
                  childCount: _getFilteredProducts(productProvider.products).length, // Dynamic count based on filters
                ),
              ),
            ),
            
            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 150),
            ),
          ],
            )
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.keyboard_arrow_up,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildWelcomeSection() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final String? initials = (user != null && user.firstName.isNotEmpty)
            ? (user.lastName.isNotEmpty
                ? '${user.firstName[0]}${user.lastName[0]}'
                : user.firstName[0])
            : null;
        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryLight,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 77),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${user?.firstName ?? 'Guest'}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Fresh farm products delivered to your door',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ProfileImage(
                    imageUrl: user?.profileImageUrl,
                    size: 60,
                    showEditIcon: false,
                    initials: initials,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_shipping,
                      title: 'Free Delivery',
                      subtitle: 'On orders over GHS 50',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.verified,
                      title: 'Fresh Quality',
                      subtitle: '100% Organic',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: category,
              isSelected: _selectedCategory == category,
              onSelected: () => _onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.go('/categories');
              break;
            case 2:
              context.go('/cart');
              break;
            case 3:
              context.go('/orders');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // TODO: Replace these with actual data from ProductService
  // Removed unused mock data methods - now using Firebase data
}
