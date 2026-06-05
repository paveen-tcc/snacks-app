import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../design/app_theme.dart';

/// Helper to rewrite Unsplash image URLs to request a specific size
String optimizeImageUrl(String url, int width) {
  if (url.startsWith('https://images.unsplash.com/')) {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['w'] = width.toString();
      queryParams['fit'] = 'crop';
      queryParams['auto'] = 'format';
      queryParams['q'] = '80';
      return uri.replace(queryParameters: queryParams).toString();
    } catch (_) {
      return url;
    }
  }
  return url;
}

class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.fit = BoxFit.cover,
    required this.fallbackIcon,
    this.borderRadius,
  });

  final String imageUrl;
  final double width;
  final double height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BoxFit fit;
  final Widget fallbackIcon;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // Request a URL width that is double the memory cache width or pixel width to account for retina displays
    final targetUrlWidth = memCacheWidth != null ? memCacheWidth! * 2 : (width * 2).toInt();
    final optimizedUrl = optimizeImageUrl(imageUrl, targetUrlWidth);

    // Use the original URL as cache key so resized variants share one cache entry
    final imageWidget = CachedNetworkImage(
      imageUrl: optimizedUrl,
      cacheKey: imageUrl,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      useOldImageOnUrlChange: true,
      placeholder: (context, url) => Container(
        color: palette.surfaceMuted,
        alignment: Alignment.center,
        child: SizedBox(
          width: width * 0.4,
          height: height * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(palette.brand.withValues(alpha: 0.5)),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: palette.surfaceMuted,
        alignment: Alignment.center,
        child: fallbackIcon,
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
