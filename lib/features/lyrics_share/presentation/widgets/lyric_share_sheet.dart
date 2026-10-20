import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../player/domain/lyrics_line.dart';
import '../../../player/domain/track.dart';
import '../controllers/lyric_share_controller.dart';
import 'tabs/lyric_share_preview_tab.dart';
import 'tabs/lyric_share_select_lines_tab.dart';
import 'tabs/lyric_share_telemetry_tab.dart';
import 'tabs/lyric_share_style_tab.dart';

/// Studio Modal bottom sheet for customizing, previewing, and sharing lyric cards
class LyricShareSheet extends ConsumerStatefulWidget {
  final Track track;
  final List<LyricsLine> allLines;
  final LyricsLine? initialSelectedLine;
  final Color? dominantAlbumColor;
  final Color? vibrantAlbumColor;
  final Color? lightVibrantAlbumColor;
  final String? audioSpec;
  final String? autoEqProfileName;
  final String? dspProfileName;
  final String? dacDeviceName;
  final DateTime? timestamp;
  final String? customGearText;
  final bool initialShowQrCode;

  const LyricShareSheet({
    super.key,
    required this.track,
    required this.allLines,
    this.initialSelectedLine,
    this.dominantAlbumColor,
    this.vibrantAlbumColor,
    this.lightVibrantAlbumColor,
    this.audioSpec,
    this.autoEqProfileName,
    this.dspProfileName,
    this.dacDeviceName,
    this.timestamp,
    this.customGearText,
    this.initialShowQrCode = false,
  });

  /// Helper to display the sheet in modern Material 3 full screen modal
  static Future<void> show(
    BuildContext context, {
    required Track track,
    required List<LyricsLine> allLines,
    LyricsLine? initialSelectedLine,
    Color? dominantAlbumColor,
    Color? vibrantAlbumColor,
    Color? lightVibrantAlbumColor,
    String? audioSpec,
    String? autoEqProfileName,
    String? dspProfileName,
    String? dacDeviceName,
    DateTime? timestamp,
    String? customGearText,
    bool initialShowQrCode = false,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => ScaffoldMessenger(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: LyricShareSheet(
              track: track,
              allLines: allLines,
              initialSelectedLine: initialSelectedLine,
              dominantAlbumColor: dominantAlbumColor,
              vibrantAlbumColor: vibrantAlbumColor,
              lightVibrantAlbumColor: lightVibrantAlbumColor,
              audioSpec: audioSpec,
              autoEqProfileName: autoEqProfileName,
              dspProfileName: dspProfileName,
              dacDeviceName: dacDeviceName,
              timestamp: timestamp,
              customGearText: customGearText,
              initialShowQrCode: initialShowQrCode,
            ),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LyricShareSheet> createState() => _LyricShareSheetState();
}

class _LyricShareSheetState extends ConsumerState<LyricShareSheet> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late final StateNotifierProvider<LyricShareController, LyricShareState> _provider;
  int _currentTabIndex = 0; // 0 = Studio, 1 = Lines, 2 = Telemetry, 3 = Style
  final TextEditingController _noteTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = StateNotifierProvider<LyricShareController, LyricShareState>(
      (ref) => LyricShareController(
        track: widget.track,
        allLines: widget.allLines,
        initialSelectedLine: widget.initialSelectedLine,
        dominantColor: widget.dominantAlbumColor,
        vibrantColor: widget.vibrantAlbumColor,
        lightVibrantColor: widget.lightVibrantAlbumColor,
        audioSpec: widget.audioSpec,
        autoEqProfileName: widget.autoEqProfileName,
        dspProfileName: widget.dspProfileName,
        dacDeviceName: widget.dacDeviceName,
        timestamp: widget.timestamp,
        customGearText: widget.customGearText,
        showQrCode: widget.initialShowQrCode,
      ),
    );
  }

  @override
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  void _showFeedbackSnackbar(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Top Drag Handle & Title Bar
            _buildHeader(context, theme, state),

            // 4-Tab Studio Navigation Pill Bar
            _buildTabSelector(theme, state),

            const Divider(height: 1, thickness: 0.8),

            // Tab Content
            Expanded(
              child: _buildActiveTabContent(context, theme, state, controller),
            ),

            const Divider(height: 1, thickness: 0.8),

            // Bottom Actions Bar (Save & Share)
            SafeArea(
              top: false,
              bottom: true,
              child: _buildBottomActionBar(context, theme, state, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, LyricShareState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.share2,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lyric Studio Share',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  widget.track.title.isNotEmpty ? widget.track.title : 'Track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            onPressed: () {
              AppHaptics.lightImpact();
              Navigator.of(context).pop();
            },
            icon: Icon(
              LucideIcons.x,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(ThemeData theme, LyricShareState state) {
    final selectedCount = state.config.selectedLines.length;

    final tabs = [
      (0, 'Studio', LucideIcons.image),
      (1, 'Lines ($selectedCount/6)', LucideIcons.type),
      (2, 'Telemetry', LucideIcons.slidersHorizontal),
      (3, 'Style', LucideIcons.palette),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _currentTabIndex == tab.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _currentTabIndex = tab.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.$3,
                        size: 14,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tab.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return LyricSharePreviewTab(
          state: state,
          controller: controller,
          repaintBoundaryKey: _repaintBoundaryKey,
        );
      case 1:
        return LyricShareSelectLinesTab(
          state: state,
          controller: controller,
        );
      case 2:
        return LyricShareTelemetryTab(
          state: state,
          controller: controller,
          noteTextController: _noteTextController,
        );
      case 3:
        return LyricShareStyleTab(
          state: state,
          controller: controller,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Save Image Button
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: state.isRendering
                  ? null
                  : () async {
                      AppHaptics.lightImpact();
                      final path = await controller.saveImageLocally(_repaintBoundaryKey);
                      if (context.mounted && path != null) {
                        _showFeedbackSnackbar(context, 'Saved to Gallery: $path');
                      }
                    },
              icon: Icon(
                LucideIcons.download,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: const Text('Save'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share Story / Socials Button
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: state.isRendering || state.config.selectedLines.isEmpty
                  ? null
                  : () async {
                      AppHaptics.mediumImpact();
                      final result = await controller.shareLyricCard(_repaintBoundaryKey);
                      if (context.mounted) {
                        if (result.isMissingPlugin) {
                          _showFeedbackSnackbar(
                            context,
                            'Image saved to Gallery! Restart app to enable direct native sharing.',
                            duration: const Duration(seconds: 4),
                          );
                        } else if (!result.success && result.errorMessage != null) {
                          _showFeedbackSnackbar(context, result.errorMessage!);
                        }
                      }
                    },
              icon: state.isRendering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      LucideIcons.share2,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
              label: Text(state.isRendering ? 'Generating...' : 'Share to Socials'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
