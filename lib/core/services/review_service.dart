import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/models/review_model.dart';
import 'firebase_service.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Add a new review
  Future<String?> addReview({
    required String productId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      final review = ReviewModel(
        id: '', // Will be set by Firestore
        productId: productId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: false,
        images: images,
      );

      final docRef = await _firebaseService.firestore
          .collection('reviews')
          .add(review.toMap());

      return docRef.id;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return null;
    }
  }

  /// Get reviews for a specific product
  Stream<List<ReviewModel>> getProductReviews(String productId, {int limit = 10}) {
    return _firebaseService.firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromMap(data);
      }).toList();
    });
  }

  /// Get reviews by a specific user
  Stream<List<ReviewModel>> getUserReviews(String userId, {int limit = 20}) {
    return _firebaseService.firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromMap(data);
      }).toList();
    });
  }

  /// Get average rating for a product
  Future<double> getProductAverageRating(String productId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      final ratings = snapshot.docs.map((doc) => doc.data()['rating'] as int).toList();
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      
      return double.parse(average.toStringAsFixed(1));
    } catch (e) {
      debugPrint('Error getting average rating: $e');
      return 0.0;
    }
  }

  /// Get review count for a product
  Future<int> getProductReviewCount(String productId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting review count: $e');
      return 0;
    }
  }

  /// Update a review
  Future<bool> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment;
      if (images != null) updateData['images'] = images;

      await _firebaseService.firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updateData);

      return true;
    } catch (e) {
      debugPrint('Error updating review: $e');
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await _firebaseService.firestore
          .collection('reviews')
          .doc(reviewId)
          .delete();

      return true;
    } catch (e) {
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Check if user has already reviewed a product
  Future<bool> hasUserReviewedProduct(String userId, String productId) async {
    try {
      final snapshot = await _firebaseService.firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user review: $e');
      return false;
    }
  }

  /// Get all reviews (Admin)
  Stream<List<ReviewModel>> getAllReviews({int limit = 50}) {
    return _firebaseService.firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReviewModel.fromMap(data);
      }).toList();
    });
  }

  /// Verify a review (Admin)
  Future<bool> verifyReview(String reviewId) async {
    try {
      await _firebaseService.firestore
          .collection('reviews')
          .doc(reviewId)
          .update({
        'isVerified': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      debugPrint('Error verifying review: $e');
      return false;
    }
  }
}
