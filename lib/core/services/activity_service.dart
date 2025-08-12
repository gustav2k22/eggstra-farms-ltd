import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import 'firebase_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Log a new activity to Firebase
  Future<void> logActivity({
    required ActivityType type,
    required String title,
    required String description,
    String? userId,
    String? orderId,
    String? productId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = ActivityModel(
        id: '', // Will be set by Firestore
        type: type,
        title: title,
        description: description,
        userId: userId,
        orderId: orderId,
        productId: productId,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
      );

      await _firebaseService.firestore
          .collection('activities')
          .add(activity.toMap());
    } catch (e) {
      debugPrint('Error logging activity: $e');
    }
  }

  /// Get recent activities stream for admin dashboard
  Stream<List<ActivityModel>> getRecentActivitiesStream({int limit = 10}) {
    return _firebaseService.firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }).toList();
    });
  }

  /// Get activities for a specific user
  Stream<List<ActivityModel>> getUserActivitiesStream(String userId, {int limit = 20}) {
    return _firebaseService.firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }).toList();
    });
  }

  /// Get activities by type
  Stream<List<ActivityModel>> getActivitiesByTypeStream(ActivityType type, {int limit = 20}) {
    return _firebaseService.firestore
        .collection('activities')
        .where('type', isEqualTo: type.name)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ActivityModel.fromMap(data);
      }).toList();
    });
  }

  /// Log order-related activities
  Future<void> logOrderActivity(String orderId, String userId, OrderActivityType activityType, {Map<String, dynamic>? metadata}) async {
    String title;
    String description;
    ActivityType type = ActivityType.order;

    switch (activityType) {
      case OrderActivityType.created:
        title = 'New order received';
        description = 'Order #${orderId.substring(orderId.length - 6).toUpperCase()} was placed';
        break;
      case OrderActivityType.confirmed:
        title = 'Order confirmed';
        description = 'Order #${orderId.substring(orderId.length - 6).toUpperCase()} was confirmed';
        break;
      case OrderActivityType.shipped:
        title = 'Order shipped';
        description = 'Order #${orderId.substring(orderId.length - 6).toUpperCase()} is on the way';
        break;
      case OrderActivityType.delivered:
        title = 'Order delivered';
        description = 'Order #${orderId.substring(orderId.length - 6).toUpperCase()} delivered successfully';
        break;
      case OrderActivityType.cancelled:
        title = 'Order cancelled';
        description = 'Order #${orderId.substring(orderId.length - 6).toUpperCase()} was cancelled';
        break;
    }

    await logActivity(
      type: type,
      title: title,
      description: description,
      userId: userId,
      orderId: orderId,
      metadata: metadata,
    );
  }

  /// Log user-related activities
  Future<void> logUserActivity(String userId, UserActivityType activityType, {Map<String, dynamic>? metadata}) async {
    String title;
    String description;
    ActivityType type = ActivityType.user;

    switch (activityType) {
      case UserActivityType.registered:
        title = 'New user registered';
        description = 'A new user joined Eggstra Farms';
        break;
      case UserActivityType.profileUpdated:
        title = 'Profile updated';
        description = 'User updated their profile information';
        break;
      case UserActivityType.passwordChanged:
        title = 'Password changed';
        description = 'User changed their password';
        break;
    }

    await logActivity(
      type: type,
      title: title,
      description: description,
      userId: userId,
      metadata: metadata,
    );
  }

  /// Log product-related activities
  Future<void> logProductActivity(String productId, ProductActivityType activityType, {String? userId, Map<String, dynamic>? metadata}) async {
    String title;
    String description;
    ActivityType type = ActivityType.product;

    switch (activityType) {
      case ProductActivityType.created:
        title = 'New product added';
        description = 'A new product was added to the catalog';
        break;
      case ProductActivityType.updated:
        title = 'Product updated';
        description = 'Product information was updated';
        break;
      case ProductActivityType.stockUpdated:
        title = 'Product stock updated';
        description = 'Product stock levels were updated';
        break;
      case ProductActivityType.deleted:
        title = 'Product removed';
        description = 'A product was removed from the catalog';
        break;
    }

    await logActivity(
      type: type,
      title: title,
      description: description,
      userId: userId,
      productId: productId,
      metadata: metadata,
    );
  }
}

enum ActivityType {
  order,
  user,
  product,
  system,
}

enum OrderActivityType {
  created,
  confirmed,
  shipped,
  delivered,
  cancelled,
}

enum UserActivityType {
  registered,
  profileUpdated,
  passwordChanged,
}

enum ProductActivityType {
  created,
  updated,
  stockUpdated,
  deleted,
}
