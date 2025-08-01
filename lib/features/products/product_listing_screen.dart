import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/models/product_model.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/product_card.dart';
import '../../shared/widgets/category_chip.dart';

class ProductListingScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  final bool showCategoriesOnly;

  const ProductListingScreen({
    super.key,
    this.category,
    this.searchQuery,
    this.showCategoriesOnly = false,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'Featured';
  bool _isLoading = false;
  
  // Mock data - replace with Firebase integration
  List<ProductModel> _products = [];
  
  final List<String> _categories = [
    'All', 'Eggs', 'Poultry', 'Dairy', 'Vegetables', 'Fruits', 'Grains'
  ];
  
  final List<String> _sortOptions = [
    'Featured', 'Price: Low to High', 'Price: High to Low', 'Newest', 'Rating'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Initialize with passed parameters
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
    }
    
    _loadProducts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
    });
    
    // Mock products data - replace with Firebase call
    _products = [
      ProductModel(
        id: '1',
        name: 'Free Range Eggs (Dozen)',
        description: 'Fresh free-range eggs from our happy chickens, rich in omega-3 and vitamins',
        price: 15.99,
        category: 'Eggs',
        imageUrls: ['https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Free+Range+Eggs'],
        unit: 'dozen',
        stockQuantity: 50,
        isAvailable: true,
        isFeatured: true,
        isOrganic: true,
        discount: 10.0,
        rating: 4.8,
        reviewCount: 124,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        farmLocation: 'Akuapem Hills',
        harvestDate: DateTime.now().subtract(const Duration(days: 1)),
        expiryDate: DateTime.now().add(const Duration(days: 14)),
      ),
      ProductModel(
        id: '2',
        name: 'Organic Chicken Breast',
        description: 'Premium organic chicken breast, hormone-free and antibiotic-free',
        price: 28.50,
        category: 'Poultry',
        imageUrls: ['https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Chicken+Breast'],
        unit: 'kg',
        stockQuantity: 25,
        isAvailable: true,
        isFeatured: true,
        isOrganic: true,
        rating: 4.6,
        reviewCount: 89,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
        farmLocation: 'Kumasi Farms',
      ),
      ProductModel(
        id: '3',
        name: 'Farm Fresh Milk',
        description: 'Pure, pasteurized milk from grass-fed cows',
        price: 8.99,
        category: 'Dairy',
        imageUrls: ['https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Fresh+Milk'],
        unit: 'liter',
        stockQuantity: 30,
        isAvailable: true,
        isFeatured: false,
        isOrganic: true,
        rating: 4.7,
        reviewCount: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now(),
        farmLocation: 'Ashanti Region',
      ),
      ProductModel(
        id: '4',
        name: 'Organic Tomatoes',
        description: 'Fresh organic tomatoes, perfect for cooking and salads',
        price: 12.00,
        category: 'Vegetables',
        imageUrls: ['https://via.placeholder.com/300x200/F44336/FFFFFF?text=Tomatoes'],
        unit: 'kg',
        stockQuantity: 40,
        isAvailable: true,
        isFeatured: false,
        isOrganic: true,
        rating: 4.5,
        reviewCount: 67,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        farmLocation: 'Volta Region',
      ),
      ProductModel(
        id: '5',
        name: 'Sweet Pineapples',
        description: 'Juicy and sweet pineapples, locally grown',
        price: 6.50,
        category: 'Fruits',
        imageUrls: ['https://via.placeholder.com/300x200/FFEB3B/000000?text=Pineapples'],
        unit: 'piece',
        stockQuantity: 20,
        isAvailable: true,
        isFeatured: true,
        isOrganic: false,
        rating: 4.4,
        reviewCount: 43,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
        farmLocation: 'Eastern Region',
      ),
      ProductModel(
        id: '6',
        name: 'Brown Rice',
        description: 'Nutritious brown rice, locally produced',
        price: 18.75,
        category: 'Grains',
        imageUrls: ['https://via.placeholder.com/300x200/8BC34A/FFFFFF?text=Brown+Rice'],
        unit: 'kg',
        stockQuantity: 15,
        isAvailable: true,
        isFeatured: false,
        isOrganic: true,
        rating: 4.3,
        reviewCount: 28,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
        farmLocation: 'Northern Region',
      ),
    ];
    
    setState(() {
      _isLoading = false;
    });
  }

  List<ProductModel> get _filteredProducts {
    var filtered = _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      
      return matchesSearch && matchesCategory && product.isAvailable;
    }).toList();
    
    // Sort products
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'Newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Featured':
      default:
        filtered.sort((a, b) {
          if (a.isFeatured && !b.isFeatured) return -1;
          if (!a.isFeatured && b.isFeatured) return 1;
          return b.rating.compareTo(a.rating);
        });
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.showCategoriesOnly ? 'Categories' : (widget.category ?? 'Products'),
        showBack: true,
        showCart: true,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.showCategoriesOnly
              ? _buildCategoriesView()
              : Column(
                  children: [
                    _buildSearchAndFilters(),
                    _buildCategoryChips(),
                    _buildSortAndResults(),
                    Expanded(
                      child: _buildProductGrid(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CustomTextField(
        controller: _searchController,
        label: 'Search',
        hint: 'Search products...',
        prefixIcon: Icons.search,
        onChanged: (value) => setState(() {}),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterDialog,
              ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CategoryChip(
              label: category,
              isSelected: _selectedCategory == category,
              onSelected: () => setState(() => _selectedCategory = category),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoriesView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomTextField(
            controller: _searchController,
            label: 'Search Categories',
            hint: 'Search for categories...',
            prefixIcon: Icons.search,
            onChanged: (value) => setState(() {}),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: _categories.where((cat) => cat != 'All').length,
            itemBuilder: (context, index) {
              // Skip 'All' category
              final category = _categories.where((cat) => cat != 'All').elementAt(index);
              
              // Get count of products in this category
              final productCount = _products.where((p) => p.category == category).length;
              
              // Generate a consistent color based on category name
              final categoryColor = _getCategoryColor(category);
              
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to products with this category pre-selected
                          context.push('/products', extra: {'category': category});
                        },
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: categoryColor.withValues(alpha: 50),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 48,
                                  color: categoryColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$productCount products',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary.withValues(alpha: 179),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSortAndResults() {
    final filteredProducts = _filteredProducts;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${filteredProducts.length} products found',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSortDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(20),
                color: AppColors.inputBackground,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final filteredProducts = _filteredProducts;
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 128),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary.withValues(alpha: 179),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 128),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCategory = 'All';
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: ProductCard(
                  productId: product.id,
                  name: product.name,
                  price: product.price,
                  imageUrl: product.imageUrl,
                  category: product.category,
                  rating: product.rating,
                  isOrganic: product.isOrganic,
                  onTap: () => _navigateToProductDetails(product),
                  onAddToCart: () => _addToCart(product),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Filter Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Filter options
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) {
                        return CategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onSelected: () => setState(() => _selectedCategory = category),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._sortOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: _sortBy,
                        onChanged: (value) => setState(() => _sortBy = value!),
                        activeColor: AppColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Apply button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
              activeColor: AppColors.primary,
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToProductDetails(ProductModel product) {
    // Use GoRouter instead of Navigator for consistent navigation
    context.push(
      '/product-details',
      extra: product.id,
    );
  }

  void _addToCart(ProductModel product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(product, 1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
  
  // Helper method to get consistent color based on category name
  Color _getCategoryColor(String category) {
    // Generate a consistent color based on the category name
    final colorMap = {
      'Eggs': const Color(0xFF4CAF50),      // Green
      'Poultry': const Color(0xFFFF9800),    // Orange
      'Dairy': const Color(0xFF2196F3),      // Blue
      'Vegetables': const Color(0xFFF44336), // Red
      'Fruits': const Color(0xFFFFEB3B),     // Yellow
      'Grains': const Color(0xFF8BC34A),     // Light Green
      'Meat': const Color(0xFFE91E63),       // Pink
      'Fish': const Color(0xFF03A9F4),       // Light Blue
      'Bakery': const Color(0xFFFF5722),     // Deep Orange
      'Beverages': const Color(0xFF9C27B0),  // Purple
    };
    
    return colorMap[category] ?? 
           // If category not in map, generate a deterministic color based on name
           Color((category.hashCode & 0xFFFFFF) | 0xFF000000);
  }

  // Helper method to get category icon
  IconData _getCategoryIcon(String category) {
    final iconMap = {
      'Eggs': Icons.egg_alt,
      'Poultry': Icons.agriculture,
      'Dairy': Icons.local_drink,
      'Vegetables': Icons.eco,
      'Fruits': Icons.apple,
      'Grains': Icons.grass,
      'Meat': Icons.restaurant_menu,
      'Fish': Icons.water,
      'Bakery': Icons.bakery_dining,
      'Beverages': Icons.local_cafe,
    };
    
    return iconMap[category] ?? Icons.category;
  }
}
