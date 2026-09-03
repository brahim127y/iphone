import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double iconSize;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _placeholder();
    }

    final url = imageUrl!.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    // Local file path
    final cleanPath = url.startsWith('file://') ? url.substring(7) : url;
    final file = File(cleanPath);

    return Image.file(
      file,
      height: height,
      width: width,
      fit: fit,
      cacheWidth: width != null && width! > 0 && width! != double.infinity ? (width! * 2).toInt() : 400,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }


  Widget _placeholder() {
    return Container(
      height: height,
      width: width ?? double.infinity,
      color: AppColors.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          color: AppColors.textMuted,
          size: iconSize,
        ),
      ),
    );
  }
}
