import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firebase_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';
import 'auth_provider.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final AuthProvider _authProvider;
  
  CartModel? _cart;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cart?.isEmpty ?? true;
  bool get isNotEmpty => _cart?.isNotEmpty ?? false;
  int get totalItems => _cart?.totalItems ?? 0;
  double get subtotal => _cart?.subtotal ?? 0.0;
  double get tax => _cart?.tax ?? 0.0;
  double get deliveryFee => _cart?.deliveryFee ?? 0.0;
  double get discount => 0.0; // Default discount implementation
  double get total => _cart?.total ?? 0.0;
  List<CartItemModel> get items => _cart?.items ?? [];

  CartProvider(this._authProvider) {
    _initializeCart();
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      _loadCartFromFirestore();
    } else {
      _loadCartFromLocal();
    }
  }

  Future<void> _initializeCart() async {
    if (_authProvider.isAuthenticated) {
      await _loadCartFromFirestore();
    } else {
      await _loadCartFromLocal();
    }
  }

  Future<void> _loadCartFromFirestore() async {
    if (_authProvider.user == null) return;

    try {
      _setLoading(true);
      
      final cartDoc = await _firebaseService.cartCollection
          .doc(_authProvider.user!.id)
          .get();

      if (cartDoc.exists) {
        _cart = CartModel.fromFirestore(cartDoc);
      } else {
        _cart = _createEmptyCart();
        await _saveCartToFirestore();
      }

      // Also save to local storage as backup
      await _saveCartToLocal();
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load cart: $e';
      debugPrint('Error loading cart from Firestore: $e');
      // Fallback to local cart
      await _loadCartFromLocal();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadCartFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(AppConstants.cartDataKey);
      
      if (cartData != null) {
        // Parse cart data from local storage
        // Note: This is a simplified implementation
        // In a real app, you'd properly serialize/deserialize the cart
        _cart = _createEmptyCart();
      } else {
        _cart = _createEmptyCart();
      }
      
      await _saveCartToLocal();
    } catch (e) {
      _cart = _createEmptyCart();
      debugPrint('Error loading cart from local storage: $e');
    }
    
    notifyListeners();
  }

  Future<void> _saveCartToFirestore() async {
    if (_cart == null || _authProvider.user == null) return;

    try {
      await _firebaseService.cartCollection
          .doc(_authProvider.user!.id)
          .set(_cart!.toMap());
    } catch (e) {
      debugPrint('Error saving cart to Firestore: $e');
    }
  }

  Future<void> _saveCartToLocal() async {
    if (_cart == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cartDataKey, _cart!.toMap().toString());
    } catch (e) {
      debugPrint('Error saving cart to local storage: $e');
    }
  }

  CartModel _createEmptyCart() {
    return CartModel(
      id: _authProvider.user?.id ?? const Uuid().v4(),
      userId: _authProvider.user?.id ?? '',
      items: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Cart operations
  Future<bool> addItem(ProductModel product, {int quantity = 1}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      _cart ??= _createEmptyCart();

      final existingItemIndex = _cart!.items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingItemIndex >= 0) {
        // Update existing item quantity
        final existingItem = _cart!.items[existingItemIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        
        final updatedItems = List<CartItemModel>.from(_cart!.items);
        updatedItems[existingItemIndex] = updatedItem;
        
        _cart = _cart!.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );
      } else {
        // Add new item
        final newItem = CartItemModel(
          id: const Uuid().v4(),
          productId: product.id,
          product: product,
          quantity: quantity,
          unitPrice: product.price,
          addedAt: DateTime.now(),
        );

        _cart = _cart!.copyWith(
          items: [..._cart!.items, newItem],
          updatedAt: DateTime.now(),
        );
      }

      await _saveCart();
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'add_to_cart',
        parameters: {
          'item_id': product.id,
          'item_name': product.name,
          'item_category': product.category,
          'quantity': quantity,
          'value': product.discountedPrice * quantity,
          'currency': AppConstants.defaultCurrency,
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to add item to cart: $e');
      debugPrint('Error adding item to cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeItem(String productId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null) return false;

      final itemToRemove = _cart!.getItemByProductId(productId);
      if (itemToRemove == null) return false;

      final updatedItems = _cart!.items.where(
        (item) => item.productId != productId,
      ).toList();

      _cart = _cart!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'remove_from_cart',
        parameters: {
          'item_id': productId,
          'item_name': itemToRemove.product.name,
          'item_category': itemToRemove.product.category,
          'quantity': itemToRemove.quantity,
          'value': itemToRemove.discountedTotalPrice,
          'currency': AppConstants.defaultCurrency,
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to remove item from cart: $e');
      debugPrint('Error removing item from cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateItemQuantity(String productId, int quantity) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null || quantity < 0) return false;

      if (quantity == 0) {
        return await removeItem(productId);
      }

      final itemIndex = _cart!.items.indexWhere(
        (item) => item.productId == productId,
      );

      if (itemIndex < 0) return false;

      final updatedItem = _cart!.items[itemIndex].copyWith(quantity: quantity);
      final updatedItems = List<CartItemModel>.from(_cart!.items);
      updatedItems[itemIndex] = updatedItem;

      _cart = _cart!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      return true;
    } catch (e) {
      _setError('Failed to update item quantity: $e');
      debugPrint('Error updating item quantity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> clearCart() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      _cart = _createEmptyCart();
      await _saveCart();
      
      // Log analytics event
      await _firebaseService.logEvent(name: 'clear_cart');

      return true;
    } catch (e) {
      _setError('Failed to clear cart: $e');
      debugPrint('Error clearing cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> applyCoupon(String couponCode) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null) return false;

      // TODO: Implement coupon validation logic
      // For now, we'll apply a dummy discount
      double discount = 0.0;
      if (couponCode.toUpperCase() == 'SAVE10') {
        discount = _cart!.subtotal * 0.1; // 10% discount
      }

      _cart = _cart!.copyWith(
        couponCode: couponCode,
        couponDiscount: discount,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'apply_coupon',
        parameters: {
          'coupon_code': couponCode,
          'discount_amount': discount,
          'currency': AppConstants.defaultCurrency,
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to apply coupon: $e');
      debugPrint('Error applying coupon: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeCoupon() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null) return false;

      _cart = _cart!.copyWith(
        couponCode: null,
        couponDiscount: null,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      return true;
    } catch (e) {
      _setError('Failed to remove coupon: $e');
      debugPrint('Error removing coupon: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveCart() async {
    if (_authProvider.isAuthenticated) {
      await _saveCartToFirestore();
    }
    await _saveCartToLocal();
    notifyListeners();
  }

  int getProductQuantity(String productId) {
    return _cart?.getProductQuantity(productId) ?? 0;
  }

  bool hasProduct(String productId) {
    return _cart?.hasProduct(productId) ?? false;
  }

  Future<void> refreshCart() async {
    await _initializeCart();
  }

  // Additional methods for cart screen compatibility
  Future<bool> addToCart(ProductModel product, int quantity) async {
    return await addItem(product, quantity: quantity);
  }

  Future<bool> updateQuantity(String productId, int newQuantity) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null) return false;

      final itemIndex = _cart!.items.indexWhere(
        (item) => item.productId == productId,
      );

      if (itemIndex < 0) return false;

      if (newQuantity <= 0) {
        return await removeFromCart(productId);
      }

      final updatedItems = List<CartItemModel>.from(_cart!.items);
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        quantity: newQuantity,
      );

      _cart = _cart!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      return true;
    } catch (e) {
      _setError('Failed to update quantity: $e');
      debugPrint('Error updating quantity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> removeFromCart(String productId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (_cart == null) return false;

      final updatedItems = _cart!.items.where(
        (item) => item.productId != productId,
      ).toList();

      _cart = _cart!.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _saveCart();
      
      // Log analytics event
      await _firebaseService.logEvent(
        name: 'remove_from_cart',
        parameters: {
          'product_id': productId,
          'currency': AppConstants.defaultCurrency,
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to remove item: $e');
      debugPrint('Error removing item: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  int get itemCount => _cart?.totalItems ?? 0;

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
