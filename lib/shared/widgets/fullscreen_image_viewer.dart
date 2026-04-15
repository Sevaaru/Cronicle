import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import 'package:cronicle/shared/widgets/remote_network_image.dart';

void showFullscreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => _FullscreenImageViewer(imageUrl: imageUrl),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({required this.imageUrl});
  final String imageUrl;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _animCtrl;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final pos = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _transformController.value.getMaxScaleOnAxis();

    Matrix4 end;
    if (currentScale > 1.1) {
      end = Matrix4.identity();
    } else {
      // ignore: deprecated_member_use
      end = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-pos.dx * 2, -pos.dy * 2)
        // ignore: deprecated_member_use
        ..scale(3.0);
    }

    _animation = Matrix4Tween(
      begin: _transformController.value,
      end: end,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.forward(from: 0);
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descarga no disponible en web')),
          );
        }
        return;
      }
      final response = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      final result = await ImageGallerySaverPlus.saveImage(bytes, quality: 100);
      if (mounted) {
        final ok = result is Map && result['isSuccess'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Imagen guardada' : 'Error al guardar')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () {
              final scale = _transformController.value.getMaxScaleOnAxis();
              if (scale <= 1.1) Navigator.of(context).pop();
            },
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 5.0,
              clipBehavior: Clip.none,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth.isFinite ? c.maxWidth : 800.0;
                    final h = c.maxHeight.isFinite ? c.maxHeight : 600.0;
                    return RemoteNetworkImage(
                      key: ValueKey(widget.imageUrl),
                      imageUrl: widget.imageUrl,
                      width: w,
                      height: h,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      ),
                      error: const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 26),
                      style: IconButton.styleFrom(backgroundColor: Colors.black45),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (!kIsWeb)
                      IconButton(
                        icon: _saving
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download_rounded, color: Colors.white, size: 26),
                        style: IconButton.styleFrom(backgroundColor: Colors.black45),
                        onPressed: _saveImage,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
