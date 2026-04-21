import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Imagen remota con caché (móvil / escritorio).
class RemoteNetworkImage extends StatelessWidget {
  const RemoteNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.maxWidth,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.error,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final double? maxWidth;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, _) =>
          placeholder ??
          SizedBox(
            width: width ?? 200,
            height: height ?? 80,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      errorWidget: (_, _, _) => error ?? const Icon(Icons.broken_image, size: 32),
    );
    if (maxWidth != null) {
      image = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: image,
      );
    }
    return image;
  }
}
