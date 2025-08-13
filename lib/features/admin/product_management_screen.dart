import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/image_service.dart';
import '../../core/services/product_service.dart';
import '../../core/services/cloudinary_service.dart';
import '../../shared/models/product_model.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/loading_overlay.dart';
import '../../shared/widgets/image_picker_widget.dart';
import 'image_migration_screen.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = false;
  
  // Firebase integration
  List<ProductModel> _products = [];
  StreamSubscription<List<ProductModel>>? _productsSubscription;
  
  final List<String> _categories = [
    'All', 'Eggs', 'Poultry', 'Dairy', 'Vegetables', 'Fruits'
  ];
  
  final List<String> _statusOptions = [
    'All', 'Available', 'Out of Stock', 'Low Stock'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadProducts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _productsSubscription?.cancel();
    super.dispose();
  }

  void _loadProducts() {
    setState(() {
      _isLoading = true;
    });
    
    // Load products from Firebase using ProductService
    final productsStream = ProductService().getProducts();
    _productsSubscription?.cancel();
    _productsSubscription = productsStream.listen(
      (products) {
        if (mounted) {
          setState(() {
            _products = products;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error loading products: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading products: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  List<ProductModel> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      
      bool matchesStatus = true;
      if (_selectedStatus == 'Available') {
        matchesStatus = product.isAvailable && product.stockQuantity > 10;
      } else if (_selectedStatus == 'Out of Stock') {
        matchesStatus = !product.isAvailable || product.stockQuantity == 0;
      } else if (_selectedStatus == 'Low Stock') {
        matchesStatus = product.isAvailable && product.stockQuantity > 0 && product.stockQuantity <= 10;
      }
      
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Product Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All Products'),
            Tab(text: 'Add Product'),
          ],
        ),
        actions: [
          // Image migration button
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ImageMigrationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.cloud_sync, color: AppColors.warning),
            tooltip: 'Migrate Product Images',
          ),
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductListTab(),
              _buildAddProductTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductListTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: _buildProductList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          CustomTextField(
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
                : null,
          ),
          const SizedBox(height: 16),
          // Filter chips
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Category',
                  _selectedCategory,
                  _categories,
                  (value) => setState(() => _selectedCategory = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  _selectedStatus,
                  _statusOptions,
                  (value) => setState(() => _selectedStatus = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.inputBackground,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProductList() {
    final filteredProducts = _filteredProducts;
    
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
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
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product, index);
      },
    );
  }

  Widget _buildProductCard(ProductModel product, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 26),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Product image and basic info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Product image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.inputBackground,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.imageUrls.isNotEmpty && product.imageUrls.first.isNotEmpty
                                ? (() {
                                    final firstUrl = product.imageUrls.first;
                                    final isNetwork = firstUrl.startsWith('http');
                                    final isLocalPath = firstUrl.startsWith('file://') || (firstUrl.startsWith('/') && !firstUrl.startsWith('http'));

                                    if (isNetwork) {
                                      return CachedNetworkImage(
                                        imageUrl: firstUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.inputBackground,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) {
                                          debugPrint('Error loading image: $url, Error: $error');
                                          return Container(
                                            color: AppColors.inputBackground,
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.image_not_supported,
                                                  color: AppColors.textSecondary,
                                                  size: 24,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'No Image',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    } else if (isLocalPath && !kIsWeb) {
                                      // Handle local file path
                                      String path;
                                      if (firstUrl.startsWith('file:///')) {
                                        path = firstUrl.substring(8);
                                      } else if (firstUrl.startsWith('file://')) {
                                        path = firstUrl.substring(7);
                                      } else {
                                        path = firstUrl;
                                      }
                                      final file = File(path);
                                      if (file.existsSync()) {
                                        return Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) {
                                            debugPrint('Error loading local image: $firstUrl, Error: $error');
                                            return Container(
                                              color: AppColors.inputBackground,
                                              child: const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    color: AppColors.textSecondary,
                                                    size: 24,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'No Image',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      // Fallback if file doesn't exist
                                      return Container(
                                        color: AppColors.inputBackground,
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              color: AppColors.textSecondary,
                                              size: 24,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'No Image',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else {
                                      // Unknown format or running on web without file access
                                      return Container(
                                        color: AppColors.inputBackground,
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              color: AppColors.textSecondary,
                                              size: 24,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'No Image',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  })()
                                : Container(
                                    color: AppColors.inputBackground,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          color: AppColors.textSecondary,
                                          size: 24,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'No Image',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Product details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _buildStatusBadge(product),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'GHS ${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Stock: ${product.stockQuantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: product.stockQuantity > 10
                                          ? AppColors.success
                                          : product.stockQuantity > 0
                                              ? AppColors.warning
                                              : AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground.withValues(alpha: 128),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Edit',
                            onPressed: () => _editProduct(product),
                            variant: ButtonVariant.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: product.isAvailable ? 'Disable' : 'Enable',
                            onPressed: () => _toggleProductStatus(product),
                            variant: product.isAvailable ? ButtonVariant.outline : ButtonVariant.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => _deleteProduct(product),
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(alpha: 26),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
      },
    );
  }

  Widget _buildStatusBadge(ProductModel product) {
    String status;
    Color color;
    
    if (!product.isAvailable || product.stockQuantity == 0) {
      status = 'Out of Stock';
      color = AppColors.error;
    } else if (product.stockQuantity <= 10) {
      status = 'Low Stock';
      color = AppColors.warning;
    } else {
      status = 'Available';
      color = AppColors.success;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 77)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAddProductTab() {
    return const AddProductForm();
  }

  void _editProduct(ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProductModal(product: product),
    );
  }

  void _toggleProductStatus(ProductModel product) {
    // TODO: Implement product status toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${product.name} ${product.isAvailable ? 'disabled' : 'enabled'} successfully',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement product deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// Add Product Form Widget
class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  
  String _selectedCategory = 'Eggs';
  String _selectedUnit = 'piece';
  bool _isOrganic = false;
  bool _isFeatured = false;
  bool _isLoading = false;
  String? _imageUrl; // Add state variable for image picker

  final List<String> _categories = ['Eggs', 'Poultry', 'Dairy', 'Vegetables', 'Fruits'];
  final List<String> _units = ['piece', 'kg', 'liter', 'dozen', 'pack'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Product',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Product images section
            _buildImageSection(),
            const SizedBox(height: 24),
            
            // Basic information
            CustomTextField(
              controller: _nameController,
              label: 'Product Name',
              hint: 'Enter product name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Enter product description',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Price (GHS )',
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    'Unit',
                    _selectedUnit,
                    _units,
                    (value) => setState(() => _selectedUnit = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    'Category',
                    _selectedCategory,
                    _categories,
                    (value) => setState(() => _selectedCategory = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _stockController,
                    label: 'Stock Quantity',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter stock quantity';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Switches
            _buildSwitchTile('Organic Product', _isOrganic, (value) => setState(() => _isOrganic = value)),
            _buildSwitchTile('Featured Product', _isFeatured, (value) => setState(() => _isFeatured = value)),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Add Product',
                onPressed: _isLoading ? null : _addProduct,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder, style: BorderStyle.solid),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ImagePickerWidget(
              imageType: ImageType.product,
              userId: 'admin', // We'll use a fixed ID for admin uploads
              productId: _nameController.text.isNotEmpty ? _nameController.text.toLowerCase().replaceAll(' ', '_') : 'temp_product',
              currentImageUrl: _imageUrl,
              isCircular: false,
              size: 200,
              title: 'Add Product Image',
              onImageSelected: (result) {
                if (result.success) {
                  setState(() {
                    _imageUrl = result.displayUrl;
                  });
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Product image uploaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to upload image: ${result.error}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.inputBackground,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, void Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withValues(alpha: 77)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate image is uploaded
    if (_imageUrl == null || _imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create product object with all the form data
      final product = ProductModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrls: [_imageUrl!], // Use the uploaded image URL in a list
        stockQuantity: int.parse(_stockController.text),
        unit: _selectedUnit,
        isOrganic: _isOrganic,
        isFeatured: _isFeatured,
        rating: 5.0,
        reviewCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save product to Firebase using ProductService
      final productService = ProductService();
      final success = await productService.addProduct(product);
      
      if (!success) {
        throw Exception('Failed to save product to Firebase');
      }
      
      debugPrint('Product successfully saved to Firebase: ${product.name} with ID: ${product.id}');
      
      // Check if widget is still mounted before using BuildContext
      if (!mounted) return;
      
      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.clear();
      
      setState(() {
        _isLoading = false;
        _isOrganic = false;
        _isFeatured = false;
        _imageUrl = null; // Reset the image URL
        _selectedCategory = 'Eggs';
        _selectedUnit = 'piece';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // Check if widget is still mounted before using BuildContext
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Edit Product Modal
class EditProductModal extends StatefulWidget {
  final ProductModel product;

  const EditProductModal({super.key, required this.product});

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  
  late String _selectedCategory;
  late String _selectedUnit;
  late bool _isOrganic;
  late bool _isFeatured;
  late String? _imageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  
  final List<String> _categories = ['Eggs', 'Poultry', 'Dairy', 'Vegetables', 'Fruits', 'Grains'];
  final List<String> _units = ['piece', 'kg', 'gram', 'liter', 'dozen', 'pack'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    
    _selectedCategory = widget.product.category;
    _selectedUnit = widget.product.unit;
    _isOrganic = widget.product.isOrganic;
    _isFeatured = widget.product.isFeatured;
    _imageUrl = widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: LoadingOverlay(
        isLoading: _isLoading,
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
                    'Edit Product',
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
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section
                      _buildImageSection(),
                      const SizedBox(height: 24),
                      
                      // Product Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Product Name',
                        hint: 'Enter product name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Enter product description',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter product description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Price and Stock Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _priceController,
                              label: 'Price (GHS)',
                              hint: '0.00',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _stockController,
                              label: 'Stock Quantity',
                              hint: '0',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter stock';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid stock';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Category and Unit Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              'Category',
                              _selectedCategory,
                              _categories,
                              (value) => setState(() => _selectedCategory = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdownField(
                              'Unit',
                              _selectedUnit,
                              _units,
                              (value) => setState(() => _selectedUnit = value!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Switches
                      _buildSwitchTile('Organic Product', _isOrganic, (value) => setState(() => _isOrganic = value)),
                      _buildSwitchTile('Featured Product', _isFeatured, (value) => setState(() => _isFeatured = value)),
                      
                      const SizedBox(height: 32),
                      
                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: 'Update Product',
                          onPressed: _updateProduct,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        // Enhanced Image Section with better UX
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Product Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_isUploadingImage)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              
              // Image Preview
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: _imageUrl != null && _imageUrl!.isNotEmpty
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Overlay with edit button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: _isUploadingImage ? null : _showImageOptions,
                                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _isUploadingImage ? null : _showImageOptions,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add product image',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Recommended: 1200x1200px',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingImage ? null : _showImageOptions,
                        icon: Icon(_imageUrl != null ? Icons.edit : Icons.add_a_photo),
                        label: Text(_imageUrl != null ? 'Change Image' : 'Add Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_imageUrl != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _isUploadingImage ? null : _removeImage,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('Remove', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, void Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final ImageService imageService = ImageService();
      final image = await imageService.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        // Upload directly to Cloudinary with better error handling
        final result = await _uploadImageToCloudinary(image);
        
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            if (result.success && result.imageUrl != null) {
              _imageUrl = result.imageUrl!;
            }
          });

          if (result.success && result.imageUrl != null) {
            // Update the product with the new image URL
            await _updateProductImage(result.imageUrl!);
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload image: ${result.error ?? "Unknown error"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageUploadResult> _uploadImageToCloudinary(XFile imageFile) async {
    try {
      final CloudinaryService cloudinaryService = CloudinaryService();
      
      // Convert XFile to File for Cloudinary upload
      File file;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(bytes);
        file = tempFile;
      } else {
        file = File(imageFile.path);
      }
      
      final cloudinaryUrl = await cloudinaryService.uploadImage(
        imageFile: file,
        folder: 'eggstra/products',
        publicId: 'product_${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Clean up temporary file if created for web
      if (kIsWeb && await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Failed to delete temp file: $e');
        }
      }
      
      if (cloudinaryUrl != null) {
        return ImageUploadResult(
          success: true,
          imageUrl: cloudinaryUrl,
          isCloudinary: true,
        );
      } else {
        return ImageUploadResult(
          success: false,
          error: 'Cloudinary upload failed - no URL returned',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return ImageUploadResult(
        success: false,
        error: 'Cloudinary upload failed: $e',
      );
    }
  }

  void _removeImage() {
    setState(() {
      _imageUrl = null;
    });
    
    // Update the product to remove the image
    _updateProductImage(null);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed successfully'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _updateProductImage(String? newImageUrl) async {
    try {
      // Update the product's image URLs
      final updatedImageUrls = List<String>.from(widget.product.imageUrls);
      
      if (newImageUrl != null) {
        if (updatedImageUrls.isNotEmpty) {
          updatedImageUrls[0] = newImageUrl; // Replace the first image
        } else {
          updatedImageUrls.add(newImageUrl); // Add as first image
        }
      } else {
        // Remove image
        if (updatedImageUrls.isNotEmpty) {
          updatedImageUrls.removeAt(0);
        }
      }

      final updatedProduct = widget.product.copyWith(
        imageUrls: updatedImageUrls,
        updatedAt: DateTime.now(),
      );

      final productService = ProductService();
      final success = await productService.updateProduct(updatedProduct);

      if (!success) {
        throw Exception('Failed to update product image in Firebase');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Create updated product object
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text),
        stockQuantity: int.parse(_stockController.text),
        category: _selectedCategory,
        unit: _selectedUnit,
        isOrganic: _isOrganic,
        isFeatured: _isFeatured,
        updatedAt: DateTime.now(),
      );
      
      // Update product in Firebase using ProductService
      final productService = ProductService();
      final success = await productService.updateProduct(updatedProduct);
      
      if (!success) {
        throw Exception('Failed to update product in Firebase');
      }
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate success
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
