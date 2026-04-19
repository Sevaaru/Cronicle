import 'package:cached_network_image/cached_network_image.dart';
import 'package:cronicle/core/media/gallery_save_permissions.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abre el visor en el **navigator raíz** para que cubra toda la pantalla,
/// incluida la barra inferior del [AppShell], y el modo inmersivo oculte las
/// barras del sistema. El botón atrás de Android cierra primero esta ruta.
void showFullscreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      barrierColor: Colors.black,
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
    with TickerProviderStateMixin {
  final _transformController = TransformationController();
  late final AnimationController _zoomAnimCtrl;
  late final AnimationController _dismissAnimCtrl;
  Animation<Matrix4>? _zoomMatrixAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _saving = false;

  /// Intercepta el botón atrás de Android/gesto del sistema antes de que
  /// GoRouter procese el evento, para cerrar el visor primero.
  ChildBackButtonDispatcher? _backDispatcher;

  /// Desplazamiento vertical manual (dismiss por arrastre).
  double _dragOffsetY = 0;

  /// Animación de salida hacia arriba/abajo.
  double _dismissAnimStartY = 0;
  double _dismissAnimEndY = 0;
  bool _runningDismissAnimation = false;

  static const _zoomThreshold = 1.04;
  static const _dismissDistance = 110.0;
  static const _dismissVelocity = 700.0;

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
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (!_runningDismissAnimation) return;
        final t = Curves.easeOutCubic.transform(_dismissAnimCtrl.value);
        setState(() {
          _dragOffsetY =
              _dismissAnimStartY + (_dismissAnimEndY - _dismissAnimStartY) * t;
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _runningDismissAnimation) {
          _runningDismissAnimation = false;
          if (mounted) {
            Navigator.of(context, rootNavigator: true).maybePop();
          }
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _enterImmersive());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backDispatcher?.removeCallback(_handleSystemBack);
    final dispatcher = Router.of(context).backButtonDispatcher;
    if (dispatcher != null) {
      _backDispatcher = dispatcher.createChildBackButtonDispatcher()
        ..addCallback(_handleSystemBack)
        ..takePriority();
    }
  }

  Future<bool> _handleSystemBack() async {
    if (!_runningDismissAnimation && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
    }
    return true; // Siempre consumir el evento.
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

  double get _scale => _transformController.value.getMaxScaleOnAxis();

  double _backgroundOpacity() {
    final maxD = MediaQuery.sizeOf(context).height * 0.45;
    if (maxD <= 0) return 1;
    final t = (_dragOffsetY.abs() / maxD).clamp(0.0, 1.0);
    return (1 - t * 0.55).clamp(0.35, 1.0);
  }

  @override
  void dispose() {
    _backDispatcher?.removeCallback(_handleSystemBack);
    _restoreSystemUi();
    _zoomAnimCtrl.dispose();
    _dismissAnimCtrl.dispose();
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
      // ignore: deprecated_member_use
      end = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(-pos.dx * 2, -pos.dy * 2)
        // ignore: deprecated_member_use
        ..scale(3.0);
    }

    _zoomMatrixAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: end,
    ).animate(CurvedAnimation(parent: _zoomAnimCtrl, curve: Curves.easeInOut));
    _zoomAnimCtrl.forward(from: 0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_scale > _zoomThreshold || _runningDismissAnimation) return;
    setState(() => _dragOffsetY += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_scale > _zoomThreshold || _runningDismissAnimation) return;
    final v = details.primaryVelocity ??
        details.velocity.pixelsPerSecond.dy;
    final shouldDismiss = _dragOffsetY.abs() > _dismissDistance ||
        v.abs() > _dismissVelocity;
    if (!shouldDismiss) {
      setState(() => _dragOffsetY = 0);
      return;
    }
    final h = MediaQuery.sizeOf(context).height;
    final down = _dragOffsetY > 0 || v > 200;
    _dismissAnimStartY = _dragOffsetY;
    _dismissAnimEndY = down ? h * 1.15 : -h * 1.15;
    _runningDismissAnimation = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black.withValues(alpha: _backgroundOpacity()),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_runningDismissAnimation) return;
              if (_scale <= _zoomThreshold) {
                Navigator.of(context, rootNavigator: true).maybePop();
              }
            },
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: Transform.translate(
              offset: Offset(0, _dragOffsetY),
              child: SizedBox.expand(
                child: ValueListenableBuilder<Matrix4>(
                  valueListenable: _transformController,
                  builder: (context, matrix, _) {
                    final scale = matrix.getMaxScaleOnAxis();
                    return InteractiveViewer(
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
                      onPressed: () => Navigator.of(context, rootNavigator: true)
                          .maybePop(),
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
    );
  }
}
