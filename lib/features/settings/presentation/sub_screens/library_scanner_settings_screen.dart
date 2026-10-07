import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../player/presentation/controllers/sleep_timer_controller.dart';
import '../../../player/presentation/widgets/sleep_timer_sheet.dart';

class LibraryScannerSettingsScreen extends ConsumerStatefulWidget {
  const LibraryScannerSettingsScreen({super.key});

  @override
  ConsumerState<LibraryScannerSettingsScreen> createState() => _LibraryScannerSettingsScreenState();
}

class _LibraryScannerSettingsScreenState extends ConsumerState<LibraryScannerSettingsScreen> {
  int _minTrackDurationSeconds = 30;
  bool _autoScanOnStartup = true;

  @override
  void initState() {
    super.initState();
    final storage = LocalPersistenceService.instance;
    final savedSeconds = storage.getSetting<int>('minimum_track_duration_seconds', null);
    if (savedSeconds != null) {
      _minTrackDurationSeconds = savedSeconds;
    } else {
      final legacyIgnore = storage.getSetting<bool>('ignore_short_tracks', true)!;
      _minTrackDurationSeconds = legacyIgnore ? 30 : 0;
    }
    _autoScanOnStartup = storage.getSetting<bool>('auto_scan_on_startup', true)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final timerState = ref.watch(sleepTimerControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('LIBRARY SCANNER & SLEEP TIMER'),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildStatusHero(context, theme, primary, libraryState.tracks.length, libraryState.configuredFolderPaths.length, timerState.isActive, isSolid),
          const SizedBox(height: 18),

          // ─── 2. MUSIC SOURCE FOLDERS ────────────────────────────────────────
          _buildSectionHeader(context, 'MUSIC SOURCE FOLDERS', HugeIcons.strokeRoundedFolderLibrary),
          const SizedBox(height: 8),
          _buildSourceFoldersCard(context, isSolid),
          const SizedBox(height: 20),

          // ─── 3. SMART SLEEP TIMER ───────────────────────────────────────────
          _buildSectionHeader(context, 'SMART SLEEP TIMER', HugeIcons.strokeRoundedHourglass),
          const SizedBox(height: 8),
          _buildSleepTimerCard(context, isSolid),
          const SizedBox(height: 20),

          // ─── 4. LIBRARY SCANNER RULES ───────────────────────────────────────
          _buildSectionHeader(context, 'LIBRARY SCANNER RULES', HugeIcons.strokeRoundedFolder01),
          const SizedBox(height: 8),
          _buildLibraryRulesCard(context, isSolid),
        ],
      ),
    );
  }

  Widget _buildStatusHero(
    BuildContext context,
    ThemeData theme,
    Color primary,
    int trackCount,
    int folderCount,
    bool timerActive,
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
                  icon: HugeIcons.strokeRoundedFolderLibrary,
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
                      'LIBRARY INDEX & PERSISTENCE',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Local media indexer, auto-sync watchers & gradual sleep timer',
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
                label: 'Indexed: $trackCount Tracks',
                isActive: trackCount > 0,
                color: primary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Folders: $folderCount Sources',
                isActive: folderCount > 0,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: timerActive ? 'Sleep Timer: Active' : 'Sleep Timer: Idle',
                isActive: timerActive,
                color: timerActive ? const Color(0xFF00E676) : theme.colorScheme.outline,
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

  Widget _buildSleepTimerCard(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final timerState = ref.watch(sleepTimerControllerProvider);
    final timerNotifier = ref.read(sleepTimerControllerProvider.notifier);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
        borderColor: timerState.isActive ? primary.withValues(alpha: 0.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedHourglass,
                    size: 16,
                    color: timerState.isActive ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gradual Fade Sleep Timer',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: timerState.isActive
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          const Color(0xFF00E676),
                          isSolid: isSolid,
                          translucentAlpha: 0.15,
                          solidBlendAlpha: 0.20,
                        )
                      : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timerState.isActive) ...[
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      timerState.isActive ? 'RUNNING' : 'DISABLED',
                      style: TextStyle(
                        color: timerState.isActive
                            ? const Color(0xFF00E676)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (timerState.isActive) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.08,
                  solidBlendAlpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    timerState.formattedRemaining,
                    style: TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timerState.isFadingOut
                              ? 'FADING OUT (15s remaining)'
                              : 'Music will pause at countdown end',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: timerState.isFadingOut
                                ? const Color(0xFFFF9F0A)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timerState.stopAtEndOfTrack
                              ? 'Wait for end of track enabled'
                              : (timerState.enableFadeOut ? '15s gradual fade active' : 'Direct stop'),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: M3EButton.outlined(
                    onPressed: () {
                      AppHaptics.lightImpact();
                      timerNotifier.extendTimer(15);
                    },
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 14, color: primary),
                    label: Text(
                      '+15m Extend',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: M3EButton.outlined(
                    onPressed: () {
                      AppHaptics.lightImpact();
                      timerNotifier.cancelTimer();
                    },
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 14, color: Color(0xFFFF3B30)),
                    label: const Text(
                      'Cancel Timer',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF3B30)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Automated audio sleep timer with gentle 15-second volume attenuation curve to prevent abrupt silence.',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [15, 30, 45, 60].map((mins) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: M3EButton.outlined(
                      onPressed: () {
                        AppHaptics.selectionClick();
                        timerNotifier.startTimer(mins);
                      },
                      label: Text(
                        '${mins}m',
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: M3EButton(
              style: M3EButtonStyle.text,
              onPressed: () => SleepTimerSheet.show(context),
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSlidersHorizontal, size: 14, color: primary),
              label: Text(
                'Open Full Sleep Timer Sheet',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFoldersCard(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final folders = libraryState.configuredFolderPaths;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configured Music Folders (${folders.length})',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              if (libraryState.isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: M3EProgressIndicator.circular(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Baydev HiFi automatically scans all subdirectories of these configured folders for lossless & Hi-Res audio files.',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.3),
          ),
          const SizedBox(height: 12),
          if (folders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No custom music folders configured.\nTap "+ Add Music Folder" to select your audio storage location.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4),
                ),
              ),
            )
          else
            ...folders.map(
              (path) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        path,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 20, color: Color(0xFFFF453A)),
                      tooltip: 'Remove Folder',
                      onPressed: () {
                        AppHaptics.lightImpact();
                        controller.removeMusicFolder(path);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed folder: $path')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (libraryState.isScanning) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.1,
                  solidBlendAlpha: 0.16,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: M3EProgressIndicator.circular(strokeWidth: 2, color: primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      libraryState.statusMessage ?? 'Scanning music folders...',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: M3EButton.filled(
                  onPressed: libraryState.isScanning
                      ? null
                      : () {
                          AppHaptics.mediumImpact();
                          controller.pickAndScanDirectory();
                        },
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: theme.colorScheme.onPrimary),
                  label: const Text('Add Music Folder', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              M3EButton.outlined(
                onPressed: libraryState.isScanning
                    ? null
                    : () {
                        AppHaptics.lightImpact();
                        controller.rescanSavedFolders();
                      },
                icon: HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 16, color: primary),
                label: Text(
                  libraryState.isScanning ? 'Scanning...' : 'Rescan',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryRulesCard(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final storage = LocalPersistenceService.instance;

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
          _buildBentoDropdownSelector<int>(
            context: context,
            title: 'MINIMUM AUDIO DURATION FILTER',
            currentValue: _minTrackDurationSeconds,
            items: const [0, 15, 30, 60],
            itemLabel: (sec) => sec == 0 ? 'No Filter (Include All Tracks)' : 'Ignore Audio < $sec Seconds',
            itemDescription: (sec) => sec == 0
                ? 'Include all short audio clips, ringtones, and sound effects in library'
                : 'Automatically hide ringtones, alarms, and short recordings under $sec s',
            itemIcon: (sec) => sec == 0 ? HugeIcons.strokeRoundedVolumeHigh : HugeIcons.strokeRoundedFilter,
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                setState(() => _minTrackDurationSeconds = val);
                storage.saveSetting('minimum_track_duration_seconds', val);
                storage.saveSetting('ignore_short_tracks', val > 0);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Scan on App Startup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically sync newly added local tracks in background on launch',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: _autoScanOnStartup,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  setState(() => _autoScanOnStartup = val);
                  storage.saveSetting('auto_scan_on_startup', val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoDropdownSelector<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemDescription,
    required dynamic Function(T) itemIcon,
    required ValueChanged<T?> onChanged,
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
              onChanged: onChanged,
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
}

