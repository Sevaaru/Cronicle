// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

String _objectFit(BoxFit fit) => switch (fit) {
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'contain',
      BoxFit.fitHeight => 'contain',
      BoxFit.scaleDown => 'scale-down',
      _ => 'contain',
    };

/// En web usa `<img>` nativo vía [HtmlElementView], evitando CORS de CanvasKit/Skwasm.
class RemoteNetworkImage extends StatefulWidget {
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
  State<RemoteNetworkImage> createState() => _RemoteNetworkImageState();
}

class _RemoteNetworkImageState extends State<RemoteNetworkImage> {
  static int _seq = 0;
  late final String _viewType = 'cronicle_remote_img_${_seq++}';
  bool _failed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final url = widget.imageUrl;
    final w = widget.width;
    final h = widget.height;
    final objectFit = _objectFit(widget.fit);

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.border = 'none'
        ..style.objectFit = objectFit;
      if (w != null) {
        img.style.width = '${w.toInt()}px';
      } else {
        img.style.width = '100%';
        img.style.maxWidth = '100vw';
      }
      if (widget.maxWidth != null) {
        img.style.maxWidth = '${widget.maxWidth!.toInt()}px';
      }
      if (h != null) {
        img.style.height = '${h.toInt()}px';
      } else {
        img.style.height = 'auto';
        img.style.maxHeight = '100dvh';
      }
      img.onLoad.listen((_) {
        if (mounted) setState(() => _loaded = true);
      });
      img.onError.listen((_) {
        if (mounted) setState(() => _failed = true);
      });
      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.error ??
          const Icon(Icons.broken_image, size: 32, color: Colors.grey);
    }
    Widget view = HtmlElementView(viewType: _viewType);
    if (widget.width != null && widget.height != null) {
      view = SizedBox(width: widget.width, height: widget.height, child: view);
    } else if (widget.width != null) {
      final side = widget.width!;
      view = SizedBox(width: side, height: side, child: view);
    } else if (widget.height != null) {
      final side = widget.height!;
      view = SizedBox(width: side, height: side, child: view);
    }

    if (widget.placeholder != null && !_loaded) {
      return Stack(
        alignment: Alignment.center,
        children: [
          view,
          IgnorePointer(child: widget.placeholder!),
        ],
      );
    }
    return view;
  }
}
