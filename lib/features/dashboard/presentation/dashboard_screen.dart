import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../library/presentation/controllers/library_controller.dart';
import '../../navidrome/domain/subsonic_models.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../pro_q_studio/presentation/pro_q_studio_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToPlayer;
  final VoidCallback onNavigateToLibrary;
  final VoidCallback onNavigateToDsp;

  const DashboardScreen({
    super.key,
    required this.onNavigateToPlayer,
    required this.onNavigateToLibrary,
    required this.onNavigateToDsp,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playerControllerProvider);
    final track = playback.currentTrack;
    final libraryState = ref.watch(unifiedLibraryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.amberEq,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'BAYDEV HIFI STUDIO',
                              style: AppTypography.badge(color: AppColors.amberEq),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Audiophile Hub & Engine Dashboard',
                          style: AppTypography.title(Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.memory, size: 14, color: AppColors.amberEq),
                        const SizedBox(width: 6),
                        Text(
                          'SoLoud 48kHz',
                          style: AppTypography.badge(color: AppColors.amberEq),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 1. Audio Engine & DSP Rack Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF141924),
                      const Color(0xFF0F1218),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF263040), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AUDIO ENGINE STATUS',
                          style: TextStyle(
                            color: Color(0xFF90A4AE),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BIT-PERFECT DAC READY',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusMetric('Sample Rate', '48.0 kHz', const Color(0xFF00E5FF)),
                        const SizedBox(width: 16),
                        _buildStatusMetric('Engine Buffer', 'Low-Latency', const Color(0xFFFFB74D)),
                        const SizedBox(width: 16),
                        _buildStatusMetric('Auto Headroom', '-4.8 dB', const Color(0xFFEF5350)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Pro-Q Studio Direct Fullscreen Launch Banner
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProQStudioScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1B1A12),
                        const Color(0xFF13130F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.amberEq.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amberEq.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.amberEq.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.amberEq),
                        ),
                        child: const Icon(
                          Icons.equalizer,
                          color: AppColors.amberEq,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRO-Q STUDIO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Buka Fullscreen Landscape Studio • 10-Band Biquad & Target Matching',
                              style: TextStyle(
                                color: Color(0xFFCFD8DC),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.fullscreen,
                        color: AppColors.amberEq,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Now Playing Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: playback.isPlaying ? AppColors.amberEq : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track?.title ?? 'Belum ada lagu diputar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track?.artist ?? 'Buka Player untuk memutar audio',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onNavigateToPlayer,
                      icon: const Icon(Icons.play_circle_fill, size: 36, color: AppColors.amberEq),
                      tooltip: 'Buka Player',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Unified Library & Quick Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10141C),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222936)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onNavigateToLibrary,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'UNIFIED MUSIC LIBRARY',
                                style: TextStyle(
                                  color: Color(0xFF90A4AE),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${libraryState.totalTracksCount} Lagu Tersedia (${libraryState.hiResTracksCount} Hi-Res FLAC)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF90A4AE)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              ref.read(unifiedLibraryProvider.notifier).setFilter(LibrarySourceFilter.all);
                              onNavigateToLibrary();
                            },
                            child: _buildFilterChip('All Sources (${libraryState.totalTracksCount})', true),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              ref.read(unifiedLibraryProvider.notifier).setFilter(LibrarySourceFilter.offline);
                              onNavigateToLibrary();
                            },
                            child: _buildFilterChip('Offline (${libraryState.offlineTracksCount})', false),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              ref.read(unifiedLibraryProvider.notifier).setFilter(LibrarySourceFilter.navidrome);
                              onNavigateToLibrary();
                            },
                            child: _buildFilterChip(
                              'Navidrome (${libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected ? "Connected" : "Offline"})',
                              libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              ref.read(unifiedLibraryProvider.notifier).setFilter(LibrarySourceFilter.hiRes);
                              onNavigateToLibrary();
                            },
                            child: _buildFilterChip('Hi-Res 24-bit (${libraryState.hiResTracksCount})', false),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF78909C),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E2838) : const Color(0xFF141820),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF2A3442),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF90A4AE),
          fontSize: 9.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
