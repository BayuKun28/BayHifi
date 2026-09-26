import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../../settings/domain/player_playback_settings.dart';

class CustomTimeBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final TimeBarStyle style;
  final ValueChanged<Duration> onSeek;
  final Color primaryColor;
  final TimeDisplayMode timeDisplayMode;
  final VoidCallback? onToggleTimeDisplayMode;

  const CustomTimeBar({
    super.key,
    required this.position,
    required this.duration,
    required this.style,
    required this.onSeek,
    required this.primaryColor,
    this.timeDisplayMode = TimeDisplayMode.total,
    this.onToggleTimeDisplayMode,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final remaining = duration > position ? duration - position : Duration.zero;
    final displayDurationText = timeDisplayMode == TimeDisplayMode.remaining
        ? '-${_formatDuration(remaining)}'
        : _formatDuration(duration);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrackBar(context, progress, theme),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontFeatures: AppTypography.audioFigures,
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: onToggleTimeDisplayMode,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    displayDurationText,
                    style: TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackBar(BuildContext context, double progress, ThemeData theme) {
    switch (style) {
      case TimeBarStyle.slim:
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            activeTrackColor: primaryColor,
            inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.4),
            thumbColor: primaryColor,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: progress,
            onChanged: (val) {
              final newMs = (val * duration.inMilliseconds).toInt();
              onSeek(Duration(milliseconds: newMs));
            },
          ),
        );

      case TimeBarStyle.capsule:
        return SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8.0,
            activeTrackColor: primaryColor,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              elevation: 3,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: progress,
            onChanged: (val) {
              final newMs = (val * duration.inMilliseconds).toInt();
              onSeek(Duration(milliseconds: newMs));
            },
          ),
        );

      case TimeBarStyle.segmented:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleTouch(context, details.localPosition),
          onTapDown: (details) => _handleTouch(context, details.localPosition),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const int segments = 32;
                final activeSegments = (progress * segments).round();
                return Row(
                  children: List.generate(segments, (i) {
                    final isActive = i < activeSegments;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? (i > segments * 0.8
                                  ? const Color(0xFFFF9F0A)
                                  : primaryColor)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        );

      case TimeBarStyle.waveform:
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) => _handleTouch(context, details.localPosition),
          onTapDown: (details) => _handleTouch(context, details.localPosition),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const int bars = 40;
                final activeBars = (progress * bars).round();
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(bars, (i) {
                    final isActive = i < activeBars;
                    // Pseudo-waveform curve height
                    final double normalizedHeight = 0.3 + 0.7 * ((i * 7 + 3) % 11) / 10.0;
                    return Expanded(
                      child: Center(
                        child: Container(
                          width: 2.5,
                          height: 20 * normalizedHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isActive
                                ? primaryColor
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        );
    }
  }

  void _handleTouch(BuildContext context, Offset localPosition) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0) {
      final double ratio = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
      final int newMs = (ratio * duration.inMilliseconds).toInt();
      HapticFeedback.selectionClick();
      onSeek(Duration(milliseconds: newMs));
    }
  }
}
