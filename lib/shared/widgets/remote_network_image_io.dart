import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final double? maxWidth;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? error;

  /// Decoded width hint in physical pixels. If null, auto-derived from
  /// [width] / [maxWidth] × devicePixelRatio. Pass an explicit value
  /// when the layout size is known but the image needs sharper decoding
  /// (e.g. high-DPI poster art).
  final int? memCacheWidth;

  /// Decoded height hint in physical pixels. If null, auto-derived from
  /// [height] × devicePixelRatio.
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    // Auto-derive decode size from layout size + DPR. This caps memory
    // usage to what the image will actually be drawn at, avoiding huge
    // 4K decodes for thumbnails which is the #1 source of scroll jank.
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final w = memCacheWidth ??
        ((width ?? maxWidth)?.let((v) => (v * dpr).round()));
    final h = memCacheHeight ?? height?.let((v) => (v * dpr).round());

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: w,
      memCacheHeight: h,
      maxWidthDiskCache: w == null ? null : w * 2,
      maxHeightDiskCache: h == null ? null : h * 2,
      fadeInDuration: const Duration(milliseconds: 120),
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

extension _NumLet<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
