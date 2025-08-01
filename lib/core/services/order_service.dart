import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/order_model.dart';
import '../../shared/models/cart_model.dart';
import 'firebase_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  // Place order
  Future<String?> placeOrder({
    required String userId,
    required CartModel cart,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';
      
      final order = OrderModel(
        id: orderId,
        userId: userId,
        items: cart.items.map((cartItem) => OrderItemModel(
          productId: cartItem.productId,
          productName: cartItem.product.name,
          productImageUrl: cartItem.product.imageUrls.isNotEmpty ? cartItem.product.imageUrls.first : '',
          quantity: cartItem.quantity,
          unitPrice: cartItem.unitPrice,
          totalPrice: cartItem.discountedTotalPrice,
          unit: cartItem.product.unit,
        )).toList(),
        subtotal: cart.subtotal,
        tax: cart.tax,
        deliveryFee: cart.deliveryFee,
        total: cart.total + cart.tax + cart.deliveryFee,
        status: 'pending',
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        deliveryAddress: DeliveryAddressModel.fromMap(deliveryAddress),
        orderDate: DateTime.now(),
        notes: notes,
        orderNumber: _generateOrderNumber(),
      );

      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .set(order.toMap());

      // Log analytics
      await _firebaseService.logEvent(
        name: 'order_placed',
        parameters: {
          'order_id': orderId,
          'user_id': userId,
          'total_amount': order.total,
          'item_count': order.items.length,
          'payment_method': paymentMethod,
        },
      );

      return orderId;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }

  // Get user orders
  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _firebaseService.firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get all orders (Admin)
  Stream<List<OrderModel>> getAllOrders() {
    return _firebaseService.firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get orders by status (Admin)
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    return _firebaseService.firestore
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting order by ID: $e');
      return null;
    }
  }

  // Update order status (Admin)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await _firebaseService.logEvent(
        name: 'order_status_updated',
        parameters: {
          'order_id': orderId,
          'new_status': newStatus,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  // Update payment status (Admin)
  Future<bool> updatePaymentStatus(String orderId, String newPaymentStatus) async {
    try {
      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'paymentStatus': newPaymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await _firebaseService.logEvent(
        name: 'payment_status_updated',
        parameters: {
          'order_id': orderId,
          'payment_status': newPaymentStatus,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await _firebaseService.logEvent(
        name: 'order_cancelled',
        parameters: {
          'order_id': orderId,
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  // Get order statistics (Admin)
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('orders')
          .get();

      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      final totalOrders = orders.length;
      final totalRevenue = orders.fold<double>(0, (accumulated, order) => accumulated + order.total);
      final pendingOrders = orders.where((order) => order.status == 'pending').length;
      final deliveredOrders = orders.where((order) => order.status == 'delivered').length;
      final cancelledOrders = orders.where((order) => order.status == 'cancelled').length;

      // Calculate today's stats
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayOrders = orders.where((order) => 
        order.createdAt.isAfter(todayStart)
      ).toList();
      
      final todayOrderCount = todayOrders.length;
      final todayRevenue = todayOrders.fold<double>(0, (accumulated, order) => accumulated + order.total);

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'pendingOrders': pendingOrders,
        'deliveredOrders': deliveredOrders,
        'cancelledOrders': cancelledOrders,
        'todayOrders': todayOrderCount,
        'todayRevenue': todayRevenue,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0,
      };
    } catch (e) {
      debugPrint('Error getting order statistics: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'pendingOrders': 0,
        'deliveredOrders': 0,
        'cancelledOrders': 0,
        'todayOrders': 0,
        'todayRevenue': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }

  // Search orders (Admin)
  Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('orders')
          .get();
      
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      
      // Filter by search query (case-insensitive)
      return orders.where((order) {
        final searchLower = query.toLowerCase();
        return order.orderNumber.toLowerCase().contains(searchLower) ||
               order.id.toLowerCase().contains(searchLower) ||
               order.userId.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching orders: $e');
      return [];
    }
  }

  // Get recent orders (Admin)
  Stream<List<OrderModel>> getRecentOrders({int limit = 10}) {
    return _firebaseService.firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get orders by date range (Admin)
  Stream<List<OrderModel>> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _firebaseService.firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: startDate)
        .where('createdAt', isLessThanOrEqualTo: endDate)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  // Add delivery tracking
  Future<bool> addDeliveryTracking(String orderId, Map<String, dynamic> trackingInfo) async {
    try {
      await _firebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
        'trackingInfo': trackingInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding delivery tracking: $e');
      return false;
    }
  }

  // Generate order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final time = now.millisecondsSinceEpoch.toString().substring(8);
    
    return 'EF$year$month$day$time';
  }

  // Initialize sample orders (for development)
  Future<void> initializeSampleOrders() async {
    try {
      final sampleOrders = [
        OrderModel(
          id: 'order_001',
          userId: 'user_001',
          orderNumber: 'EF24010001',
          items: [],
          subtotal: 45.99,
          tax: 4.60,
          deliveryFee: 5.00,
          total: 55.59,
          status: 'delivered',
          paymentMethod: 'Mobile Money',
          paymentStatus: 'paid',
          deliveryAddress: DeliveryAddressModel.fromMap({
            'fullName': 'John Doe',
            'phoneNumber': '+233123456789',
            'address': '123 Main Street',
            'city': 'Accra',
            'region': 'Greater Accra',
          }),
          orderDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        OrderModel(
          id: 'order_002',
          userId: 'user_002',
          orderNumber: 'EF24010002',
          items: [],
          subtotal: 28.50,
          tax: 2.85,
          deliveryFee: 5.00,
          total: 36.35,
          status: 'pending',
          paymentMethod: 'Card',
          paymentStatus: 'pending',
          deliveryAddress: DeliveryAddressModel.fromMap({
            'fullName': 'Jane Smith',
            'phoneNumber': '+233987654321',
            'address': '456 Oak Avenue',
            'city': 'Kumasi',
            'region': 'Ashanti',
          }),
          orderDate: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      for (final order in sampleOrders) {
        await _firebaseService.firestore
            .collection('orders')
            .doc(order.id)
            .set(order.toMap());
      }
      
      debugPrint('Sample orders initialized successfully');
    } catch (e) {
      debugPrint('Error initializing sample orders: $e');
    }
  }
}
