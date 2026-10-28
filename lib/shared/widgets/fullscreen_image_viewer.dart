import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cronicle/core/media/gallery_save_permissions.dart';
import 'package:cronicle/l10n/app_localizations.dart';

/// Args for the fullscreen viewer. Either a single image URL or a gallery
/// (list + initial index).
class FullscreenImageArgs {
  const FullscreenImageArgs({
    required this.urls,
    this.initialIndex = 0,
  }) : assert(urls.length > 0);

  /// Convenience for a single image.
  factory FullscreenImageArgs.single(String url) =>
      FullscreenImageArgs(urls: [url]);

  final List<String> urls;
  final int initialIndex;
}

/// Push the fullscreen viewer with a single image.
///
/// Implementation note: we use Flutter's stock `showGeneralDialog` which
/// installs a proper `ModalRoute` on the **root** Navigator. That route
/// registers itself with the framework's `BackButtonDispatcher` and is
/// always the first thing popped on Android back — which avoids the
/// previous bug where GoRouter’s back-button handling fought with an
/// imperatively-pushed route.
void showFullscreenImage(BuildContext context, String imageUrl) {
  _pushViewer(context, FullscreenImageArgs.single(imageUrl));
}

/// Push the fullscreen viewer with a gallery of images, optionally starting
/// at [initialIndex]. Use this for game screenshots, character pictures, etc.
void showFullscreenGallery(
  BuildContext context,
  List<String> urls, {
  int initialIndex = 0,
}) {
  if (urls.isEmpty) return;
  _pushViewer(
    context,
    FullscreenImageArgs(
      urls: urls,
      initialIndex: initialIndex.clamp(0, urls.length - 1),
    ),
  );
}

void _pushViewer(BuildContext context, FullscreenImageArgs args) {
  // Push on the LOCAL Navigator (the one the calling page belongs to,
  // typically the shell Navigator). The viewer becomes a regular route
  // sitting directly above the current page in the same Navigator stack.
  // GoRouter's `popRoute` delegates to that same Navigator's `maybePop`,
  // so Android back pops the viewer first — and only the viewer — then
  // a second back pops the underlying page. No matchList desync, no
  // double-pop, no dialog-vs-route conflicts.
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => FullscreenImageViewerPage(args: args),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// Public viewer page used by the route pushed by [showFullscreenImage] /
/// [showFullscreenGallery].
class FullscreenImageViewerPage extends StatelessWidget {
  const FullscreenImageViewerPage({super.key, required this.args});
  final FullscreenImageArgs args;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: _FullscreenImageViewer(args: args),
    );
  }
}

class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({required this.args});
  final FullscreenImageArgs args;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with TickerProviderStateMixin {
  late final PageController _pageCtrl;
  late int _currentIndex;
  bool _saving = false;
  bool _chromeVisible = true;
  bool _popped = false;

  // Vertical swipe-to-dismiss state. Driven by a raw Listener so that
  // multi-touch (pinch) gestures stay free for the InteractiveViewer below.
  Offset _dragOffset = Offset.zero;
  bool _dragging = false;
  int? _dragPointerId;
  Offset _dragLastPosition = Offset.zero;
  Offset _dragStartPosition = Offset.zero;
  Offset _dragVelocityLast = Offset.zero;
  Duration _dragLastTs = Duration.zero;
  Offset _dragStart = Offset.zero;
  int _activePointerCount = 0;
  late final AnimationController _snapBackCtrl;

  // Per-page transform controllers (so zoom state survives page swipe).
  final Map<int, TransformationController> _transformCtrls = {};

  static const _zoomThreshold = 1.04;
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 800.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.args.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
    _snapBackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (!mounted) return;
        final t = Curves.easeOutCubic.transform(_snapBackCtrl.value);
        setState(() {
          _dragOffset = Offset.lerp(_dragStart, Offset.zero, t)!;
        });
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyOverlayStyle());
  }

  @override
  void dispose() {
    _restoreSystemUi();
    _snapBackCtrl.dispose();
    _pageCtrl.dispose();
    for (final c in _transformCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// We deliberately AVOID `SystemUiMode.immersiveSticky` here. In sticky
  /// immersive mode, Android consumes the first back press / edge swipe to
  /// restore the system bars instead of dispatching it to the activity, and
  /// that flag tends to outlive a `setEnabledSystemUIMode(edgeToEdge)` call
  /// in `dispose()` by one frame — which made the back press AFTER closing
  /// the viewer be silently swallowed and end up backgrounding the app.
  /// Instead we keep `edgeToEdge` (already the app default) and just paint
  /// the bars transparent with light icons while we are visible.
  void _applyOverlayStyle() {
    if (kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _restoreSystemUi() {
    if (kIsWeb) return;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  TransformationController _ctrlFor(int i) =>
      _transformCtrls.putIfAbsent(i, () => TransformationController());

  double _scaleFor(int i) => _ctrlFor(i).value.getMaxScaleOnAxis();

  /// Close the viewer by popping its route from the local Navigator
  /// (the same one we pushed it onto). The `_popped` guard prevents
  /// double-pops from racing close taps + dismiss gesture + Android back.
  void _close() {
    if (!mounted || _popped) return;
    _popped = true;
    Navigator.of(context).maybePop();
  }

  // ---------- swipe to dismiss (Listener-based) ----------
  // Implemented with a raw `Listener` instead of a `GestureDetector` so it
  // does not enter the gesture arena and never steals pinch gestures from
  // the `InteractiveViewer`. We only track a single-pointer vertical drag;
  // as soon as a second pointer touches down (= pinch) we cancel.

  static const double _dragSlop = 12.0;

  void _cancelDrag() {
    if (!_dragging) {
      _dragPointerId = null;
      return;
    }
    _dragging = false;
    _dragPointerId = null;
    if (_dragOffset == Offset.zero) return;
    _dragStart = _dragOffset;
    _snapBackCtrl.forward(from: 0);
  }

  void _onPointerDown(PointerDownEvent e) {
    _activePointerCount += 1;
    if (_activePointerCount > 1) {
      // Pinch starting — give the gesture entirely to InteractiveViewer.
      _cancelDrag();
      return;
    }
    if (_scaleFor(_currentIndex) > _zoomThreshold) return;
    if (_snapBackCtrl.isAnimating) _snapBackCtrl.stop();
    _dragPointerId = e.pointer;
    _dragStartPosition = e.position;
    _dragLastPosition = e.position;
    _dragVelocityLast = Offset.zero;
    _dragLastTs = e.timeStamp;
    // Don't actually start dragging until the user moves past slop.
    _dragging = false;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_dragPointerId != e.pointer) return;
    if (_activePointerCount > 1) return;
    final dyTotal = e.position.dy - _dragStartPosition.dy;
    final dxTotal = e.position.dx - _dragStartPosition.dx;
    if (!_dragging) {
      // Only commit to drag if vertical movement clearly dominates.
      if (dyTotal.abs() < _dragSlop) return;
      if (dxTotal.abs() > dyTotal.abs() * 0.9) {
        // Mostly horizontal — let PageView handle it.
        _dragPointerId = null;
        return;
      }
      _dragging = true;
      _dragStart = _dragOffset;
    }
    final dt = (e.timeStamp - _dragLastTs).inMicroseconds / 1e6;
    if (dt > 0) {
      _dragVelocityLast =
          Offset(0, (e.position.dy - _dragLastPosition.dy) / dt);
    }
    _dragLastPosition = e.position;
    _dragLastTs = e.timeStamp;
    setState(() {
      _dragOffset = Offset(0, dyTotal);
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_activePointerCount > 0) _activePointerCount -= 1;
    if (_dragPointerId != e.pointer) return;
    _dragPointerId = null;
    if (!_dragging) return;
    _dragging = false;
    final dist = _dragOffset.dy.abs();
    final vy = _dragVelocityLast.dy.abs();
    if (dist > _dismissDistance || vy > _dismissVelocity) {
      _close();
      return;
    }
    if (_dragOffset == Offset.zero) return;
    _dragStart = _dragOffset;
    _snapBackCtrl.forward(from: 0);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_activePointerCount > 0) _activePointerCount -= 1;
    if (_dragPointerId == e.pointer) _cancelDrag();
  }

  double _scrim() {
    final sz = MediaQuery.sizeOf(context);
    final ref = math.max(160.0, sz.height * 0.4);
    final t = (_dragOffset.dy.abs() / ref).clamp(0.0, 1.0);
    return (1 - Curves.easeOut.transform(t)).clamp(0.0, 1.0);
  }

  double _liveScale() {
    final sz = MediaQuery.sizeOf(context);
    final ref = sz.height * 0.55;
    final d = _dragOffset.dy.abs();
    return (1 - (d / ref) * 0.32).clamp(0.6, 1.0);
  }

  // ---------- save ----------

  Future<void> _saveCurrent() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.gallerySaveUnavailableWeb)),
          );
        }
        return;
      }
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final allowed = await ensureGallerySavePermission();
        if (!allowed) {
          if (!mounted) return;
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
      final url = widget.args.urls[_currentIndex];
      final response = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data!);
      final result =
          await ImageGallerySaverPlus.saveImage(bytes, quality: 100);
      if (!mounted) return;
      final ok = result is Map && result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.gallerySaveSuccess : l10n.gallerySaveErrorGeneric,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final scrim = _scrim();
    final urls = widget.args.urls;
    final isGallery = urls.length > 1;
    final liveScale = _liveScale();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated black scrim — fades with vertical drag.
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: scrim)),
          ),

          // Image content (PageView for galleries) with drag transform.
          // The Listener wraps everything so it sees raw pointer events
          // WITHOUT entering the gesture arena — that lets the pinch
          // gesture flow freely to the InteractiveViewer below while we
          // still get to track single-finger vertical drags for dismiss.
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              behavior: HitTestBehavior.translucent,
              child: Transform.translate(
                offset: _dragOffset,
                child: Transform.scale(
                  scale: liveScale,
                  alignment: Alignment.center,
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: urls.length,
                    physics: _scaleFor(_currentIndex) > _zoomThreshold ||
                            _dragging
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    onPageChanged: (i) =>
                        setState(() => _currentIndex = i),
                    itemBuilder: (context, i) => _ZoomablePage(
                      url: urls[i],
                      controller: _ctrlFor(i),
                      onTap: () =>
                          setState(() => _chromeVisible = !_chromeVisible),
                      onScaleChanged: () {
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // (vertical-drag overlay removed — handled by the Listener above)

          // Top chrome: close + counter + save.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: _chromeVisible ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _chromeVisible ? scrim : 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        _ChromeIconButton(
                          icon: Icons.close_rounded,
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: _close,
                        ),
                        Expanded(
                          child: Center(
                            child: isGallery
                                ? _Counter(
                                    current: _currentIndex + 1,
                                    total: urls.length,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        if (!kIsWeb)
                          _ChromeIconButton(
                            icon: Icons.download_rounded,
                            tooltip: AppLocalizations.of(context)!
                                .gallerySaveSuccess,
                            loading: _saving,
                            onPressed: _saveCurrent,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom dots indicator (only galleries with <= 12 items).
          if (isGallery && urls.length <= 12)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _chromeVisible ? Offset.zero : const Offset(0, 1),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _chromeVisible ? scrim : 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 12),
                      child: _DotsIndicator(
                        count: urls.length,
                        index: _currentIndex,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single zoomable page used inside the [PageView].
class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({
    required this.url,
    required this.controller,
    required this.onTap,
    required this.onScaleChanged,
  });

  final String url;
  final TransformationController controller;
  final VoidCallback onTap;
  final VoidCallback onScaleChanged;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  Animation<Matrix4>? _anim;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_anim != null) widget.controller.value = _anim!.value;
      });
    widget.controller.addListener(widget.onScaleChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(widget.onScaleChanged);
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails d) => _doubleTapDetails = d;

  void _handleDoubleTap() {
    final pos = _doubleTapDetails?.localPosition ?? Offset.zero;
    final current = widget.controller.value.getMaxScaleOnAxis();
    Matrix4 end;
    if (current > 1.04) {
      end = Matrix4.identity();
    } else {
      end = Matrix4.identity()
        ..translate(-pos.dx * 2, -pos.dy * 2)
        ..scale(3.0);
    }
    _anim = Matrix4Tween(begin: widget.controller.value, end: end).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: widget.controller,
        minScale: 1.0,
        maxScale: 5.0,
        clipBehavior: Clip.none,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: widget.url,
            fit: BoxFit.contain,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
            errorWidget: (_, _, _) => const Icon(
              Icons.broken_image_rounded,
              color: Colors.white54,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

/// Material 3 chrome IconButton: tonal-style on a translucent surface.
class _ChromeIconButton extends StatelessWidget {
  const _ChromeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}
