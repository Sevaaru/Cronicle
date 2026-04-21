import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cronicle/core/media/gallery_save_permissions.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void showFullscreenImage(BuildContext context, String imageUrl) {
  context.push('/full-image', extra: imageUrl);
}

class FullscreenImagePage extends StatelessWidget {
  const FullscreenImagePage({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) =>
      _FullscreenImageViewer(imageUrl: imageUrl);
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({required this.imageUrl});
  final String imageUrl;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with TickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _zoomAnimCtrl;
  late final AnimationController _dismissAnimCtrl;
  late final AnimationController _snapBackCtrl;
  Offset _snapBackStart = Offset.zero;
  Animation<Matrix4>? _zoomMatrixAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _saving = false;

  bool _popped = false;

  Offset _dragOffset = Offset.zero;

  double _dragGestureScale = 1;

  Offset _dismissAnimStart = Offset.zero;
  Offset _dismissAnimEnd = Offset.zero;
  double _dismissScaleStart = 1;
  double _dismissScaleEnd = 0.14;
  bool _runningDismissAnimation = false;

  static const _zoomThreshold = 1.04;
  static const _dismissDistance = 110.0;
  static const _dismissVelocity = 700.0;

  final Set<int> _activePointerIds = {};

  @override
  void initState() {
    super.initState();
    _zoomAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomMatrixAnimation != null) {
          _transformController.value = _zoomMatrixAnimation!.value;
        }
      });

    _dismissAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        if (!_runningDismissAnimation) return;
        final raw = _dismissAnimCtrl.value;
        final tMove = Curves.easeInCubic.transform(raw);
        final tScale = Curves.easeIn.transform(math.min(1, raw * 1.15));
        setState(() {
          _dragOffset = Offset.lerp(
            _dismissAnimStart,
            _dismissAnimEnd,
            tMove,
          )!;
          _dragGestureScale = (_dismissScaleStart +
              (_dismissScaleEnd - _dismissScaleStart) * tScale)
            .clamp(0.08, 1.0);
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _runningDismissAnimation) {
          _runningDismissAnimation = false;
          _safePop();
        }
      });

    _snapBackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        if (!mounted) return;
        final t = Curves.easeOutCubic.transform(_snapBackCtrl.value);
        setState(() {
          _dragOffset = Offset.lerp(_snapBackStart, Offset.zero, t)!;
        });
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _enterImmersive());
  }

  void _enterImmersive() {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.light,
          ),
        );
        break;
      default:
        break;
    }
  }

  void _restoreSystemUi() {
    if (kIsWeb) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  void _safePop() {
    if (_popped || !mounted) return;
    _popped = true;
    if (context.canPop()) context.pop();
  }

  double get _scale => _transformController.value.getMaxScaleOnAxis();

  double _backgroundOpacity() {
    final sz = MediaQuery.sizeOf(context);
    final ref = math.max(140.0, math.max(sz.width, sz.height) * 0.32);
    if (ref <= 0) return 1;
    final t = (_dragOffset.distance / ref).clamp(0.0, 1.0);
    final progress = Curves.easeOut.transform(t);
    return (1.0 - progress).clamp(0.0, 1.0);
  }

  double _liveDragScale() {
    if (_runningDismissAnimation) return _dragGestureScale;
    final sz = MediaQuery.sizeOf(context);
    final ref = math.max(sz.width, sz.height) * 0.55;
    if (ref <= 0) return 1;
    final d = _dragOffset.distance;
    return (1.0 - (d / ref) * 0.38).clamp(0.52, 1.0);
  }

  @override
  void dispose() {
    _restoreSystemUi();
    _zoomAnimCtrl.dispose();
    _dismissAnimCtrl.dispose();
    _snapBackCtrl.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    final pos = _doubleTapDetails?.localPosition ?? Offset.zero;
    final currentScale = _scale;

    Matrix4 end;
    if (currentScale > _zoomThreshold) {
      end = Matrix4.identity();
    } else {
      end = Matrix4.identity()
        ..translate(-pos.dx * 2, -pos.dy * 2)
        ..scale(3.0);
    }

    _zoomMatrixAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: end,
    ).animate(CurvedAnimation(parent: _zoomAnimCtrl, curve: Curves.easeInOut));
    _zoomAnimCtrl.forward(from: 0);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_scale > _zoomThreshold || _runningDismissAnimation) return;
    if (_snapBackCtrl.isAnimating) {
      _snapBackCtrl.stop();
      _snapBackCtrl.reset();
    }
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_scale > _zoomThreshold || _runningDismissAnimation) return;
    final v = details.velocity.pixelsPerSecond;
    final speed = v.distance;
    final dist = _dragOffset.distance;
    final shouldDismiss =
        dist > _dismissDistance || speed > _dismissVelocity;
    if (!shouldDismiss) {
      _snapBackStart = _dragOffset;
      if (_snapBackStart.distance < 0.5) {
        setState(() {
          _dragOffset = Offset.zero;
          _dragGestureScale = 1;
        });
        return;
      }
      _snapBackCtrl.forward(from: 0);
      return;
    }

    Offset dir = _dragOffset;
    if (dir.distance < 16) {
      dir = v;
    }
    if (dir.distance < 1) {
      dir = const Offset(0, 1);
    }
    dir = dir / dir.distance;

    final sz = MediaQuery.sizeOf(context);
    final pad = math.max(sz.width, sz.height) * 0.65;
    _dismissAnimStart = _dragOffset;
    _dismissAnimEnd = _dragOffset + dir * pad;
    _dismissScaleStart = _liveDragScale();
    _dismissScaleEnd = 0.12;
    setState(() {
      _runningDismissAnimation = true;
      _dragGestureScale = _dismissScaleStart;
    });
    _dismissAnimCtrl
      ..reset()
      ..forward();
  }

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (kIsWeb) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.gallerySaveUnavailableWeb)),
          );
        }
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final allowed = await ensureGallerySavePermission();
        if (!allowed && mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.gallerySavePermissionDenied),
              action: SnackBarAction(
                label: l10n.gallerySaveOpenSettings,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return;
        }
      }
      final response = await Dio().get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      final result = await ImageGallerySaverPlus.saveImage(bytes, quality: 100);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final ok = result is Map && result['isSuccess'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? l10n.gallerySaveSuccess : l10n.gallerySaveErrorGeneric,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _ignoreDismissOverlay =>
      _runningDismissAnimation ||
      _scale > _zoomThreshold ||
      _activePointerIds.length > 1;

  @override
  Widget build(BuildContext context) {
    final scrim = _backgroundOpacity();
    return PopScope(
      canPop: !_runningDismissAnimation,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _popped = true;
          return;
        }
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: scrim),
            ),
          ),
          Transform.translate(
            offset: _dragOffset,
            child: Transform.scale(
              scale: _runningDismissAnimation
                  ? _dragGestureScale.clamp(0.08, 1.0)
                  : _liveDragScale().clamp(0.08, 1.0),
              alignment: Alignment.center,
              child: SizedBox.expand(
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _transformController,
                  builder: (context, matrix, _) {
                    final scale = matrix.getMaxScaleOnAxis();
                    return GestureDetector(
                      onDoubleTapDown: _handleDoubleTapDown,
                      onDoubleTap: _handleDoubleTap,
                      behavior: HitTestBehavior.translucent,
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 0.5,
                        maxScale: 5.0,
                        panEnabled: scale > _zoomThreshold,
                        clipBehavior: Clip.none,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: widget.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white70),
                            ),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (e) {
                setState(() => _activePointerIds.add(e.pointer));
              },
              onPointerUp: (e) {
                setState(() => _activePointerIds.remove(e.pointer));
              },
              onPointerCancel: (e) {
                setState(() => _activePointerIds.remove(e.pointer));
              },
              child: IgnorePointer(
                ignoring: _ignoreDismissOverlay,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_runningDismissAnimation || _popped) return;
                    if (_scale <= _zoomThreshold) {
                      _safePop();
                    }
                  },
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onDoubleTapDown: _handleDoubleTapDown,
                  onDoubleTap: _handleDoubleTap,
                  child: const SizedBox.expand(),
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
                      onPressed: _safePop,
                    ),
                    if (!kIsWeb)
                      IconButton(
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
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
    ),
    );
  }
}
