import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';

class EnhancedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholder;
  final Widget? errorWidget;
  final bool showPlaceholder;
  final Color? backgroundColor;
  final double? aspectRatio;

  const EnhancedImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showPlaceholder = true,
    this.backgroundColor,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl == null || imageUrl!.isEmpty) {
      imageWidget = _buildPlaceholder();
    } else if (imageUrl!.startsWith('http')) {
      // Network image (Cloudinary or Firebase Storage URL)
      imageWidget = _buildNetworkImage();
    } else if (imageUrl!.startsWith('file://') || imageUrl!.startsWith('/')) {
      // Local file image - but fallback to placeholder if file doesn't exist
      imageWidget = _buildLocalImageWithFallback();
    } else {
      // Asset image or unknown format
      imageWidget = _buildAssetOrPlaceholder();
    }

    // Wrap with container for styling
    Widget styledWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.inputBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageWidget,
    );

    // Apply aspect ratio if specified
    if (aspectRatio != null) {
      styledWidget = AspectRatio(
        aspectRatio: aspectRatio!,
        child: styledWidget,
      );
    }

    return styledWidget;
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('Error loading network image: $url, Error: $error');
        return _buildErrorWidget();
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  Widget _buildLocalImageWithFallback() {
    final filePath = imageUrl!.startsWith('file://') 
        ? imageUrl!.substring(7) 
        : imageUrl!;
    
    final file = File(filePath);
    
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }
        
        if (snapshot.data == true) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading local image: $filePath, Error: $error');
              return _buildPlaceholder(); // Fallback to placeholder instead of error
            },
          );
        } else {
          debugPrint('Local image file does not exist: $filePath');
          return _buildPlaceholder(); // Fallback to placeholder for missing files
        }
      },
    );
  }

  Widget _buildAssetOrPlaceholder() {
    // Try to load as asset first
    if (imageUrl!.contains('assets/')) {
      return Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    if (!showPlaceholder) {
      return const SizedBox.shrink();
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.inputBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: (width != null && width! < 100) ? 24 : 48,
            color: AppColors.textSecondary,
          ),
          if (placeholder != null) ...[
            const SizedBox(height: 8),
            Text(
              placeholder!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: (width != null && width! < 100) ? 10 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.inputBackground,
      child: Center(
        child: SizedBox(
          width: (width != null && width! < 100) ? 16 : 24,
          height: (width != null && width! < 100) ? 16 : 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }

    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.inputBackground,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (width != null && width! < 100) ? 24 : 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 4),
          Text(
            'Image not found',
            style: TextStyle(
              color: AppColors.error,
              fontSize: (width != null && width! < 100) ? 8 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Specialized widgets for different use cases

class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final bool showBadges;
  final bool isOrganic;
  final bool isFeatured;
  final double? discount;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.showBadges = true,
    this.isOrganic = false,
    this.isFeatured = false,
    this.discount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EnhancedImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          fit: BoxFit.cover,
          placeholder: 'Product Image',
          borderRadius: BorderRadius.circular(12),
        ),
        if (showBadges) ..._buildBadges(),
      ],
    );
  }

  List<Widget> _buildBadges() {
    final badges = <Widget>[];

    // Organic badge
    if (isOrganic) {
      badges.add(
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'ORGANIC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    // Featured badge
    if (isFeatured) {
      badges.add(
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      );
    }

    // Discount badge
    if (discount != null && discount! > 0) {
      badges.add(
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${discount!.toInt()}% OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return badges;
  }
}

class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showEditIcon;
  final VoidCallback? onEditTap;
  final String? initials;

  const ProfileImage({
    super.key,
    this.imageUrl,
    this.size = 80,
    this.showEditIcon = false,
    this.onEditTap,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? EnhancedImage(
                    imageUrl: imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    showPlaceholder: false,
                    borderRadius: BorderRadius.circular(size / 2),
                  )
                : _buildInitialsPlaceholder(),
          ),
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: size * 0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials ?? '?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: size * 0.3,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
