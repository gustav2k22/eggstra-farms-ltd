import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/image_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final ImageType imageType;
  final String userId;
  final String? productId;
  final Function(ImageUploadResult) onImageSelected;
  final String? currentImageUrl;
  final bool isCircular;
  final double size;
  final IconData icon;
  final String title;

  const ImagePickerWidget({
    Key? key,
    required this.imageType,
    required this.userId,
    required this.onImageSelected,
    this.productId,
    this.currentImageUrl,
    this.isCircular = false,
    this.size = 120.0,
    this.icon = Icons.add_photo_alternate,
    this.title = 'Add Image',
  }) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImageService _imageService = ImageService();
  bool _isLoading = false;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.currentImageUrl;
  }

  @override
  void didUpdateWidget(covariant ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentImageUrl != oldWidget.currentImageUrl) {
      setState(() {
        _imageUrl = widget.currentImageUrl;
      });
    }
  }

  Future<void> _showImageSourceSheet() async {
    final result = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSourceOption(
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a new photo',
              color: AppColors.primary,
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            _buildDivider(),
            _buildSourceOption(
              icon: Icons.photo_library_rounded,
              title: 'Gallery',
              subtitle: 'Choose from your photos',
              color: AppColors.secondary,
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_imageUrl != null) ...[
              _buildDivider(),
              _buildSourceOption(
                icon: Icons.delete_outline_rounded,
                title: 'Remove',
                subtitle: 'Remove current image',
                color: Colors.red,
                onTap: () => Navigator.pop(context, null),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      if (mounted) {
        _pickImage(result);
      }
    } else if (result == null && _imageUrl != null) {
      // User chose to remove the image
      setState(() {
        _imageUrl = null;
      });
      widget.onImageSelected(ImageUploadResult(
        success: true,
        imageUrl: null,
        isLocal: false,
      ));
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final image = await _imageService.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final result = await _imageService.uploadImage(
          imageFile: image,
          imageType: widget.imageType,
          userId: widget.userId,
          productId: widget.productId,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (result.success) {
              _imageUrl = result.displayUrl;
            }
          });

          widget.onImageSelected(result);

          if (!result.success) {
            _showErrorMessage('Failed to upload image: ${result.error}');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Error selecting image: $e');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _showImageSourceSheet,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: widget.isCircular ? null : BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildImageContent(),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_imageUrl != null) {
      return ClipRRect(
        borderRadius: widget.isCircular 
            ? BorderRadius.circular(widget.size / 2)
            : BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: _buildImage(_imageUrl!),
            ),
            // Edit overlay
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.edit, size: 16, color: AppColors.secondary),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.icon,
            size: widget.size / 3,
            color: AppColors.textSecondary.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      // Network image
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image,
              size: widget.size / 3,
              color: Colors.red[300],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else if (url.startsWith('file://')) {
      // Local file
      if (kIsWeb) {
        return Center(
          child: Text(
            'Local File\n(Not visible on web)',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        );
      } else {
        return Image.file(
          File(url.replaceFirst('file://', '')),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.broken_image,
                size: widget.size / 3,
                color: Colors.red[300],
              ),
            );
          },
        );
      }
    } else {
      // Asset image
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image,
              size: widget.size / 3,
              color: Colors.red[300],
            ),
          );
        },
      );
    }
  }
}
