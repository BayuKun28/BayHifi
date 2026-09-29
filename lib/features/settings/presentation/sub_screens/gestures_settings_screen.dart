import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/player_customization_settings.dart';
import '../controllers/player_customization_controller.dart';

class GesturesSettingsScreen extends ConsumerWidget {
  const GesturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(playerCustomizationProvider);
    final controller = ref.read(playerCustomizationProvider.notifier);
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('GESTURES & TRACK TILES'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // 1. ARTWORK GESTURES
          _buildSectionHeader(
            context,
            'NOW PLAYING ARTWORK GESTURES',
            HugeIcons.strokeRoundedActivity01,
          ),
          const SizedBox(height: 8),
          _buildArtworkGesturesCard(context, settings, controller, isSolid),
          const SizedBox(height: 20),

          // 2. TRACK TILE LAYOUT
          _buildSectionHeader(
            context,
            'TRACK TILE DISPLAY & METADATA',
            HugeIcons.strokeRoundedMusicNote01,
          ),
          const SizedBox(height: 8),
          _buildTrackTileLayoutCard(context, settings, controller, isSolid),
          const SizedBox(height: 20),

          // 3. TRACK TILE SWIPE ACTIONS
          _buildSectionHeader(
            context,
            'TRACK LIST SWIPE ACTIONS',
            HugeIcons.strokeRoundedSlidersVertical,
          ),
          const SizedBox(height: 8),
          _buildTrackTileSwipeCard(context, settings, controller, isSolid),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkGesturesCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
    bool isSolid,
  ) {
    return Container(
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 14,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Touch & Gesture Triggers on Album Art',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildGestureDropdownRow(
            context,
            'Single Tap Action',
            settings.singleTapAction,
            (act) => controller.setSingleTapAction(act),
            isSolid,
          ),
          const Divider(height: 16),
          _buildGestureDropdownRow(
            context,
            'Double Tap Action',
            settings.doubleTapAction,
            (act) => controller.setDoubleTapAction(act),
            isSolid,
          ),
          const Divider(height: 16),
          _buildGestureDropdownRow(
            context,
            'Long Press Action',
            settings.longPressAction,
            (act) => controller.setLongPressAction(act),
            isSolid,
          ),
        ],
      ),
    );
  }

  Widget _buildGestureDropdownRow(
    BuildContext context,
    String label,
    ArtworkGestureAction currentAction,
    ValueChanged<ArtworkGestureAction> onChanged,
    bool isSolid,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        DropdownButton<ArtworkGestureAction>(
          value: currentAction,
          underline: const SizedBox(),
          dropdownColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(12),
          items: ArtworkGestureAction.values.map((action) {
            return DropdownMenuItem(
              value: action,
              child: Text(
                action.label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              HapticFeedback.selectionClick();
              onChanged(val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildTrackTileLayoutCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
    bool isSolid,
  ) {
    return Material(
      color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trackTitleFirst,
              title: const Text(
                'Title First Layout',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                settings.trackTitleFirst ? 'Display: Title (Line 1) • Artist (Line 2)' : 'Display: Artist (Line 1) • Title (Line 2)',
                style: const TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setTrackTitleFirst(val);
              },
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trackShowFormatBadge,
              title: const Text(
                'Show Audio Format Badge',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Display FLAC, WAV, MP3, OPUS badges next to subtitle',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setTrackShowFormatBadge(val);
              },
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trackShowBitrate,
              title: const Text(
                'Show Sample Rate Telemetry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Display real-time kHz sample rate in track subtitle',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setTrackShowBitrate(val);
              },
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trackShowDuration,
              title: const Text(
                'Show Track Duration',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Display mm:ss duration on each track item',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setTrackShowDuration(val);
              },
            ),
            const Divider(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.trackShowDirectFav,
              title: const Text(
                'Show Direct Favorite Button',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                '1-tap heart button right on the track tile row',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setTrackShowDirectFav(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTileSwipeCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
    bool isSolid,
  ) {
    return Container(
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 14,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swipe Gestures on Library Items',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Swipe Right (Left-to-Right)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<TrackTileSwipeAction>(
                value: settings.trackSwipeRight,
                underline: const SizedBox(),
                dropdownColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
                items: TrackTileSwipeAction.values.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(
                      action.label,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    controller.setTrackSwipeRight(val);
                  }
                },
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Swipe Left (Right-to-Left)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              DropdownButton<TrackTileSwipeAction>(
                value: settings.trackSwipeLeft,
                underline: const SizedBox(),
                dropdownColor: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
                items: TrackTileSwipeAction.values.map((action) {
                  return DropdownMenuItem(
                    value: action,
                    child: Text(
                      action.label,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    HapticFeedback.selectionClick();
                    controller.setTrackSwipeLeft(val);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
