import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/player_customization_settings.dart';
import '../controllers/player_customization_controller.dart';

class VisualizerSettingsScreen extends ConsumerWidget {
  const VisualizerSettingsScreen({super.key});

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
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildStatusHero(context, theme, primary, settings, isSolid),
          const SizedBox(height: 18),

          // ─── 2. ALBUM ART & COVER DISPLAY (COMBOBOX) ────────────────────────
          _buildBentoDropdownSelector<AlbumArtStyle>(
            context: context,
            sectionTitle: 'ALBUM ART & COVER STYLE',
            sectionIcon: HugeIcons.strokeRoundedAlbum01,
            currentValue: settings.albumArtStyle,
            items: AlbumArtStyle.values,
            itemLabel: (s) => s.label,
            itemDescription: (s) => s.description,
            itemIcon: _getAlbumStyleIcon,
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                controller.setAlbumArtStyle(val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 14),

          // ─── 3. SPECTRUM VISUALIZER STYLING ─────────────────────────────────
          _buildSpectrumVisualizerCard(context, theme, primary, settings, controller, isSolid),
          const SizedBox(height: 14),

          // ─── 4. TIME BAR & SEEKBAR STYLING ──────────────────────────────────
          _buildBentoDropdownSelector<TimeBarStyle>(
            context: context,
            sectionTitle: 'TIME BAR & SEEKBAR STYLE',
            sectionIcon: HugeIcons.strokeRoundedSlidersVertical,
            currentValue: settings.timeBarStyle,
            items: TimeBarStyle.values,
            itemLabel: (s) => s.label,
            itemDescription: (s) => s.description,
            itemIcon: _getTimeBarStyleIcon,
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                controller.setTimeBarStyle(val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 14),

          // ─── 5. PERFORMANCE PROFILE ─────────────────────────────────────────
          _buildBentoDropdownSelector<PerformanceMode>(
            context: context,
            sectionTitle: 'ADAPTIVE PERFORMANCE PROFILE',
            sectionIcon: HugeIcons.strokeRoundedCpuCharge,
            currentValue: settings.performanceMode,
            items: PerformanceMode.values,
            itemLabel: (m) => m.label,
            itemDescription: (m) => m.description,
            itemIcon: _getPerfModeIcon,
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                controller.setPerformanceMode(val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 20),

          // ─── 6. 3D PARALLAX & MOTION PHYSICS ────────────────────────────────
          _buildSectionHeader(
            context,
            '3D PARALLAX MOTION & BREATHING PULSE',
            HugeIcons.strokeRoundedLayers01,
          ),
          const SizedBox(height: 8),
          _buildParallaxCard(context, theme, primary, settings, controller, isSolid),
          const SizedBox(height: 20),

          // ─── 7. BACKDROP BLUR & AMBIENT GLOW ────────────────────────────────
          _buildSectionHeader(
            context,
            'DYNAMIC BACKDROP BLUR & AMBIENT GLOW',
            HugeIcons.strokeRoundedSparkles,
          ),
          const SizedBox(height: 8),
          _buildBlurGlowCard(context, theme, primary, settings, controller, isSolid),
        ],
      ),
    );
  }

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
                  icon: HugeIcons.strokeRoundedSparkles,
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
                      'STUDIO VISUAL DYNAMICS',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'RTA spectrum styling, dynamic artwork skins & 3D parallax shaders',
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
                label: 'Art: ${settings.albumArtStyle.label}',
                isActive: true,
                color: primary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Spectrum: ${settings.spectrumStyle.label}',
                isActive: true,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Seekbar: ${settings.timeBarStyle.label}',
                isActive: true,
                color: theme.colorScheme.tertiary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Perf: ${settings.performanceMode.label.split('(').first.trim()}',
                isActive: true,
                color: primary,
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

  /// Compact, high-density Bento Dropdown (ComboBox) Selector
  Widget _buildBentoDropdownSelector<T>({
    required BuildContext context,
    required String sectionTitle,
    required dynamic sectionIcon,
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
              HugeIcon(icon: sectionIcon, size: 15, color: primary),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown ComboBox Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: currentValue,
                isExpanded: true,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                dropdownColor: isSolid
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                items: items.map((item) {
                  final isSelected = item == currentValue;
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: itemIcon(item),
                          size: 18,
                          color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            itemLabel(item),
                            style: TextStyle(
                              fontSize: 12,
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
          ),
          const SizedBox(height: 6),

          // Active Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              itemDescription(currentValue),
              style: TextStyle(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumVisualizerCard(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedAudioWaveform, size: 15, color: primary),
              const SizedBox(width: 8),
              Text(
                'RTA SPECTRUM VISUALIZER',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Spectrum Style Dropdown ComboBox
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: isSolid
                  ? theme.colorScheme.surfaceContainerHighest
                  : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SpectrumStyle>(
                value: settings.spectrumStyle,
                isExpanded: true,
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                dropdownColor: isSolid
                    ? theme.colorScheme.surfaceContainerHigh
                    : theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                items: SpectrumStyle.values.map((style) {
                  final isSelected = style == settings.spectrumStyle;
                  return DropdownMenuItem<SpectrumStyle>(
                    value: style,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: _getSpectrumStyleIcon(style),
                          size: 18,
                          color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 12,
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
                    controller.setSpectrumStyle(val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              settings.spectrumStyle.description,
              style: TextStyle(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
          const SizedBox(height: 10),

          // FFT Resolution Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FFT Frequency Resolution',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Analysis frequency bin density',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isSolid
                      ? theme.colorScheme.surfaceContainerHighest
                      : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: settings.fftBins,
                    dropdownColor: isSolid
                        ? theme.colorScheme.surfaceContainerHigh
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    items: [256, 512, 1024, 2048].map((bins) {
                      return DropdownMenuItem(
                        value: bins,
                        child: Text(
                          '$bins Bins',
                          style: TextStyle(
                            fontFeatures: AppTypography.audioFigures,
                            fontSize: 11,
                            fontWeight: bins == settings.fftBins ? FontWeight.w800 : FontWeight.w500,
                            color: bins == settings.fftBins ? primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        AppHaptics.selectionClick();
                        controller.setFftBins(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParallaxCard(
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
            title: '3D Motion Parallax Artwork',
            subtitle: 'Smooth perspective tilt responding to touch drag & pointer hover',
            value: settings.enableParallax,
            onChanged: (val) => controller.setEnableParallax(val),
          ),
          if (settings.enableParallax) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tilt Intensity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                _buildValueBadge(context, theme, primary, '${(settings.parallaxIntensity * 100).toInt()} %', isSolid),
              ],
            ),
            Slider(
              value: settings.parallaxIntensity,
              min: 0.2,
              max: 2.0,
              divisions: 18,
              activeColor: primary,
              onChanged: (val) => controller.setParallaxIntensity(val),
            ),
          ],
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Audio-Reactive Bass Pulse',
            subtitle: 'Subtle organic breathing scale pulsing with low-frequency sub-bass',
            value: settings.enableBreathingPulse,
            onChanged: (val) => controller.setEnableBreathingPulse(val),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurGlowCard(
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
            title: 'Gaussian Backdrop Blur',
            subtitle: 'Glassmorphic blur on floating capsule dock and bottom sheets',
            value: settings.enableBackdropBlur,
            onChanged: (val) => controller.setEnableBackdropBlur(val),
          ),
          if (settings.enableBackdropBlur) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Blur Sigma', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                _buildValueBadge(context, theme, primary, '${settings.blurSigma.toInt()} px', isSolid),
              ],
            ),
            Slider(
              value: settings.blurSigma,
              min: 4.0,
              max: 30.0,
              divisions: 26,
              activeColor: primary,
              onChanged: (val) => controller.setBlurSigma(val),
            ),
          ],
          const Divider(height: 16),
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Dynamic Ambient Artwork Glow',
            subtitle: 'Radiates real-time soft atmospheric color aura behind album art',
            value: settings.ambientGlow,
            onChanged: (val) => controller.setAmbientGlow(val),
          ),
          if (settings.ambientGlow) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Glow Intensity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                _buildValueBadge(context, theme, primary, '${(settings.ambientGlowIntensity * 100).toInt()} %', isSolid),
              ],
            ),
            Slider(
              value: settings.ambientGlowIntensity,
              min: 0.1,
              max: 1.0,
              divisions: 18,
              activeColor: primary,
              onChanged: (val) => controller.setAmbientGlowIntensity(val),
            ),
          ],
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

  Widget _buildValueBadge(BuildContext context, ThemeData theme, Color primary, String text, bool isSolid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFeatures: AppTypography.audioFigures,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primary,
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
      case AlbumArtStyle.square:
        return HugeIcons.strokeRoundedGridTable;
      case AlbumArtStyle.disc:
        return HugeIcons.strokeRoundedDisc;
      case AlbumArtStyle.vinyl:
        return HugeIcons.strokeRoundedAlbum01;
      case AlbumArtStyle.turntable:
        return HugeIcons.strokeRoundedDisc;
      case AlbumArtStyle.cassette:
        return HugeIcons.strokeRoundedRadio;
      case AlbumArtStyle.cdJewel:
        return HugeIcons.strokeRoundedSquareLock02;
    }
  }

  dynamic _getSpectrumStyleIcon(SpectrumStyle style) {
    switch (style) {
      case SpectrumStyle.m3Expressive:
        return HugeIcons.strokeRoundedSparkles;
      case SpectrumStyle.bars:
        return HugeIcons.strokeRoundedAudioWaveform;
      case SpectrumStyle.wave:
        return HugeIcons.strokeRoundedActivity01;
      case SpectrumStyle.dots:
        return HugeIcons.strokeRoundedGrid;
      case SpectrumStyle.beam:
        return HugeIcons.strokeRoundedMinusSign;
      case SpectrumStyle.mirrorWave:
        return HugeIcons.strokeRoundedLayers01;
      case SpectrumStyle.vuMeter:
        return HugeIcons.strokeRoundedDashboardSpeed01;
      case SpectrumStyle.circular:
        return HugeIcons.strokeRoundedCompass01;
    }
  }

  dynamic _getTimeBarStyleIcon(TimeBarStyle style) {
    switch (style) {
      case TimeBarStyle.slim:
        return HugeIcons.strokeRoundedSlidersVertical;
      case TimeBarStyle.wavy:
        return HugeIcons.strokeRoundedAudioWaveform;
      case TimeBarStyle.capsule:
        return HugeIcons.strokeRoundedClock01;
      case TimeBarStyle.segmented:
        return HugeIcons.strokeRoundedVolumeHigh;
      case TimeBarStyle.waveform:
        return HugeIcons.strokeRoundedAudioWaveform;
      case TimeBarStyle.ruler:
        return HugeIcons.strokeRoundedRuler;
      case TimeBarStyle.glowingPill:
        return HugeIcons.strokeRoundedSquare;
    }
  }
}
