import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

class CartItemModel {
  final String id;
  final String productId;
  final ProductModel product;
  final int quantity;
  final double unitPrice;
  final DateTime addedAt;
  final Map<String, dynamic>? customOptions;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.addedAt,
    this.customOptions,
  });

  double get totalPrice => unitPrice * quantity;

  double get discountedTotalPrice => product.discountedPrice * quantity;

  double get savings => totalPrice - discountedTotalPrice;

  bool get hasDiscount => product.hasDiscount;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      product: ProductModel.fromMap(map['product'] ?? {}),
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      addedAt: map['addedAt'] is Timestamp 
          ? (map['addedAt'] as Timestamp).toDate()
          : DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
      customOptions: map['customOptions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'product': product.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'addedAt': Timestamp.fromDate(addedAt),
      'customOptions': customOptions,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    ProductModel? product,
    int? quantity,
    double? unitPrice,
    DateTime? addedAt,
    Map<String, dynamic>? customOptions,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      addedAt: addedAt ?? this.addedAt,
      customOptions: customOptions ?? this.customOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItemModel(id: $id, productId: $productId, quantity: $quantity, totalPrice: $totalPrice)';
  }
}

class CartModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? couponCode;
  final double? couponDiscount;
  final double tax;
  final double deliveryFee;

  CartModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.couponCode,
    this.couponDiscount,
    this.tax = 0.0,
    this.deliveryFee = 0.0,
  });

  int get totalItems => items.fold(0, (accumulated, item) => accumulated + item.quantity);

  double get subtotal => items.fold(0.0, (accumulated, item) => accumulated + item.discountedTotalPrice);

  double get originalSubtotal => items.fold(0.0, (accumulated, item) => accumulated + item.totalPrice);

  double get productSavings => originalSubtotal - subtotal;

  double get couponSavings => couponDiscount ?? 0.0;

  double get totalSavings => productSavings + couponSavings;

  double get total => subtotal - couponSavings;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  bool get hasCoupon => couponCode != null && couponCode!.isNotEmpty;

  CartItemModel? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasProduct(String productId) {
    return items.any((item) => item.productId == productId);
  }

  int getProductQuantity(String productId) {
    final item = getItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CartModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>?)
          ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      couponCode: data['couponCode'],
      couponDiscount: data['couponDiscount']?.toDouble(),
    );
  }

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      couponCode: map['couponCode'],
      couponDiscount: map['couponDiscount']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'couponCode': couponCode,
      'couponDiscount': couponDiscount,
    };
  }

  CartModel copyWith({
    String? id,
    String? userId,
    List<CartItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? couponCode,
    double? couponDiscount,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      couponCode: couponCode ?? this.couponCode,
      couponDiscount: couponDiscount ?? this.couponDiscount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartModel(id: $id, userId: $userId, totalItems: $totalItems, total: $total)';
  }
}
