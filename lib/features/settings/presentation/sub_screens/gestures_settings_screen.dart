import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/player_customization_settings.dart';
import '../controllers/player_customization_controller.dart';

class GesturesSettingsScreen extends ConsumerWidget {
  const GesturesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
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
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildStatusHero(context, theme, primary, settings, isSolid),
          const SizedBox(height: 18),

          // ─── 2. ARTWORK GESTURES ───────────────────────────────────────────
          _buildSectionHeader(
            context,
            'NOW PLAYING ARTWORK GESTURES',
            HugeIcons.strokeRoundedActivity01,
          ),
          const SizedBox(height: 8),
          _buildArtworkGesturesCard(context, settings, controller, isSolid),
          const SizedBox(height: 20),

          // ─── 3. TRACK TILE DISPLAY & METADATA ──────────────────────────────
          _buildSectionHeader(
            context,
            'TRACK TILE DISPLAY & METADATA',
            HugeIcons.strokeRoundedMusicNote01,
          ),
          const SizedBox(height: 8),
          _buildTrackTileLayoutCard(context, theme, primary, settings, controller, isSolid),
          const SizedBox(height: 20),

          // ─── 4. TRACK LIST SWIPE ACTIONS ───────────────────────────────────
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

  // ─── STATUS HERO BANNER ───────────────────────────────────────────────────
  Widget _buildStatusHero(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerCustomizationSettings settings,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedTouch01,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GESTURES & TACTILE CONTROLS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Interactive cover taps, library swipe shortcuts & metadata visibility',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                context,
                theme,
                label: 'Tap: ${settings.singleTapAction.label}',
                isActive: settings.singleTapAction != ArtworkGestureAction.none,
                color: primary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Double: ${settings.doubleTapAction.label}',
                isActive: settings.doubleTapAction != ArtworkGestureAction.none,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Swipe R: ${settings.trackSwipeRight.label}',
                isActive: settings.trackSwipeRight != TrackTileSwipeAction.none,
                color: theme.colorScheme.tertiary,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isSolid
            ? (isActive
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest)
            : (isActive
                ? color.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
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

  // ─── ARTWORK GESTURES CARD ────────────────────────────────────────────────
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
        radius: 16,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoDropdownSelector<ArtworkGestureAction>(
            context: context,
            title: 'SINGLE TAP TRIGGER (NOW PLAYING ART)',
            currentValue: settings.singleTapAction,
            items: ArtworkGestureAction.values,
            itemLabel: (a) => a.label,
            itemDescription: (a) => a.description,
            itemIcon: _getGestureActionIcon,
            onChanged: (act) => controller.setSingleTapAction(act),
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),
          _buildBentoDropdownSelector<ArtworkGestureAction>(
            context: context,
            title: 'DOUBLE TAP TRIGGER (NOW PLAYING ART)',
            currentValue: settings.doubleTapAction,
            items: ArtworkGestureAction.values,
            itemLabel: (a) => a.label,
            itemDescription: (a) => a.description,
            itemIcon: _getGestureActionIcon,
            onChanged: (act) => controller.setDoubleTapAction(act),
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),
          _buildBentoDropdownSelector<ArtworkGestureAction>(
            context: context,
            title: 'LONG PRESS TRIGGER (NOW PLAYING ART)',
            currentValue: settings.longPressAction,
            items: ArtworkGestureAction.values,
            itemLabel: (a) => a.label,
            itemDescription: (a) => a.description,
            itemIcon: _getGestureActionIcon,
            onChanged: (act) => controller.setLongPressAction(act),
            isSolid: isSolid,
          ),
        ],
      ),
    );
  }

  // ─── TRACK TILE LAYOUT CARD ───────────────────────────────────────────────
  Widget _buildTrackTileLayoutCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Title First Layout',
            subtitle: settings.trackTitleFirst
                ? 'Display: Track Title (Line 1) • Artist (Line 2)'
                : 'Display: Artist (Line 1) • Track Title (Line 2)',
            value: settings.trackTitleFirst,
            onChanged: (val) => controller.setTrackTitleFirst(val),
          ),
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Show Audio Format Badge',
            subtitle: 'Display FLAC, WAV, MP3, OPUS badges in track subtitle',
            value: settings.trackShowFormatBadge,
            onChanged: (val) => controller.setTrackShowFormatBadge(val),
          ),
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Show Sample Rate Telemetry',
            subtitle: 'Display real-time kHz sample rate in track subtitle',
            value: settings.trackShowBitrate,
            onChanged: (val) => controller.setTrackShowBitrate(val),
          ),
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Show Track Duration',
            subtitle: 'Display mm:ss audio duration on right trailing column',
            value: settings.trackShowDuration,
            onChanged: (val) => controller.setTrackShowDuration(val),
          ),
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Show Direct Favorite Button',
            subtitle: '1-tap heart button right on the track tile row',
            value: settings.trackShowDirectFav,
            onChanged: (val) => controller.setTrackShowDirectFav(val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required ThemeData theme,
    required Color primary,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: primary,
          onChanged: (val) {
            AppHaptics.lightImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }

  // ─── TRACK TILE SWIPE ACTIONS CARD ────────────────────────────────────────
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
        radius: 16,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoDropdownSelector<TrackTileSwipeAction>(
            context: context,
            title: 'SWIPE RIGHT ACTION (LEFT-TO-RIGHT)',
            currentValue: settings.trackSwipeRight,
            items: TrackTileSwipeAction.values,
            itemLabel: (a) => a.label,
            itemDescription: (a) => a.description,
            itemIcon: _getSwipeActionIcon,
            onChanged: (act) => controller.setTrackSwipeRight(act),
            isSolid: isSolid,
          ),
          const SizedBox(height: 12),
          _buildBentoDropdownSelector<TrackTileSwipeAction>(
            context: context,
            title: 'SWIPE LEFT ACTION (RIGHT-TO-LEFT)',
            currentValue: settings.trackSwipeLeft,
            items: TrackTileSwipeAction.values,
            itemLabel: (a) => a.label,
            itemDescription: (a) => a.description,
            itemIcon: _getSwipeActionIcon,
            onChanged: (act) => controller.setTrackSwipeLeft(act),
            isSolid: isSolid,
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE BENTO DROPDOWN HELPER ───────────────────────────────────────
  Widget _buildBentoDropdownSelector<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemDescription,
    required dynamic Function(T) itemIcon,
    required ValueChanged<T> onChanged,
    required bool isSolid,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: false),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: currentValue,
              isExpanded: true,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              dropdownColor: isSolid
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                final isSelected = item == currentValue;
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: itemIcon(item),
                        size: 16,
                        color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  AppHaptics.selectionClick();
                  onChanged(val);
                }
              },
            ),
          ),
          const SizedBox(height: 2),
          Text(
            itemDescription(currentValue),
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  dynamic _getGestureActionIcon(ArtworkGestureAction action) {
    switch (action) {
      case ArtworkGestureAction.toggleLyrics:
        return HugeIcons.strokeRoundedText;
      case ArtworkGestureAction.togglePlayPause:
        return HugeIcons.strokeRoundedPlayCircle;
      case ArtworkGestureAction.toggleFavorite:
        return HugeIcons.strokeRoundedFavourite;
      case ArtworkGestureAction.openInspector:
        return HugeIcons.strokeRoundedInformationCircle;
      case ArtworkGestureAction.openProQStudio:
        return HugeIcons.strokeRoundedSlidersHorizontal;
      case ArtworkGestureAction.openDspRack:
        return HugeIcons.strokeRoundedAudioBook04;
      case ArtworkGestureAction.openQueue:
        return HugeIcons.strokeRoundedPlaylist01;
      case ArtworkGestureAction.viewFullArtwork:
        return HugeIcons.strokeRoundedImage02;
      case ArtworkGestureAction.none:
        return HugeIcons.strokeRoundedCancel01;
    }
  }

  dynamic _getSwipeActionIcon(TrackTileSwipeAction action) {
    switch (action) {
      case TrackTileSwipeAction.addToQueue:
        return HugeIcons.strokeRoundedPlaylist01;
      case TrackTileSwipeAction.playNext:
        return HugeIcons.strokeRoundedNext;
      case TrackTileSwipeAction.toggleFavorite:
        return HugeIcons.strokeRoundedFavourite;
      case TrackTileSwipeAction.addToPlaylist:
        return HugeIcons.strokeRoundedFolderPlus;
      case TrackTileSwipeAction.none:
        return HugeIcons.strokeRoundedCancel01;
    }
  }
}
