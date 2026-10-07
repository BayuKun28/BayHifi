import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../data/playback_analytics_service.dart';
import '../../domain/studio_wrapped_data.dart';
import '../templates/studio_wrapped_export_hub.dart';

class StudioWrappedStoryScreen extends ConsumerStatefulWidget {
  const StudioWrappedStoryScreen({super.key});

  @override
  ConsumerState<StudioWrappedStoryScreen> createState() => _StudioWrappedStoryScreenState();
}

class _StudioWrappedStoryScreenState extends ConsumerState<StudioWrappedStoryScreen>
    with SingleTickerProviderStateMixin {
  static const int _kTotalSlides = 7;
  static const Duration _kSlideDuration = Duration(seconds: 7);

  int _currentSlideIndex = 0;
  late AnimationController _progressController;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _kSlideDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _advanceSlide();
        }
      });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _advanceSlide() {
    if (_currentSlideIndex < _kTotalSlides - 1) {
      setState(() {
        _currentSlideIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      // Completed all slides - stop at last slide
      _progressController.stop();
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _onTapDown(TapDownDetails details, double screenWidth) {
    if (details.globalPosition.dx < screenWidth * 0.35) {
      _previousSlide();
    } else {
      _advanceSlide();
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      setState(() => _isPaused = true);
      _progressController.stop();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      setState(() => _isPaused = false);
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final wrappedData = ref.watch(studioWrappedDataProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: (details) => _onTapDown(details, size.width),
          onLongPressStart: (_) => _pauseStory(),
          onLongPressEnd: (_) => _resumeStory(),
          child: Stack(
            children: [
              // ─── 1. BACKGROUND GLOW / STUDIO BACKDROP ─────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                  ),
                ),
              ),

              // ─── 2. ACTIVE SLIDE CONTENT ──────────────────────────
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentSlideIndex),
                      child: _buildSlideContent(_currentSlideIndex, wrappedData, theme, isSolid),
                    ),
                  ),
                ),
              ),

              // ─── 3. TOP PROGRESS BARS & HEADER ────────────────────
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Multi-Segment Story Progress Bars
                    Row(
                      children: List.generate(_kTotalSlides, (index) {
                        return Expanded(
                          child: Container(
                            height: 3.5,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double fill = 0.0;
                                if (index < _currentSlideIndex) {
                                  fill = 1.0;
                                } else if (index == _currentSlideIndex) {
                                  fill = _progressController.value;
                                }
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: fill,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),

                    // Top Header Bar with Close & Gallery Button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedSparkles,
                                size: 11,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BAYDEV HIFI 2026',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Open Gallery / Export Hub Button
                        IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18, color: Colors.white),
                          tooltip: 'Recap Templates & Share',
                          onPressed: () {
                            _pauseStory();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StudioWrappedExportHub()),
                            ).then((_) => _resumeStory());
                          },
                        ),
                        // Close Story Button
                        IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 20, color: Colors.white),
                          tooltip: 'Close Story',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
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

  Widget _buildSlideContent(int index, StudioWrappedData data, ThemeData theme, bool isSolid) {
    switch (index) {
      case 0:
        return _buildSlide1Welcome(data, theme, isSolid);
      case 1:
        return _buildSlide2TopTracks(data, theme, isSolid);
      case 2:
        return _buildSlide3TopArtists(data, theme, isSolid);
      case 3:
        return _buildSlide4AudioPurity(data, theme, isSolid);
      case 4:
        return _buildSlide5DspMastery(data, theme, isSolid);
      case 5:
        return _buildSlide6HardwareDac(data, theme, isSolid);
      case 6:
      default:
        return _buildSlide7PersonaGrandReveal(data, theme, isSolid);
    }
  }

  // ─── SLIDE 1: WELCOME & LISTENING TIME ─────────────────────────────────────
  Widget _buildSlide1Welcome(StudioWrappedData data, ThemeData theme, bool isSolid) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedHeadphones,
              size: 42,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'YOUR 2026 AUDIOPHILE JOURNEY',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'A Year in Pure Sound',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // Big Listening Time Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
          ),
          child: Column(
            children: [
              Text(
                data.totalListeningMinutes.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'MINUTES STREAMED & PLAYED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatPill('TRACKS', '${data.totalTracksPlayed}', HugeIcons.strokeRoundedMusicNote01, theme),
                  _buildStatPill('ARTISTS', '${data.totalUniqueArtists}', HugeIcons.strokeRoundedUserGroup, theme),
                  _buildStatPill('DAYS ACTIVE', '${data.activeListeningDays}', HugeIcons.strokeRoundedCalendar03, theme),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SLIDE 2: TOP TRACKS COUNTDOWN ─────────────────────────────────────────
  Widget _buildSlide2TopTracks(StudioWrappedData data, ThemeData theme, bool isSolid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedMusicNote03, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'TOP TRACKS OF 2026',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Your Heavy Rotation',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // List of Top 5 Tracks
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.topTracks.take(5).length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final track = data.topTracks[index];
              final isNumberOne = index == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isNumberOne
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isNumberOne
                        ? theme.colorScheme.primary.withValues(alpha: 0.6)
                        : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                    width: isNumberOne ? 1.4 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isNumberOne ? theme.colorScheme.primary : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${track.rank}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isNumberOne ? Colors.black : Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Track Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play count & duration
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${track.playCount} PLAYS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '${track.totalDuration.inMinutes} MIN',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── SLIDE 3: TOP ARTISTS & GENRES ─────────────────────────────────────────
  Widget _buildSlide3TopArtists(StudioWrappedData data, ThemeData theme, bool isSolid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'SONIC INSPIRATIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Top Artists & Genres',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 16),

        // Number 1 Artist Spotlight
        if (data.topArtists.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 26, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#1 TOP ARTIST',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.topArtists.first.artist,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.topArtists.first.minutesListened} minutes streamed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Other Top Artists
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.topArtists.skip(1).take(4).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final artist = data.topArtists[index + 1];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
                ),
                child: Row(
                  children: [
                    Text(
                      '#${artist.rank}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        artist.artist,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${artist.minutesListened}m',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white54,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Genre Tags
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: data.topGenres.take(4).map((g) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 0.6),
              ),
              child: Text(
                '${g.genre.toUpperCase()} ${(g.percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── SLIDE 4: AUDIOPHILE PURITY & BIT-PERFECT ──────────────────────────────
  Widget _buildSlide4AudioPurity(StudioWrappedData data, ThemeData theme, bool isSolid) {
    final purity = data.audioPurityReport;
    final flacPercent = (purity.losslessFlacRatio * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedAudioWaveform, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'SIGNAL INTEGRITY & PURITY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Bit-Perfect Signal Path',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),

        // Purity Main Gauge Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
          ),
          child: Column(
            children: [
              Text(
                '$flacPercent%',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: -1.0,
                ),
              ),
              const Text(
                'HI-RES LOSSLESS / FLAC RATIO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              // Segmented visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: flacPercent,
                        child: Container(color: theme.colorScheme.primary),
                      ),
                      Expanded(
                        flex: (100 - flacPercent).clamp(1, 100),
                        child: Container(color: Colors.white24),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid of Audiophile Metrics
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricCard('BIT-PERFECT HOURS', '${purity.bitPerfectHours}h', HugeIcons.strokeRoundedCheckmarkCircle02, theme, isSolid),
              _buildMetricCard('HIGHEST SAMPLE RATE', purity.highestSampleRate, HugeIcons.strokeRoundedCpuCharge, theme, isSolid),
              _buildMetricCard('MASTER 192/24 TRACKS', '${purity.master24BitTracks}', HugeIcons.strokeRoundedAward01, theme, isSolid),
              _buildMetricCard('STREAMING LOSSLESS', '${(purity.opusHighQualityRatio * 100).toInt()}%', HugeIcons.strokeRoundedAudioWave01, theme, isSolid),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SLIDE 5: DSP & TUNING MASTERY ─────────────────────────────────────────
  Widget _buildSlide5DspMastery(StudioWrappedData data, ThemeData theme, bool isSolid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedSlidersVertical, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'DSP & ACOUSTIC TUNING',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Target Curve Mastery',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 18),

        // AutoEQ Favorite Target Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedTarget01, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'MOST USED AUTOEQ TARGET',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data.topAutoEqTarget,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Tuned for headphone: ${data.favoriteHeadphoneProfile}',
                style: const TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Analog Flavor & PEQ Stats
        Expanded(
          child: Column(
            children: [
              _buildDspStatRow(
                'ANALOG TUBE WARMTH SATURATION',
                '${data.tubeWarmthHours} Hours Engaged',
                HugeIcons.strokeRoundedEnergy,
                theme,
                isSolid,
              ),
              const SizedBox(height: 10),
              _buildDspStatRow(
                'PARAMETRIC EQ BANDS CALIBRATED',
                '${data.peqBandsEngaged} Active Filter Nodes',
                HugeIcons.strokeRoundedSettings01,
                theme,
                isSolid,
              ),
              const SizedBox(height: 10),
              _buildDspStatRow(
                'IMMERSIVE CROSSFEED / SPATIAL',
                '${data.crossfeedListeningHours} Hours Active',
                HugeIcons.strokeRoundedLayers01,
                theme,
                isSolid,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SLIDE 6: HARDWARE & DAC JOURNEY ───────────────────────────────────────
  Widget _buildSlide6HardwareDac(StudioWrappedData data, ThemeData theme, bool isSolid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedUsb, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'HARDWARE & DAC BRIDGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Audiophile Signal Engine',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),

        // Favorite DAC Device Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedCpuCharge, size: 30, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.favoriteDacDevice.toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'PRIMARY USB OTG / DESKTOP DAC',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1.0),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.totalDacBridgeHours} Hours Direct Bit-Perfect Bridge',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Headphone profile summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
          ),
          child: Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedHeadphones, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REFERENCE HEADPHONE PROFILE',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.favoriteHeadphoneProfile,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SLIDE 7: AUDIOPHILE PERSONA & GRAND REVEAL ───────────────────────────
  Widget _buildSlide7PersonaGrandReveal(StudioWrappedData data, ThemeData theme, bool isSolid) {
    final persona = data.persona;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary, width: 1),
            ),
            child: Text(
              'YOUR 2026 AUDIOPHILE ARCHETYPE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Big Persona Icon Badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: HugeIcon(
                icon: persona.icon,
                size: 38,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Persona Title & Subtitle
          Text(
            persona.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            persona.subtitle.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Persona Description Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
            ),
            child: Text(
              persona.description,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),

          // Persona Sound Signature Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: persona.soundSignatureTags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Primary Action: Open Export Hub
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () {
                _pauseStory();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudioWrappedExportHub()),
                );
              },
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18, color: Colors.black),
              label: const Text(
                'EXPORT & SHARE RECAP CARDS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary Action: Replay Story
          TextButton.icon(
            onPressed: () {
              setState(() {
                _currentSlideIndex = 0;
              });
              _progressController.reset();
              _progressController.forward();
            },
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedRepeat, size: 14, color: Colors.white60),
            label: const Text(
              'REPLAY RECAP STORY',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────
  Widget _buildStatPill(String label, String value, dynamic icon, ThemeData theme) {
    return Column(
      children: [
        HugeIcon(icon: icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, dynamic icon, ThemeData theme, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              HugeIcon(icon: icon, size: 14, color: theme.colorScheme.primary),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDspStatRow(String title, String subtitle, dynamic icon, ThemeData theme, bool isSolid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 0.8),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
