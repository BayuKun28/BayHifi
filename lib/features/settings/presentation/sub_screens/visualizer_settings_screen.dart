import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../domain/player_customization_settings.dart';
import '../controllers/player_customization_controller.dart';

class VisualizerSettingsScreen extends ConsumerWidget {
  const VisualizerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(playerCustomizationProvider);
    final controller = ref.read(playerCustomizationProvider.notifier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('VISUAL DYNAMICS & DISPLAY'),
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
          // 1. PERFORMANCE MODE SELECTOR
          _buildSectionHeader(
            context,
            'ADAPTIVE PERFORMANCE PROFILE',
            HugeIcons.strokeRoundedCpuCharge,
          ),
          const SizedBox(height: 8),
          _buildPerformanceModeCard(context, settings, controller),
          const SizedBox(height: 20),

          // 2. 3D PARALLAX & MOTION PHYSICS
          _buildSectionHeader(
            context,
            '3D PARALLAX MOTION & BREATHING PULSE',
            HugeIcons.strokeRoundedLayers01,
          ),
          const SizedBox(height: 8),
          _buildParallaxCard(context, settings, controller),
          const SizedBox(height: 20),

          // 3. BACKDROP BLUR & AMBIENT GLOW
          _buildSectionHeader(
            context,
            'DYNAMIC BACKDROP BLUR & AMBIENT GLOW',
            HugeIcons.strokeRoundedSparkles,
          ),
          const SizedBox(height: 8),
          _buildBlurGlowCard(context, settings, controller),
          const SizedBox(height: 20),

          // 4. ALBUM ART & COVER DISPLAY
          _buildSectionHeader(
            context,
            'ALBUM ART & COVER STYLE',
            HugeIcons.strokeRoundedAlbum01,
          ),
          const SizedBox(height: 8),
          _buildAlbumArtCard(context, settings, controller),
          const SizedBox(height: 20),

          // 5. SPECTRUM VISUALIZER STYLING
          _buildSectionHeader(
            context,
            'RTA SPECTRUM VISUALIZER',
            HugeIcons.strokeRoundedAudioWaveform,
          ),
          const SizedBox(height: 8),
          _buildSpectrumCard(context, settings, controller),
          const SizedBox(height: 20),

          // 6. TIME BAR & SEEKBAR STYLING
          _buildSectionHeader(
            context,
            'TIME BAR & SEEKBAR STYLE',
            HugeIcons.strokeRoundedSlidersVertical,
          ),
          const SizedBox(height: 8),
          _buildTimeBarCard(context, settings, controller),
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

  Widget _buildPerformanceModeCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target Rendering & Refresh Profile',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: PerformanceMode.values.map((mode) {
                final isSel = settings.performanceMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setPerformanceMode(mode);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? primary : theme.dividerColor.withValues(alpha: 0.4),
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: _getPerfModeIcon(mode),
                            size: 18,
                            color: isSel ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.description,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSel)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              size: 16,
                              color: primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParallaxCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.enableParallax,
              title: const Text(
                '3D Motion Parallax Artwork',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Smooth perspective tilt responding to touch drag and pointer hover',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setEnableParallax(val);
              },
            ),
            if (settings.enableParallax) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tilt Intensity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text('${(settings.parallaxIntensity * 100).toInt()}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.parallaxIntensity,
                min: 0.2,
                max: 2.0,
                divisions: 18,
                onChanged: (val) => controller.setParallaxIntensity(val),
              ),
            ],
            const Divider(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.enableBreathingPulse,
              title: const Text(
                'Audio-Reactive Bass Pulse',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Subtle organic breathing scale pulsing with low-frequency sub-bass',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setEnableBreathingPulse(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurGlowCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.enableBackdropBlur,
              title: const Text(
                'Gaussian Backdrop Blur',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Glassmorphic blur on floating capsule dock and bottom sheets',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setEnableBackdropBlur(val);
              },
            ),
            if (settings.enableBackdropBlur) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Blur Sigma', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text('${settings.blurSigma.toInt()} px', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.blurSigma,
                min: 4.0,
                max: 30.0,
                divisions: 26,
                onChanged: (val) => controller.setBlurSigma(val),
              ),
            ],
            const Divider(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.ambientGlow,
              title: const Text(
                'Dynamic Ambient Artwork Glow',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Radiates real-time soft atmospheric color aura behind the album art',
                style: TextStyle(fontSize: 10.5),
              ),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.setAmbientGlow(val);
              },
            ),
            if (settings.ambientGlow) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Glow Intensity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  Text('${(settings.ambientGlowIntensity * 100).toInt()}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: settings.ambientGlowIntensity,
                min: 0.1,
                max: 1.0,
                divisions: 18,
                onChanged: (val) => controller.setAmbientGlowIntensity(val),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cover Artwork Display Mode',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: AlbumArtStyle.values.map((style) {
                final isSel = settings.albumArtStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setAlbumArtStyle(style);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? primary : theme.dividerColor.withValues(alpha: 0.4),
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: _getAlbumStyleIcon(style),
                            size: 18,
                            color: isSel ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  style.description,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSel)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              size: 16,
                              color: primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpectrumCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visualizer Rendering Style',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SpectrumStyle.values.map((style) {
                final isSel = settings.spectrumStyle == style;
                return ChoiceChip(
                  label: Text(style.label),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) {
                      HapticFeedback.selectionClick();
                      controller.setSpectrumStyle(style);
                    }
                  },
                  selectedColor: primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSel ? primary : theme.colorScheme.onSurface,
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FFT Frequency Resolution',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                DropdownButton<int>(
                  value: settings.fftBins,
                  underline: const SizedBox(),
                  dropdownColor: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  items: [256, 512, 1024, 2048].map((bins) {
                    return DropdownMenuItem(
                      value: bins,
                      child: Text('$bins Bins', style: const TextStyle(fontSize: 11)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      controller.setFftBins(val);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBarCard(
    BuildContext context,
    PlayerCustomizationSettings settings,
    PlayerCustomizationNotifier controller,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seekbar & Track Progress Style',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: TimeBarStyle.values.map((style) {
                final isSel = settings.timeBarStyle == style;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setTimeBarStyle(style);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel
                            ? primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSel ? primary : theme.dividerColor.withValues(alpha: 0.4),
                          width: isSel ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: _getTimeBarStyleIcon(style),
                            size: 18,
                            color: isSel ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  style.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSel ? primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  style.description,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSel)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              size: 16,
                              color: primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  dynamic _getPerfModeIcon(PerformanceMode mode) {
    switch (mode) {
      case PerformanceMode.studioHiFi:
        return HugeIcons.strokeRoundedCpuCharge;
      case PerformanceMode.balanced:
        return HugeIcons.strokeRoundedActivity01;
      case PerformanceMode.batterySaver:
        return HugeIcons.strokeRoundedBatteryCharging01;
      case PerformanceMode.custom:
        return HugeIcons.strokeRoundedSlidersVertical;
    }
  }

  dynamic _getAlbumStyleIcon(AlbumArtStyle style) {
    switch (style) {
      case AlbumArtStyle.squircle:
        return HugeIcons.strokeRoundedSparkles;
      case AlbumArtStyle.vinyl:
        return HugeIcons.strokeRoundedAlbum01;
      case AlbumArtStyle.square:
        return HugeIcons.strokeRoundedGridTable;
      case AlbumArtStyle.disc:
        return HugeIcons.strokeRoundedRadio;
    }
  }

  dynamic _getTimeBarStyleIcon(TimeBarStyle style) {
    switch (style) {
      case TimeBarStyle.slim:
        return HugeIcons.strokeRoundedSlidersVertical;
      case TimeBarStyle.capsule:
        return HugeIcons.strokeRoundedClock01;
      case TimeBarStyle.segmented:
        return HugeIcons.strokeRoundedVolumeHigh;
      case TimeBarStyle.waveform:
        return HugeIcons.strokeRoundedAudioWaveform;
    }
  }
}
