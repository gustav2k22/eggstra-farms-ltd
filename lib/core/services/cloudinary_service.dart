import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  // Cloudinary configuration (provided via --dart-define at build/run time)
  // Example:
  // flutter run \
  //   --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud \
  //   --dart-define=CLOUDINARY_API_KEY=your_key \
  //   --dart-define=CLOUDINARY_API_SECRET=your_secret \
  //   --dart-define=CLOUDINARY_UPLOAD_PRESET=eggstra \
  //   --dart-define=CLOUDINARY_UNSIGNED=true
  static const String _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: 'drczdu4oh');
  static const String _apiKey = String.fromEnvironment('CLOUDINARY_API_KEY', defaultValue: '757639348227263');
  static const String _apiSecret = String.fromEnvironment('CLOUDINARY_API_SECRET', defaultValue: '3-GiSSxN8GnpT39L_rlDqOVi3qY');
  static const String _uploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET', defaultValue: 'eggstra');
  static const String _unsignedFlag = String.fromEnvironment('CLOUDINARY_UNSIGNED', defaultValue: 'true');
  static bool get _isUnsigned => _unsignedFlag.toLowerCase() == 'true' || _apiSecret.isEmpty;
  static String get _uploadUrl => 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image to Cloudinary
  Future<String?> uploadImage({
    required File imageFile,
    required String folder,
    String? publicId,
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Configure fields (signed vs unsigned upload)
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (_isUnsigned) {
        // Unsigned upload: no signature required. Uses upload preset.
        request.fields.addAll({
          'folder': folder,
          if (publicId != null) 'public_id': publicId,
          'resource_type': 'image',
          'upload_preset': _uploadPreset,
        });
      } else {
        // Signed upload: requires api_key, timestamp, signature.
        final signature = _generateSignature(
          timestamp: timestamp,
          folder: folder,
          publicId: publicId,
        );
        request.fields.addAll({
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'folder': folder,
          if (publicId != null) 'public_id': publicId,
          'resource_type': 'image',
          'upload_preset': _uploadPreset,
        });
      }
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        final secureUrl = jsonResponse['secure_url'] as String?;
        debugPrint('Image uploaded successfully: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode} - $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    final uploadedUrls = <String>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(
        imageFile: imageFiles[i],
        folder: folder,
        publicId: '${folder}_${DateTime.now().millisecondsSinceEpoch}_$i',
      );
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateDeleteSignature(
        publicId: publicId,
        timestamp: timestamp,
      );
      
      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'),
        body: {
          'api_key': _apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
          'public_id': publicId,
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['result'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Generate optimized image URL with transformations
  String getOptimizedImageUrl(
    String imageUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!imageUrl.contains('cloudinary.com')) {
      return imageUrl; // Return original if not a Cloudinary URL
    }
    
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    transformations.add('c_fill'); // Crop to fill dimensions
    
    final transformationString = transformations.join(',');
    
    // Insert transformations into Cloudinary URL
    return imageUrl.replaceFirst(
      '/image/upload/',
      '/image/upload/$transformationString/',
    );
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String imageUrl, {int size = 150}) {
    return getOptimizedImageUrl(
      imageUrl,
      width: size,
      height: size,
      quality: 'auto',
    );
  }

  /// Generate signature for upload
  String _generateSignature({
    required int timestamp,
    required String folder,
    String? publicId,
  }) {
    final params = <String, String>{
      'timestamp': timestamp.toString(),
      'folder': folder,
      'upload_preset': 'eggstra',
      if (publicId != null) 'public_id': publicId,
    };
    
    // Sort parameters alphabetically
    final sortedKeys = params.keys.toList()..sort();
    final paramString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');
    
    // Create signature string
    final signatureString = '$paramString$_apiSecret';
    
    // Generate SHA1 hash for Cloudinary signature
    return _sha1Hash(signatureString);
  }

  /// Generate signature for delete
  String _generateDeleteSignature({
    required String publicId,
    required int timestamp,
  }) {
    final signatureString = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    return _sha1Hash(signatureString);
  }

  /// Generate SHA1 hash for Cloudinary signature
  String _sha1Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  /// Check if image URL is from Cloudinary
  bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') || url.contains('res.cloudinary.com');
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicId(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the index of 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }
      
      // Get segments after 'upload' (skip version if present)
      final relevantSegments = pathSegments.sublist(uploadIndex + 1);
      if (relevantSegments.isEmpty) return null;
      
      // Skip version if it starts with 'v'
      final startIndex = relevantSegments[0].startsWith('v') ? 1 : 0;
      if (startIndex >= relevantSegments.length) return null;
      
      // Join remaining segments and remove file extension
      final publicIdWithExt = relevantSegments.sublist(startIndex).join('/');
      final lastDotIndex = publicIdWithExt.lastIndexOf('.');
      
      return lastDotIndex != -1 
          ? publicIdWithExt.substring(0, lastDotIndex)
          : publicIdWithExt;
    } catch (e) {
      debugPrint('Error extracting public ID: $e');
      return null;
    }
  }
}
