import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/product_model.dart';
import 'cloudinary_service.dart';
import 'product_service.dart';

/// Service to migrate local file images to Cloudinary
class ImageMigrationService {
  static final ImageMigrationService _instance = ImageMigrationService._internal();
  factory ImageMigrationService() => _instance;
  ImageMigrationService._internal();

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ProductService _productService = ProductService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate all product images from local files to Cloudinary
  Future<Map<String, dynamic>> migrateProductImages() async {
    final results = {
      'total': 0,
      'success': 0,
      'failed': 0,
      'skipped': 0,
      'products': <Map<String, dynamic>>[],
    };
    
    // Initialize product results list outside try block for proper scope
    List<Map<String, dynamic>> productResults = [];

    try {
      // Get all products
      final querySnapshot = await _firestore.collection('products').get();
      results['total'] = querySnapshot.docs.length;
      
      for (final doc in querySnapshot.docs) {
        try {
          final product = ProductModel.fromFirestore(doc);
          final productResult = <String, dynamic>{
            'id': product.id,
            'name': product.name,
            'status': 'skipped',
            'reason': 'No local images found',
          };

          // Check if product has any local file paths
          final localImageUrls = product.imageUrls
              .where((url) => url.startsWith('file://') || 
                             (url.startsWith('/') && !url.startsWith('http')))
              .toList();
          
          if (localImageUrls.isEmpty) {
            results['skipped'] = (results['skipped'] as int) + 1;
            productResult['status'] = 'skipped';
            productResults.add(productResult);
            continue;
          }

          // Process each local image
          final newImageUrls = [...product.imageUrls];
          final migratedUrls = <String>[];
          
          for (int i = 0; i < product.imageUrls.length; i++) {
            final url = product.imageUrls[i];
            
            if (url.startsWith('http')) {
              // Skip URLs that are already on Cloudinary or other web hosts
              continue;
            }
            
            try {
              // For local files, try to upload to Cloudinary
              final tempFile = await _createTempFileFromLocalPath(url);
              if (tempFile != null) {
                final cloudinaryUrl = await _cloudinaryService.uploadImage(
                  imageFile: tempFile,
                  folder: 'products',
                  publicId: 'product_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
                );
                
                if (cloudinaryUrl != null) {
                  newImageUrls[i] = cloudinaryUrl;
                  migratedUrls.add('$url -> $cloudinaryUrl');
                  debugPrint('✅ Migrated image for ${product.name}: $cloudinaryUrl');
                } else {
                  debugPrint('Failed to upload image to Cloudinary');
                  debugPrint('❌ Failed to upload image to Cloudinary: $url');
                }
                
                // Clean up temp file
                if (tempFile.existsSync()) {
                  await tempFile.delete();
                }
              } else {
                debugPrint('❌ Could not create temp file from: $url');
              }
            } catch (e) {
              debugPrint('❌ Error processing image $url: $e');
            }
          }
          
          // Update product if any images were migrated
          if (newImageUrls.join() != product.imageUrls.join()) {
            final updatedProduct = product.copyWith(imageUrls: newImageUrls);
            final updateSuccess = await _productService.updateProduct(updatedProduct);
            
            if (updateSuccess) {
              results['success'] = (results['success'] as int) + 1;
              productResult['status'] = 'success';
              productResult['migrated_urls'] = migratedUrls;
            } else {
              results['failed'] = (results['failed'] as int) + 1;
              productResult['status'] = 'failed';
              productResult['reason'] = 'Failed to update product';
            }
          } else {
            results['skipped'] = (results['skipped'] as int) + 1;
            productResult['status'] = 'skipped';
            productResult['reason'] = 'No changes needed';
          }
          
          productResults.add(productResult);
          
        } catch (e) {
          debugPrint('❌ Error processing product ${doc.id}: $e');
          results['failed'] = (results['failed'] as int) + 1;
          productResults.add({
            'id': doc.id,
            'status': 'failed',
            'reason': 'Error: ${e.toString()}',
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error migrating product images: $e');
      return {
        'success': false,
        'message': 'Failed to migrate images: ${e.toString()}',
      };
    }
    
    // Make sure we have our results before returning
    results['products'] = productResults;
    
    return {
      'success': true,
      'message': 'Migration completed',
      'results': results,
    };
  }

  /// Create a temporary file from a local file path
  Future<File?> _createTempFileFromLocalPath(String localPath) async {
    try {
      // Clean up the path for proper file access
      String path;
      if (localPath.startsWith('file:///')) {
        path = localPath.substring(8); // Remove 'file:///' prefix (8 chars)
      } else if (localPath.startsWith('file://')) {
        path = localPath.substring(7); // Remove 'file://' prefix (7 chars)
      } else {
        path = localPath;
      }
      
      // Check if the source file exists
      final sourceFile = File(path);
      if (!await sourceFile.exists()) {
        debugPrint('❌ Source file does not exist: $path');
        return null;
      }

      // Create a temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/migration_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      
      // Copy the contents
      await sourceFile.copy(tempFile.path);
      return tempFile;
    } catch (e) {
      debugPrint('❌ Error creating temp file: $e');
      return null;
    }
  }
}
