import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../audio_engine/fft_processor.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../../settings/presentation/controllers/player_customization_controller.dart';
import '../../domain/track.dart';
import 'custom_album_art_view.dart';

class ParallaxArtworkCard extends ConsumerStatefulWidget {
  final Track? track;
  final bool isPlaying;
  final double size;
  final Color primaryColor;
  final VoidCallback? onSingleTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;

  const ParallaxArtworkCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.size,
    required this.primaryColor,
    this.onSingleTap,
    this.onDoubleTap,
    this.onLongPress,
  });

  @override
  ConsumerState<ParallaxArtworkCard> createState() => _ParallaxArtworkCardState();
}

class _ParallaxArtworkCardState extends ConsumerState<ParallaxArtworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late Animation<Offset> _springAnimation;

  Offset _targetOffset = Offset.zero;
  Offset _currentOffset = Offset.zero;

  // Audio-reactive bass pulse smoothing
  double _bassEnergy = 0.0;
  DateTime _lastDoubleTapCheck = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(() {
        setState(() {
          _currentOffset = _springAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final normX = ((event.localPosition.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final normY = ((event.localPosition.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _targetOffset = Offset(normX, normY);
      _currentOffset = _targetOffset;
    });
  }

  void _onPointerExit(PointerExitEvent event) {
    _animateBackToCenter();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final normX = ((details.localPosition.dx - centerX) / centerX).clamp(-1.0, 1.0);
    final normY = ((details.localPosition.dy - centerY) / centerY).clamp(-1.0, 1.0);

    setState(() {
      _targetOffset = Offset(normX, normY);
      _currentOffset = _targetOffset;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _animateBackToCenter();
  }

  void _animateBackToCenter() {
    _springAnimation = Tween<Offset>(
      begin: _currentOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutBack,
    ));

    _springController.forward(from: 0.0);
  }

  void _handleTap() {
    final now = DateTime.now();
    if (now.difference(_lastDoubleTapCheck).inMilliseconds < 280) {
      // Double tap triggered
      _lastDoubleTapCheck = DateTime.fromMillisecondsSinceEpoch(0);
      HapticFeedback.mediumImpact();
      widget.onDoubleTap?.call();
    } else {
      _lastDoubleTapCheck = now;
      Future.delayed(const Duration(milliseconds: 290), () {
        if (_lastDoubleTapCheck == now) {
          HapticFeedback.lightImpact();
          widget.onSingleTap?.call();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(playerCustomizationProvider);
    final size = widget.size;

    // 3D Rotation Matrix Calculation
    final enabled = settings.enableParallax && settings.performanceMode != PerformanceMode.batterySaver;
    final intensity = settings.parallaxIntensity;

    final rotX = enabled ? -_currentOffset.dy * 0.16 * intensity : 0.0;
    final rotY = enabled ? _currentOffset.dx * 0.16 * intensity : 0.0;

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(rotX)
      ..rotateY(rotY);

    // Base album art
    Widget content = CustomAlbumArtView(
      track: widget.track,
      isPlaying: widget.isPlaying,
      style: settings.albumArtStyle,
      ambientGlow: settings.ambientGlow,
      primaryColor: widget.primaryColor,
      size: size,
    );

    // Audio-reactive pulse from Riverpod rtaSpectrumProvider if enabled
    if (settings.enableBreathingPulse &&
        widget.isPlaying &&
        settings.performanceMode != PerformanceMode.batterySaver) {
      final rtaAsync = ref.watch(rtaSpectrumProvider);
      final pulseScale = rtaAsync.maybeWhen(
        data: (magnitudes) {
          if (magnitudes.isEmpty) return 1.0;
          double lowSum = 0.0;
          final count = math.min(6, magnitudes.length);
          for (int i = 0; i < count; i++) {
            lowSum += magnitudes[i];
          }
          final rawEnergy = count > 0 ? (lowSum / count) : 0.0;
          _bassEnergy = _bassEnergy * 0.82 + rawEnergy * 0.18;
          return 1.0 + (_bassEnergy.clamp(0.0, 1.0) * 0.032);
        },
        orElse: () => 1.0,
      );

      content = Transform.scale(
        scale: pulseScale,
        child: content,
      );
    }

    return MouseRegion(
      onHover: (e) => _onPointerHover(e, Size(size, size)),
      onExit: _onPointerExit,
      child: GestureDetector(
        onPanUpdate: (d) => _onPanUpdate(d, Size(size, size)),
        onPanEnd: _onPanEnd,
        onTap: _handleTap,
        onLongPress: () {
          HapticFeedback.heavyImpact();
          widget.onLongPress?.call();
        },
        child: Transform(
          transform: matrix,
          alignment: FractionalOffset.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              content,
              // Dynamic sheen glare overlay when tilted
              if (enabled && (_currentOffset.dx.abs() > 0.05 || _currentOffset.dy.abs() > 0.05))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          settings.albumArtStyle == AlbumArtStyle.square
                              ? 8
                              : (settings.albumArtStyle == AlbumArtStyle.squircle ? 28 : size / 2),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment(-_currentOffset.dx, -_currentOffset.dy),
                          end: Alignment(_currentOffset.dx, _currentOffset.dy),
                          colors: [
                            Colors.white.withValues(alpha: 0.12),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.08),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
