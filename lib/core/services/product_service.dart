import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/product_model.dart';
import 'firebase_service.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  // Get all products
  Stream<List<ProductModel>> getProducts() {
    return _firebaseService.firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .orderBy('isFeatured', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    if (category == 'All') {
      return getProducts();
    }
    
    return _firebaseService.firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('isFeatured', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Filter by search query (case-insensitive)
      return products.where((product) {
        final searchLower = query.toLowerCase();
        return product.name.toLowerCase().contains(searchLower) ||
               product.description.toLowerCase().contains(searchLower) ||
               product.category.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  // Get featured products
  Stream<List<ProductModel>> getFeaturedProducts({int limit = 10}) {
    return _firebaseService.firestore
        .collection('products')
        .where('isAvailable', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('products')
          .doc(productId)
          .get();
      
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting product by ID: $e');
      return null;
    }
  }

  // Get related products
  Future<List<ProductModel>> getRelatedProducts(String productId, String category) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .where('category', isEqualTo: category)
          .limit(6)
          .get();
      
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .where((product) => product.id != productId)
          .take(4)
          .toList();
    } catch (e) {
      debugPrint('Error getting related products: $e');
      return [];
    }
  }

  // Add product (Admin only)
  Future<bool> addProduct(ProductModel product) async {
    try {
      await _firebaseService.firestore
          .collection('products')
          .doc(product.id)
          .set(product.toMap());
      
      // Log analytics
      await _firebaseService.logEvent(
        name: 'product_added',
        parameters: {
          'product_id': product.id,
          'product_name': product.name,
          'category': product.category,
          'price': product.price,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error adding product: $e');
      return false;
    }
  }

  // Update product (Admin only)
  Future<bool> updateProduct(ProductModel product) async {
    try {
      await _firebaseService.firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
      
      // Log analytics
      await _firebaseService.logEvent(
        name: 'product_updated',
        parameters: {
          'product_id': product.id,
          'product_name': product.name,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      return false;
    }
  }

  // Delete product (Admin only)
  Future<bool> deleteProduct(String productId) async {
    try {
      await _firebaseService.firestore
          .collection('products')
          .doc(productId)
          .delete();
      
      // Log analytics
      await _firebaseService.logEvent(
        name: 'product_deleted',
        parameters: {
          'product_id': productId,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  // Update product stock
  Future<bool> updateProductStock(String productId, int newStock) async {
    try {
      await _firebaseService.firestore
          .collection('products')
          .doc(productId)
          .update({
        'stockQuantity': newStock,
        'isAvailable': newStock > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating product stock: $e');
      return false;
    }
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('products')
          .get();
      
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        categories.add(product.category);
      }
      
      return categories.toList()..sort();
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return ['Eggs', 'Poultry', 'Dairy', 'Vegetables', 'Fruits', 'Grains'];
    }
  }

  // Get low stock products (Admin)
  Stream<List<ProductModel>> getLowStockProducts({int threshold = 10}) {
    return _firebaseService.firestore
        .collection('products')
        .where('stockQuantity', isLessThanOrEqualTo: threshold)
        .where('stockQuantity', isGreaterThan: 0)
        .orderBy('stockQuantity')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get out of stock products (Admin)
  Stream<List<ProductModel>> getOutOfStockProducts() {
    return _firebaseService.firestore
        .collection('products')
        .where('stockQuantity', isEqualTo: 0)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
    });
  }

  // Initialize sample products (for development)
  Future<void> initializeSampleProducts() async {
    try {
      final sampleProducts = [
        ProductModel(
          id: 'prod_001',
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
          id: 'prod_002',
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
          id: 'prod_003',
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
          id: 'prod_004',
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
          id: 'prod_005',
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
          id: 'prod_006',
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

      for (final product in sampleProducts) {
        await addProduct(product);
      }
      
      debugPrint('Sample products initialized successfully');
    } catch (e) {
      debugPrint('Error initializing sample products: $e');
    }
  }
}
