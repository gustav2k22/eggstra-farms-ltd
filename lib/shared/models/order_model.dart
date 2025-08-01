import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_model.dart';
import 'user_model.dart';

class DeliveryAddressModel {
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String region;
  final String? landmark;
  final bool isDefault;

  DeliveryAddressModel({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.region,
    this.landmark,
    this.isDefault = false,
  });

  factory DeliveryAddressModel.fromMap(Map<String, dynamic> map) {
    return DeliveryAddressModel(
      fullName: map['fullName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      region: map['region'] ?? '',
      landmark: map['landmark'],
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'address': address,
      'city': city,
      'region': region,
      'landmark': landmark,
      'isDefault': isDefault,
    };
  }

  @override
  String toString() {
    return '$address, $city, $region';
  }
}

class OrderItemModel {
  final String productId;
  final String productName;
  final String productImageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String unit;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.unit,
  });

  factory OrderItemModel.fromCartItem(CartItemModel cartItem) {
    return OrderItemModel(
      productId: cartItem.productId,
      productName: cartItem.product.name,
      productImageUrl: cartItem.product.imageUrls.isNotEmpty 
          ? cartItem.product.imageUrls.first 
          : '',
      quantity: cartItem.quantity,
      unitPrice: cartItem.product.discountedPrice,
      totalPrice: cartItem.discountedTotalPrice,
      unit: cartItem.product.unit,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'piece',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'unit': unit,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final UserModel? user;
  final String orderNumber;
  final List<OrderItemModel> items;
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final DeliveryAddressModel deliveryAddress;
  final DateTime orderDate;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final String? notes;
  final String? trackingNumber;
  final List<OrderStatusUpdate>? statusUpdates;

  OrderModel({
    required this.id,
    required this.userId,
    this.user,
    required this.orderNumber,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.deliveryAddress,
    required this.orderDate,
    DateTime? createdAt,
    this.estimatedDeliveryDate,
    this.actualDeliveryDate,
    this.notes,
    this.trackingNumber,
    this.statusUpdates,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalItems => items.fold(0, (accumulated, item) => accumulated + item.quantity);

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isProcessing => status == 'processing';
  bool get isShipped => status == 'shipped';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';

  bool get isPaymentPending => paymentStatus == 'pending';
  bool get isPaymentCompleted => paymentStatus == 'completed';
  bool get isPaymentFailed => paymentStatus == 'failed';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Order Pending';
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get paymentStatusDisplayText {
    switch (paymentStatus) {
      case 'pending':
        return 'Payment Pending';
      case 'completed':
        return 'Payment Completed';
      case 'failed':
        return 'Payment Failed';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown';
    }
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      user: data['user'] != null ? UserModel.fromMap(data['user']) : null,
      orderNumber: data['orderNumber'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      tax: (data['tax'] ?? 0.0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0.0).toDouble(),
      discount: (data['discount'] ?? 0.0).toDouble(),
      total: (data['total'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? '',
      deliveryAddress: DeliveryAddressModel.fromMap(data['deliveryAddress'] ?? {}),
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedDeliveryDate: (data['estimatedDeliveryDate'] as Timestamp?)?.toDate(),
      actualDeliveryDate: (data['actualDeliveryDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      trackingNumber: data['trackingNumber'],
      statusUpdates: (data['statusUpdates'] as List<dynamic>?)
          ?.map((update) => OrderStatusUpdate.fromMap(update as Map<String, dynamic>))
          .toList(),
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      user: map['user'] != null ? UserModel.fromMap(map['user']) : null,
      orderNumber: map['orderNumber'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      total: (map['total'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      deliveryAddress: DeliveryAddressModel.fromMap(map['deliveryAddress'] ?? {}),
      orderDate: map['orderDate'] is Timestamp 
          ? (map['orderDate'] as Timestamp).toDate()
          : DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      estimatedDeliveryDate: map['estimatedDeliveryDate'] is Timestamp 
          ? (map['estimatedDeliveryDate'] as Timestamp).toDate()
          : map['estimatedDeliveryDate'] != null ? DateTime.parse(map['estimatedDeliveryDate']) : null,
      actualDeliveryDate: map['actualDeliveryDate'] is Timestamp 
          ? (map['actualDeliveryDate'] as Timestamp).toDate()
          : map['actualDeliveryDate'] != null ? DateTime.parse(map['actualDeliveryDate']) : null,
      notes: map['notes'],
      trackingNumber: map['trackingNumber'],
      statusUpdates: (map['statusUpdates'] as List<dynamic>?)
          ?.map((update) => OrderStatusUpdate.fromMap(update as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'user': user?.toMap(),
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'deliveryAddress': deliveryAddress.toMap(),
      'orderDate': Timestamp.fromDate(orderDate),
      'estimatedDeliveryDate': estimatedDeliveryDate != null 
          ? Timestamp.fromDate(estimatedDeliveryDate!) : null,
      'actualDeliveryDate': actualDeliveryDate != null 
          ? Timestamp.fromDate(actualDeliveryDate!) : null,
      'notes': notes,
      'trackingNumber': trackingNumber,
      'statusUpdates': statusUpdates?.map((update) => update.toMap()).toList(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    String? orderNumber,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    String? status,
    String? paymentStatus,
    String? paymentMethod,
    DeliveryAddressModel? deliveryAddress,
    DateTime? orderDate,
    DateTime? estimatedDeliveryDate,
    DateTime? actualDeliveryDate,
    String? notes,
    String? trackingNumber,
    List<OrderStatusUpdate>? statusUpdates,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      orderDate: orderDate ?? this.orderDate,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
      notes: notes ?? this.notes,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      statusUpdates: statusUpdates ?? this.statusUpdates,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrderModel(id: $id, orderNumber: $orderNumber, status: $status, total: $total)';
  }
}

class OrderStatusUpdate {
  final String status;
  final String message;
  final DateTime timestamp;
  final String? updatedBy;

  OrderStatusUpdate({
    required this.status,
    required this.message,
    required this.timestamp,
    this.updatedBy,
  });

  factory OrderStatusUpdate.fromMap(Map<String, dynamic> map) {
    return OrderStatusUpdate(
      status: map['status'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] is Timestamp 
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
    };
  }
}
