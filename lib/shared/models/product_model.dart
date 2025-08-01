import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final String unit; // e.g., 'kg', 'piece', 'dozen', 'liter'
  final int stockQuantity;
  final bool isAvailable;
  final bool isFeatured;
  final bool isOrganic;
  final double? discount; // percentage discount
  final double? weight; // in kg
  final Map<String, dynamic>? nutritionInfo;
  final List<String>? tags;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? farmLocation;
  final DateTime? harvestDate;
  final DateTime? expiryDate;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    required this.unit,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.isFeatured = false,
    this.isOrganic = false,
    this.discount,
    this.weight,
    this.nutritionInfo,
    this.tags,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.farmLocation,
    this.harvestDate,
    this.expiryDate,
  });

  double get discountedPrice {
    if (discount != null && discount! > 0) {
      return price * (1 - discount! / 100);
    }
    return price;
  }

  // Alias for discountedPrice for compatibility
  double get finalPrice => discountedPrice;

  // Get first image URL for compatibility
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  bool get hasDiscount => discount != null && discount! > 0;

  bool get isInStock => stockQuantity > 0;

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());

  String get displayPrice {
    if (hasDiscount) {
      return '₵${discountedPrice.toStringAsFixed(2)}';
    }
    return '₵${price.toStringAsFixed(2)}';
  }

  String get originalPrice {
    return '₵${price.toStringAsFixed(2)}';
  }

  String get stockStatus {
    if (!isAvailable) return 'Unavailable';
    if (stockQuantity == 0) return 'Out of Stock';
    if (stockQuantity < 10) return 'Low Stock';
    return 'In Stock';
  }

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      category: data['category'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      unit: data['unit'] ?? 'piece',
      stockQuantity: data['stockQuantity'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isOrganic: data['isOrganic'] ?? false,
      discount: data['discount']?.toDouble(),
      weight: data['weight']?.toDouble(),
      nutritionInfo: data['nutritionInfo'] as Map<String, dynamic>?,
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      farmLocation: data['farmLocation'],
      harvestDate: (data['harvestDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      unit: map['unit'] ?? 'piece',
      stockQuantity: map['stockQuantity'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      isOrganic: map['isOrganic'] ?? false,
      discount: map['discount']?.toDouble(),
      weight: map['weight']?.toDouble(),
      nutritionInfo: map['nutritionInfo'] as Map<String, dynamic>?,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updatedAt'] is Timestamp 
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
      farmLocation: map['farmLocation'],
      harvestDate: map['harvestDate'] is Timestamp 
          ? (map['harvestDate'] as Timestamp).toDate()
          : map['harvestDate'] != null ? DateTime.parse(map['harvestDate']) : null,
      expiryDate: map['expiryDate'] is Timestamp 
          ? (map['expiryDate'] as Timestamp).toDate()
          : map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'unit': unit,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isOrganic': isOrganic,
      'discount': discount,
      'weight': weight,
      'nutritionInfo': nutritionInfo,
      'tags': tags,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'farmLocation': farmLocation,
      'harvestDate': harvestDate != null ? Timestamp.fromDate(harvestDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    List<String>? imageUrls,
    String? unit,
    int? stockQuantity,
    bool? isAvailable,
    bool? isFeatured,
    bool? isOrganic,
    double? discount,
    double? weight,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? farmLocation,
    DateTime? harvestDate,
    DateTime? expiryDate,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrls: imageUrls ?? this.imageUrls,
      unit: unit ?? this.unit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isOrganic: isOrganic ?? this.isOrganic,
      discount: discount ?? this.discount,
      weight: weight ?? this.weight,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmLocation: farmLocation ?? this.farmLocation,
      harvestDate: harvestDate ?? this.harvestDate,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, category: $category)';
  }
}
