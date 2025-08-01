import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../../core/services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  
  List<ProductModel> _products = [];
  List<ProductModel> _featuredProducts = [];
  List<ProductModel> _searchResults = [];
  List<String> _categories = [];
  
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String _selectedCategory = 'All';
  String _sortBy = 'featured';
  
  // Getters
  List<ProductModel> get products => _products;
  List<ProductModel> get featuredProducts => _featuredProducts;
  List<ProductModel> get searchResults => _searchResults;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;

  // Get products by category
  List<ProductModel> get filteredProducts {
    List<ProductModel> filtered = _selectedCategory == 'All' 
        ? _products 
        : _products.where((product) => product.category == _selectedCategory).toList();
    
    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        filtered.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'featured':
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

  // Initialize products
  Future<void> initializeProducts() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Load categories
      await loadCategories();
      
      // Listen to products stream
      _productService.getProducts().listen(
        (products) {
          _products = products;
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load products: $error');
        },
      );
      
      // Listen to featured products stream
      _productService.getFeaturedProducts(limit: 10).listen(
        (products) {
          _featuredProducts = products;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error loading featured products: $error');
        },
      );
      
    } catch (e) {
      _setError('Failed to initialize products: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      _categories = ['All', ...categories];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _setSearching(false);
      return;
    }

    try {
      _setSearching(true);
      _clearError();
      
      final results = await _productService.searchProducts(query);
      _searchResults = results;
      
    } catch (e) {
      _setError('Search failed: $e');
      _searchResults = [];
    } finally {
      _setSearching(false);
    }
  }

  // Clear search
  void clearSearch() {
    _searchResults = [];
    _setSearching(false);
  }

  // Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  // Set sort option
  void setSortBy(String sortBy) {
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      notifyListeners();
    }
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      return await _productService.getProductById(productId);
    } catch (e) {
      _setError('Failed to load product: $e');
      return null;
    }
  }

  // Get related products
  Future<List<ProductModel>> getRelatedProducts(String productId, String category) async {
    try {
      return await _productService.getRelatedProducts(productId, category);
    } catch (e) {
      debugPrint('Error loading related products: $e');
      return [];
    }
  }

  // Admin methods
  
  // Add product (Admin only)
  Future<bool> addProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _clearError();
      
      final success = await _productService.addProduct(product);
      if (success) {
        // Product will be automatically added to the list via the stream
        return true;
      } else {
        _setError('Failed to add product');
        return false;
      }
    } catch (e) {
      _setError('Error adding product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update product (Admin only)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      _setLoading(true);
      _clearError();
      
      final success = await _productService.updateProduct(product);
      if (success) {
        // Product will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to update product');
        return false;
      }
    } catch (e) {
      _setError('Error updating product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete product (Admin only)
  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final success = await _productService.deleteProduct(productId);
      if (success) {
        // Product will be automatically removed from the list via the stream
        return true;
      } else {
        _setError('Failed to delete product');
        return false;
      }
    } catch (e) {
      _setError('Error deleting product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update product stock (Admin only)
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      final success = await _productService.updateProductStock(productId, newStock);
      if (success) {
        // Product will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to update stock');
        return false;
      }
    } catch (e) {
      _setError('Error updating stock: $e');
      return false;
    }
  }

  // Get low stock products (Admin)
  Stream<List<ProductModel>> getLowStockProducts({int threshold = 10}) {
    return _productService.getLowStockProducts(threshold: threshold);
  }

  // Get out of stock products (Admin)
  Stream<List<ProductModel>> getOutOfStockProducts() {
    return _productService.getOutOfStockProducts();
  }

  // Initialize sample data (Development only)
  Future<void> initializeSampleProducts() async {
    try {
      await _productService.initializeSampleProducts();
    } catch (e) {
      debugPrint('Error initializing sample products: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setSearching(bool searching) {
    if (_isSearching != searching) {
      _isSearching = searching;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Refresh products
  Future<void> refresh() async {
    await initializeProducts();
  }

  // No need to override dispose() as the parent implementation is sufficient
}
