import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
  bool _ignoreShortTracks = true;
  bool _autoScanOnStartup = true;

  @override
  void initState() {
    super.initState();
    final storage = LocalPersistenceService.instance;
    _ignoreShortTracks = storage.getSetting<bool>('ignore_short_tracks', true)!;
    _autoScanOnStartup = storage.getSetting<bool>('auto_scan_on_startup', true)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('LIBRARY SCANNER & SLEEP TIMER'),
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
          // 1. MUSIC SOURCE FOLDERS
          _buildSectionHeader(context, 'MUSIC SOURCE FOLDERS', HugeIcons.strokeRoundedFolderLibrary),
          const SizedBox(height: 8),
          _buildSourceFoldersCard(context, isSolid),
          const SizedBox(height: 20),

          // 2. SMART SLEEP TIMER
          _buildSectionHeader(context, 'SMART SLEEP TIMER', HugeIcons.strokeRoundedHourglass),
          const SizedBox(height: 8),
          _buildSleepTimerCard(context, isSolid),
          const SizedBox(height: 20),

          // 3. LIBRARY SCANNER RULES
          _buildSectionHeader(context, 'LIBRARY SCANNER RULES', HugeIcons.strokeRoundedFolder01),
          const SizedBox(height: 8),
          _buildLibraryRulesCard(context, isSolid),
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

  Widget _buildSleepTimerCard(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final timerState = ref.watch(sleepTimerControllerProvider);
    final timerNotifier = ref.read(sleepTimerControllerProvider.notifier);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 12,
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
                      fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: timerState.isActive
                        ? const Color(0xFF00E676).withValues(alpha: 0.6)
                        : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                    width: 0.8,
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.08,
                  solidBlendAlpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primary.withValues(alpha: 0.25),
                  width: 0.8,
                ),
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
                  const SizedBox(width: 12),
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => timerNotifier.extendTimer(15),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 14, color: primary),
                    label: Text(
                      '+15m Extend',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: const Color(0xFFFF3B30).withValues(alpha: 0.4), width: 0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => timerNotifier.cancelTimer(),
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
            const SizedBox(height: 10),
            Row(
              children: [15, 30, 45, 60].map((mins) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        side: BorderSide(
                          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => timerNotifier.startTimer(mins),
                      child: Text(
                        '${mins}m',
                        style: TextStyle(
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
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
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
      padding: const EdgeInsets.all(14),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 12,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                ),
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
                  border: Border.all(
                    color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  ),
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
                    IconButton(
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: Color(0xFFFF453A)),
                      tooltip: 'Remove Folder',
                      onPressed: () {
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
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primary),
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
                child: FilledButton.icon(
                  onPressed: libraryState.isScanning ? null : () => controller.pickAndScanDirectory(),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 16, color: Colors.black),
                  label: const Text('Add Music Folder', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: libraryState.isScanning ? null : () => controller.rescanSavedFolders(),
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
    final storage = LocalPersistenceService.instance;

    return Material(
      color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _ignoreShortTracks,
              title: const Text('Ignore Audio Files < 30 Seconds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Hide ringtones, notifications, and short audio clips from library', style: TextStyle(fontSize: 10.5)),
              onChanged: (val) {
                setState(() => _ignoreShortTracks = val);
                storage.saveSetting('ignore_short_tracks', val);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoScanOnStartup,
              title: const Text('Auto-Scan on App Startup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Automatically sync newly added local tracks in background', style: TextStyle(fontSize: 10.5)),
              onChanged: (val) {
                setState(() => _autoScanOnStartup = val);
                storage.saveSetting('auto_scan_on_startup', val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
