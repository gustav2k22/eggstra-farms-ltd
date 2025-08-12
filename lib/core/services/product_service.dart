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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Filter available products client-side to avoid composite index requirement
      final availableProducts = allProducts
          .where((product) => product.isAvailable)
          .toList();
      
      // Sort featured products first, then by creation date
      availableProducts.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return availableProducts;
    }).handleError((error) {
      debugPrint('Error loading products: $error');
      // Return empty list on error to prevent app crashes
      return <ProductModel>[];
    });
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    if (category == 'All') {
      return getProducts();
    }
    
    return _firebaseService.firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Filter by category and availability client-side to avoid composite index requirement
      final filteredProducts = allProducts
          .where((product) => product.isAvailable && product.category == category)
          .toList();
      
      // Sort featured products first, then by creation date
      filteredProducts.sort((a, b) {
        if (a.isFeatured && !b.isFeatured) return -1;
        if (!a.isFeatured && b.isFeatured) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return filteredProducts;
    }).handleError((error) {
      debugPrint('Error loading products by category: $error');
      return <ProductModel>[];
    });
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Filter by availability and search query client-side
      return allProducts.where((product) {
        if (!product.isAvailable) return false;
        
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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final allProducts = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      
      // Filter featured and available products client-side
      final featuredProducts = allProducts
          .where((product) => product.isAvailable && product.isFeatured)
          .toList();
      
      // Sort by rating (descending)
      featuredProducts.sort((a, b) => b.rating.compareTo(a.rating));
      
      // Apply limit
      return featuredProducts.take(limit).toList();
    }).handleError((error) {
      debugPrint('Error loading featured products: $error');
      return <ProductModel>[];
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
  // Sample products initialization removed - using real Firebase data only
}
