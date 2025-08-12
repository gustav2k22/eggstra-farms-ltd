import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/activity_service.dart';

class ActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? userId;
  final String? orderId;
  final String? productId;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.userId,
    this.orderId,
    this.productId,
    required this.metadata,
    required this.timestamp,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ActivityType.system,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'],
      orderId: map['orderId'],
      productId: map['productId'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'userId': userId,
      'orderId': orderId,
      'productId': productId,
      'metadata': metadata,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Get a human-readable time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get icon based on activity type
  String get iconName {
    switch (type) {
      case ActivityType.order:
        return 'shopping_cart';
      case ActivityType.user:
        return 'person_add';
      case ActivityType.product:
        return 'inventory';
      case ActivityType.system:
        return 'settings';
    }
  }

  /// Get color based on activity type
  String get colorName {
    switch (type) {
      case ActivityType.order:
        return 'primary';
      case ActivityType.user:
        return 'success';
      case ActivityType.product:
        return 'info';
      case ActivityType.system:
        return 'secondary';
    }
  }

  ActivityModel copyWith({
    String? id,
    ActivityType? type,
    String? title,
    String? description,
    String? userId,
    String? orderId,
    String? productId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'ActivityModel(id: $id, type: $type, title: $title, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
