import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../../core/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _orders = [];
  List<OrderModel> _userOrders = [];
  Map<String, dynamic> _orderStatistics = {};
  
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  String? _error;
  String _selectedStatus = 'all';
  String _selectedTimePeriod = 'all';
  
  // Getters
  List<OrderModel> get orders => _orders;
  List<OrderModel> get userOrders => _userOrders;
  Map<String, dynamic> get orderStatistics => _orderStatistics;
  bool get isLoading => _isLoading;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;
  String get selectedTimePeriod => _selectedTimePeriod;

  // Get filtered orders for admin
  List<OrderModel> get filteredOrders {
    List<OrderModel> filtered = _orders;
    
    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered.where((order) => order.status == _selectedStatus).toList();
    }
    
    // Filter by time period
    final now = DateTime.now();
    switch (_selectedTimePeriod) {
      case 'today':
        final today = DateTime(now.year, now.month, now.day);
        filtered = filtered.where((order) => order.createdAt.isAfter(today)).toList();
        break;
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((order) => order.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered = filtered.where((order) => order.createdAt.isAfter(monthAgo)).toList();
        break;
      case 'all':
      default:
        break;
    }
    
    return filtered;
  }

  // Initialize orders (Admin)
  Future<void> initializeOrders() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Listen to all orders stream
      _orderService.getAllOrders().listen(
        (orders) {
          _orders = orders;
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load orders: $error');
        },
      );
      
      // Load order statistics
      await loadOrderStatistics();
      
    } catch (e) {
      _setError('Failed to initialize orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Initialize user orders
  Future<void> initializeUserOrders(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Listen to user orders stream
      _orderService.getUserOrders(userId).listen(
        (orders) {
          _userOrders = orders;
          notifyListeners();
        },
        onError: (error) {
          _setError('Failed to load user orders: $error');
        },
      );
      
    } catch (e) {
      _setError('Failed to initialize user orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Place order
  Future<String?> placeOrder({
    required String userId,
    required CartModel cart,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      _setPlacingOrder(true);
      _clearError();
      
      final orderId = await _orderService.placeOrder(
        userId: userId,
        cart: cart,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      
      if (orderId != null) {
        // Order will be automatically added to the list via the stream
        return orderId;
      } else {
        _setError('Failed to place order');
        return null;
      }
    } catch (e) {
      _setError('Error placing order: $e');
      return null;
    } finally {
      _setPlacingOrder(false);
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      return await _orderService.getOrderById(orderId);
    } catch (e) {
      _setError('Failed to load order: $e');
      return null;
    }
  }

  // Update order status (Admin)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      _clearError();
      
      final success = await _orderService.updateOrderStatus(orderId, newStatus);
      if (success) {
        // Order will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to update order status');
        return false;
      }
    } catch (e) {
      _setError('Error updating order status: $e');
      return false;
    }
  }

  // Update payment status (Admin)
  Future<bool> updatePaymentStatus(String orderId, String newPaymentStatus) async {
    try {
      _clearError();
      
      final success = await _orderService.updatePaymentStatus(orderId, newPaymentStatus);
      if (success) {
        // Order will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to update payment status');
        return false;
      }
    } catch (e) {
      _setError('Error updating payment status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      _clearError();
      
      final success = await _orderService.cancelOrder(orderId, reason);
      if (success) {
        // Order will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to cancel order');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling order: $e');
      return false;
    }
  }

  // Load order statistics (Admin)
  Future<void> loadOrderStatistics() async {
    try {
      final stats = await _orderService.getOrderStatistics();
      _orderStatistics = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading order statistics: $e');
    }
  }

  // Search orders (Admin)
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      return await _orderService.searchOrders(query);
    } catch (e) {
      _setError('Search failed: $e');
      return [];
    }
  }

  // Set status filter
  void setStatusFilter(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  // Set time period filter
  void setTimePeriodFilter(String timePeriod) {
    if (_selectedTimePeriod != timePeriod) {
      _selectedTimePeriod = timePeriod;
      notifyListeners();
    }
  }

  // Get recent orders (Admin)
  Stream<List<OrderModel>> getRecentOrders({int limit = 10}) {
    return _orderService.getRecentOrders(limit: limit);
  }

  // Get orders by date range (Admin)
  Stream<List<OrderModel>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orderService.getOrdersByDateRange(startDate, endDate);
  }

  // Add delivery tracking
  Future<bool> addDeliveryTracking(String orderId, Map<String, dynamic> trackingInfo) async {
    try {
      final success = await _orderService.addDeliveryTracking(orderId, trackingInfo);
      if (success) {
        // Order will be automatically updated in the list via the stream
        return true;
      } else {
        _setError('Failed to add delivery tracking');
        return false;
      }
    } catch (e) {
      _setError('Error adding delivery tracking: $e');
      return false;
    }
  }



  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setPlacingOrder(bool placing) {
    if (_isPlacingOrder != placing) {
      _isPlacingOrder = placing;
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

  // Refresh orders
  Future<void> refresh() async {
    await loadOrderStatistics();
  }

  // No need to override dispose() as the parent implementation is sufficient
}
