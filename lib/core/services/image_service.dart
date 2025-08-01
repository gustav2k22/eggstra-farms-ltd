import 'dart:io';
// dart:typed_data is already provided by flutter/foundation.dart
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_service.dart';

enum ImageType {
  product,
  profile,
  category,
  banner,
}

class ImageUploadResult {
  final bool success;
  final String? imageUrl;
  final String? localPath;
  final String? error;
  final bool isLocal;

  ImageUploadResult({
    required this.success,
    this.imageUrl,
    this.localPath,
    this.error,
    this.isLocal = false,
  });

  String? get displayUrl => imageUrl ?? localPath;
}

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FirebaseService _firebaseService = FirebaseService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Pick image from gallery or camera
  Future<XFile?> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
      );
      
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Pick multiple images
  Future<List<XFile>?> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality ?? 85,
        limit: limit,
      );
      
      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return null;
    }
  }

  // Upload single image with fallback
  Future<ImageUploadResult> uploadImage({
    required XFile imageFile,
    required ImageType imageType,
    required String userId,
    String? productId,
    String? customPath,
  }) async {
    try {
      // First try Firebase Storage
      final firebaseResult = await _uploadToFirebase(
        imageFile: imageFile,
        imageType: imageType,
        userId: userId,
        productId: productId,
        customPath: customPath,
      );

      if (firebaseResult.success) {
        // Log successful Firebase upload
        await _firebaseService.logEvent(
          name: 'image_uploaded_firebase',
          parameters: {
            'image_type': imageType.name,
            'user_id': userId,
            'file_size': await imageFile.length(),
          },
        );
        
        return firebaseResult;
      }

      // Fallback to local storage
      debugPrint('Firebase upload failed, falling back to local storage');
      final localResult = await _saveToLocalStorage(
        imageFile: imageFile,
        imageType: imageType,
        userId: userId,
        productId: productId,
        customPath: customPath,
      );

      if (localResult.success) {
        // Log fallback to local storage
        await _firebaseService.logEvent(
          name: 'image_uploaded_local',
          parameters: {
            'image_type': imageType.name,
            'user_id': userId,
            'fallback_reason': 'firebase_failed',
          },
        );
      }

      return localResult;

    } catch (e) {
      debugPrint('Error uploading image: $e');
      return ImageUploadResult(
        success: false,
        error: 'Failed to upload image: $e',
      );
    }
  }

  // Upload multiple images
  Future<List<ImageUploadResult>> uploadMultipleImages({
    required List<XFile> imageFiles,
    required ImageType imageType,
    required String userId,
    String? productId,
  }) async {
    final results = <ImageUploadResult>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final customPath = productId != null ? '$productId/image_$i' : null;
      final result = await uploadImage(
        imageFile: imageFiles[i],
        imageType: imageType,
        userId: userId,
        productId: productId,
        customPath: customPath,
      );
      results.add(result);
    }
    
    return results;
  }

  // Get image URL (handles both Firebase and local)
  Future<String?> getImageUrl(String imagePath) async {
    try {
      // Check if it's a Firebase URL
      if (imagePath.startsWith('http')) {
        return imagePath;
      }
      
      // Check if it's a local file path
      if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
        final file = File(imagePath.replaceFirst('file://', ''));
        if (await file.exists()) {
          return imagePath;
        }
      }
      
      // Try to get from Firebase Storage
      try {
        final ref = _firebaseService.storage.ref().child(imagePath);
        final url = await ref.getDownloadURL();
        return url;
      } catch (e) {
        debugPrint('Failed to get Firebase URL: $e');
      }
      
      // Try to get from local storage
      final localPath = await _getLocalImagePath(imagePath);
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          return 'file://$localPath';
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting image URL: $e');
      return null;
    }
  }

  // Delete image
  Future<bool> deleteImage(String imagePath) async {
    try {
      bool deleted = false;
      
      // Try to delete from Firebase
      try {
        if (imagePath.startsWith('http')) {
          // Extract path from URL
          final uri = Uri.parse(imagePath);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length > 2) {
            final storagePath = pathSegments.sublist(2).join('/');
            await _firebaseService.storage.ref().child(storagePath).delete();
            deleted = true;
          }
        } else {
          await _firebaseService.storage.ref().child(imagePath).delete();
          deleted = true;
        }
      } catch (e) {
        debugPrint('Failed to delete from Firebase: $e');
      }
      
      // Try to delete from local storage
      final localPath = await _getLocalImagePath(imagePath);
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          deleted = true;
        }
      }
      
      return deleted;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Get cached images for offline use
  Future<List<String>> getCachedImages(ImageType imageType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_images_${imageType.name}';
      return prefs.getStringList(cacheKey) ?? [];
    } catch (e) {
      debugPrint('Error getting cached images: $e');
      return [];
    }
  }

  // Clear image cache
  Future<void> clearImageCache(ImageType? imageType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (imageType != null) {
        final cacheKey = 'cached_images_${imageType.name}';
        await prefs.remove(cacheKey);
      } else {
        // Clear all image caches
        for (final type in ImageType.values) {
          final cacheKey = 'cached_images_${type.name}';
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Private methods

  Future<ImageUploadResult> _uploadToFirebase({
    required XFile imageFile,
    required ImageType imageType,
    required String userId,
    String? productId,
    String? customPath,
  }) async {
    try {
      final fileName = customPath ?? _generateFileName(imageFile.name);
      final storagePath = _getStoragePath(imageType, userId, fileName, productId);
      
      final ref = _firebaseService.storage.ref().child(storagePath);
      
      Uint8List imageData;
      if (kIsWeb) {
        imageData = await imageFile.readAsBytes();
      } else {
        imageData = await File(imageFile.path).readAsBytes();
      }
      
      final uploadTask = ref.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/${path.extension(imageFile.name).substring(1)}',
          customMetadata: {
            'userId': userId,
            'imageType': imageType.name,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Cache the URL locally
      await _cacheImageUrl(imageType, downloadUrl);
      
      return ImageUploadResult(
        success: true,
        imageUrl: downloadUrl,
        isLocal: false,
      );
      
    } catch (e) {
      debugPrint('Firebase upload error: $e');
      return ImageUploadResult(
        success: false,
        error: 'Firebase upload failed: $e',
      );
    }
  }

  Future<ImageUploadResult> _saveToLocalStorage({
    required XFile imageFile,
    required ImageType imageType,
    required String userId,
    String? productId,
    String? customPath,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(appDir.path, 'images', imageType.name));
      
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      
      final fileName = customPath ?? _generateFileName(imageFile.name);
      final localPath = path.join(imageDir.path, fileName);
      
      Uint8List imageData;
      if (kIsWeb) {
        imageData = await imageFile.readAsBytes();
      } else {
        imageData = await File(imageFile.path).readAsBytes();
      }
      
      final localFile = File(localPath);
      await localFile.writeAsBytes(imageData);
      
      // Store path reference
      await _storeLocalImagePath(imageType, fileName, localPath);
      
      // Cache the local path
      await _cacheImageUrl(imageType, 'file://$localPath');
      
      return ImageUploadResult(
        success: true,
        localPath: 'file://$localPath',
        isLocal: true,
      );
      
    } catch (e) {
      debugPrint('Local storage error: $e');
      return ImageUploadResult(
        success: false,
        error: 'Local storage failed: $e',
      );
    }
  }

  String _generateFileName(String originalName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalName);
    return '${timestamp}_${originalName.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}$extension';
  }

  String _getStoragePath(ImageType imageType, String userId, String fileName, String? productId) {
    switch (imageType) {
      case ImageType.product:
        return 'products/${productId ?? 'general'}/$fileName';
      case ImageType.profile:
        return 'profiles/$userId/$fileName';
      case ImageType.category:
        return 'categories/$fileName';
      case ImageType.banner:
        return 'banners/$fileName';
    }
  }

  Future<void> _cacheImageUrl(ImageType imageType, String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_images_${imageType.name}';
      final cachedUrls = prefs.getStringList(cacheKey) ?? [];
      
      if (!cachedUrls.contains(url)) {
        cachedUrls.add(url);
        await prefs.setStringList(cacheKey, cachedUrls);
      }
    } catch (e) {
      debugPrint('Error caching image URL: $e');
    }
  }

  Future<void> _storeLocalImagePath(ImageType imageType, String fileName, String localPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pathKey = 'local_image_${imageType.name}_$fileName';
      await prefs.setString(pathKey, localPath);
    } catch (e) {
      debugPrint('Error storing local image path: $e');
    }
  }

  Future<String?> _getLocalImagePath(String fileName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try all image types
      for (final type in ImageType.values) {
        final pathKey = 'local_image_${type.name}_$fileName';
        final localPath = prefs.getString(pathKey);
        if (localPath != null) {
          return localPath;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting local image path: $e');
      return null;
    }
  }
}
