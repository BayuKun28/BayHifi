import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/lyrics/east_asian_romanizer.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/audiophile_stamp_config.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_layout_style.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_sticker_model.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/components/audiophile_telemetry_stamp.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/components/lyric_sticker_badge.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_widget.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/abstract_aura_lyric_view.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/cassette_jcard_lyric_view.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/classic_minimal_card_view.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/cyber_hud_lyric_view.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/polaroid_frame_card_view.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/templates/waveform_quote_card_view.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  const sampleTrack = Track(
    id: 'test-track-1',
    title: 'First Love (初恋)',
    artist: 'Hikaru Utada',
    album: 'First Love',
    duration: Duration(minutes: 4, seconds: 18),
    format: AudioFormat.flac,
    sampleRate: 96000,
    bitDepth: 24,
  );

  final List<LyricsLine> sampleLines = [
    const LyricsLine(
      timestamp: Duration(seconds: 12),
      text: '最後のキスは タバコのflavorがした',
      romanizedText: 'saigo no kisu wa tabako no flavor ga shita',
    ),
    const LyricsLine(
      timestamp: Duration(seconds: 18),
      text: '苦くて切ない香り',
      romanizedText: 'nigakute setsunai kaori',
    ),
    const LyricsLine(
      timestamp: Duration(seconds: 24),
      text: '明日の今頃には',
      romanizedText: 'ashita no imagoro ni wa',
    ),
  ];

  final sampleColors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

  group('Studio Lyric Card Evolution — Domain Models', () {
    test('LyricCardLayoutStyle contains all 6 distinct studio templates', () {
      expect(LyricCardLayoutStyle.values.length, 6);
      expect(LyricCardLayoutStyle.classicMinimal.label, 'Classic Studio');
      expect(LyricCardLayoutStyle.polaroidFrame.label, 'Polaroid Frame');
      expect(LyricCardLayoutStyle.cassetteJCard.label, 'Cassette J-Card');
      expect(LyricCardLayoutStyle.waveformQuote.label, 'Waveform Timeline');
      expect(LyricCardLayoutStyle.cyberHUD.label, 'CyberSpec HUD');
      expect(LyricCardLayoutStyle.abstractAura.label, 'Abstract Aura');
      expect(LyricCardLayoutStyle.classicMinimal.subtitle, isNotEmpty);
    });

    test('LyricStickerType contains all 6 studio stickers & proper badges', () {
      expect(LyricStickerType.values.length, 6);
      for (final type in LyricStickerType.values) {
        expect(type.label, isNotEmpty);
        expect(type.description, isNotEmpty);
        expect(type.badgeColor, isNotNull);
        expect(type.icon, isNotNull);
      }
    });

    test('AudiophileStampConfig handles defaults, copyWith and getters', () {
      const stamp = AudiophileStampConfig();
      expect(stamp.enabled, isTrue);
      expect(stamp.showFormatRate, isTrue);
      expect(stamp.showAutoEqProfile, isTrue);
      expect(stamp.showVirtualDspChain, isTrue);
      expect(stamp.showHardwareDac, isTrue);
      expect(stamp.showTimestamp, isTrue);
      expect(stamp.effectiveAutoEqName, 'Harman Target (Default)');
      expect(stamp.effectiveDspChainName, 'Tube + Limiter DSP');
      expect(stamp.effectiveDacName, 'Bit-Perfect Direct Out');
      expect(stamp.hasAnyEnabled, isTrue);

      final modified = stamp.copyWith(
        enabled: false,
        customAutoEqName: 'Sennheiser HD600 (Oratory1990)',
        customDacName: 'Chord Mojo 2 USB DAC',
      );
      expect(modified.enabled, isFalse);
      expect(modified.hasAnyEnabled, isFalse);
      expect(modified.effectiveAutoEqName, 'Sennheiser HD600 (Oratory1990)');
      expect(modified.effectiveDacName, 'Chord Mojo 2 USB DAC');
    });

    test('LyricShareConfig holds new studio fields and supports copyWith', () {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines.first],
        layoutStyle: LyricCardLayoutStyle.cyberHUD,
        showDualLineRomanized: true,
        personalNote: 'Late night audiophile session',
        showQrCode: true,
        selectedStickers: const [LyricStickerType.hiResLossless, LyricStickerType.bitPerfect],
      );

      expect(config.layoutStyle, LyricCardLayoutStyle.cyberHUD);
      expect(config.showDualLineRomanized, isTrue);
      expect(config.personalNote, 'Late night audiophile session');
      expect(config.showQrCode, isTrue);
      expect(config.selectedStickers.length, 2);
      expect(config.plainTextQuote, '最後のキスは タバコのflavorがした');

      final updated = config.copyWith(
        layoutStyle: LyricCardLayoutStyle.polaroidFrame,
        clearPersonalNote: true,
        selectedStickers: [LyricStickerType.lateNight],
      );
      expect(updated.layoutStyle, LyricCardLayoutStyle.polaroidFrame);
      expect(updated.personalNote, isNull);
      expect(updated.selectedStickers, [LyricStickerType.lateNight]);
    });
  });

  group('Studio Lyric Card Evolution — Controller State Transitions', () {
    test('LyricShareController mutators update state predictably', () {
      final controller = LyricShareController(
        track: sampleTrack,
        allLines: sampleLines,
        initialSelectedLine: sampleLines[0],
      );

      expect(controller.state.config.layoutStyle, LyricCardLayoutStyle.classicMinimal);
      expect(controller.state.config.selectedLines.length, 1);

      // Set layout style
      controller.setLayoutStyle(LyricCardLayoutStyle.cassetteJCard);
      expect(controller.state.config.layoutStyle, LyricCardLayoutStyle.cassetteJCard);

      // Toggle stickers
      controller.toggleSticker(LyricStickerType.hiResLossless);
      expect(controller.state.config.selectedStickers, [LyricStickerType.hiResLossless]);
      controller.toggleSticker(LyricStickerType.bitPerfect);
      expect(controller.state.config.selectedStickers, [LyricStickerType.hiResLossless, LyricStickerType.bitPerfect]);
      controller.toggleSticker(LyricStickerType.hiResLossless); // Remove
      expect(controller.state.config.selectedStickers, [LyricStickerType.bitPerfect]);

      // Max sticker cap (limit 3)
      controller.toggleSticker(LyricStickerType.tubeWarmth);
      controller.toggleSticker(LyricStickerType.lateNight);
      controller.toggleSticker(LyricStickerType.certifiedAudiophile); // 4th should cycle oldest
      expect(controller.state.config.selectedStickers.length, 3);
      expect(controller.state.config.selectedStickers.contains(LyricStickerType.certifiedAudiophile), isTrue);

      // Personal Note
      controller.setPersonalNote('Testing note 123');
      expect(controller.state.config.personalNote, 'Testing note 123');
      controller.setPersonalNote('');
      expect(controller.state.config.personalNote, isNull);

      // Dual Line Romanized
      controller.toggleDualLineRomanized(true);
      expect(controller.state.config.showDualLineRomanized, isTrue);

      // Telemetry stamp update
      controller.updateAudiophileStamp(
        customDacName: 'FiiO BTR7 Direct DAC',
        customAutoEqName: 'Hifiman Sundara (Harman 2018)',
      );
      expect(controller.state.config.audiophileStamp.effectiveDacName, 'FiiO BTR7 Direct DAC');
      expect(controller.state.config.audiophileStamp.effectiveAutoEqName, 'Hifiman Sundara (Harman 2018)');

      // QR Code toggle
      controller.toggleQrCode(true);
      expect(controller.state.config.showQrCode, isTrue);
    });

    test('LyricShareController handles multi-line contiguous selection up to 6 lines', () {
      final controller = LyricShareController(
        track: sampleTrack,
        allLines: sampleLines,
        initialSelectedLine: sampleLines[0],
      );

      // Add line 2
      controller.toggleLineSelection(sampleLines[1]);
      expect(controller.state.config.selectedLines.length, 2);
      expect(controller.state.config.selectedLines, [sampleLines[0], sampleLines[1]]);

      // Add line 3
      controller.toggleLineSelection(sampleLines[2]);
      expect(controller.state.config.selectedLines.length, 3);
      expect(controller.state.config.selectedLines, sampleLines);
    });
  });

  group('Studio Lyric Card Evolution — East Asian Romanizer', () {
    test('EastAsianRomanizer detects and transliterates Japanese, Korean, and Chinese', () {
      expect(EastAsianRomanizer.hasEastAsianCharacters('Hello World'), isFalse);
      expect(EastAsianRomanizer.hasEastAsianCharacters('初恋 (First Love)'), isTrue);
      expect(EastAsianRomanizer.needsRomanization('初恋'), isTrue);

      final romanizedJp = EastAsianRomanizer.romanize('最後のキスは');
      expect(romanizedJp, isNotEmpty);

      final romanizedKr = EastAsianRomanizer.romanize('사랑해');
      expect(romanizedKr, isNotEmpty);
    });
  });

  group('Studio Lyric Card Evolution — Widget Rendering Tests', () {
    testWidgets('Renders ClassicMinimalCardView with typography and telemetry', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0]],
        layoutStyle: LyricCardLayoutStyle.classicMinimal,
        showDualLineRomanized: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: ClassicMinimalCardView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ClassicMinimalCardView), findsOneWidget);
      expect(find.textContaining('First Love'), findsWidgets);
      expect(find.textContaining('Hikaru Utada'), findsWidgets);
      expect(find.textContaining('最後のキスは'), findsOneWidget);
    });

    testWidgets('Renders PolaroidFrameCardView with photo frame and caption', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0]],
        layoutStyle: LyricCardLayoutStyle.polaroidFrame,
        personalNote: 'Special Memory',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: PolaroidFrameCardView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PolaroidFrameCardView), findsOneWidget);
      expect(find.text('— “Special Memory”'), findsOneWidget);
      expect(find.textContaining('FIRST LOVE (初恋)'), findsOneWidget);
    });

    testWidgets('Renders CassetteJCardLyricView with tape spine and Type II stamp', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0], sampleLines[1]],
        layoutStyle: LyricCardLayoutStyle.cassetteJCard,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: CassetteJCardLyricView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CassetteJCardLyricView), findsOneWidget);
      expect(find.textContaining('BAYDEV C-90'), findsOneWidget);
      expect(find.textContaining('SIDE A'), findsOneWidget);
      expect(find.textContaining('TYPE II CHROME'), findsOneWidget);
    });

    testWidgets('Renders WaveformQuoteCardView with audio amplitude and duration pill', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0]],
        layoutStyle: LyricCardLayoutStyle.waveformQuote,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: WaveformQuoteCardView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(WaveformQuoteCardView), findsOneWidget);
      expect(find.textContaining('00:12'), findsOneWidget);
    });

    testWidgets('Renders CyberHudLyricView with Tokyo spec matrix telemetry', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0]],
        layoutStyle: LyricCardLayoutStyle.cyberHUD,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: CyberHudLyricView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CyberHudLyricView), findsOneWidget);
      expect(find.textContaining('┌──[ 0x7F ]'), findsOneWidget);
      expect(find.textContaining('96.0kHz'), findsOneWidget);
    });

    testWidgets('Renders AbstractAuraLyricView with color mesh and quote block', (tester) async {
      final config = LyricShareConfig(
        track: sampleTrack,
        selectedLines: [sampleLines[0]],
        layoutStyle: LyricCardLayoutStyle.abstractAura,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: AbstractAuraLyricView(
                  config: config,
                  colors: sampleColors,
                  scale: 1.0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AbstractAuraLyricView), findsOneWidget);
      expect(find.textContaining('First Love'), findsWidgets);
    });

    testWidgets('LyricCardWidget properly dispatches between styles', (tester) async {
      for (final style in LyricCardLayoutStyle.values) {
        final config = LyricShareConfig(
          track: sampleTrack,
          selectedLines: [sampleLines[0]],
          layoutStyle: style,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: LyricCardWidget(
                    config: config,
                    colors: sampleColors,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LyricCardWidget), findsOneWidget);
      }
    });

    testWidgets('Renders AudiophileTelemetryStamp and LyricStickerBadge', (tester) async {
      final stamp = AudiophileStampConfig(
        enabled: true,
        autoEqProfileName: 'Harman Over-Ear',
        dacDeviceName: 'USB Bit-Perfect Bridge',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AudiophileTelemetryStamp(
                  track: sampleTrack,
                  stampConfig: stamp,
                  colors: sampleColors,
                ),
                const LyricStickerBadge(
                  sticker: LyricStickerType.hiResLossless,
                ),
                const LyricStickerBadge(
                  sticker: LyricStickerType.tubeWarmth,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AudiophileTelemetryStamp), findsOneWidget);
      expect(find.textContaining('FLAC LOSSLESS 24-BIT / 96.0kHz'), findsOneWidget);
      expect(find.textContaining('AUTOEQ: HARMAN OVER-EAR'), findsOneWidget);
      expect(find.textContaining('DAC: USB BIT-PERFECT BRIDGE'), findsOneWidget);
      expect(find.byType(LyricStickerBadge), findsNWidgets(2));
      expect(find.text('HI-RES LOSSLESS'), findsOneWidget);
      expect(find.text('WARM TUBE HARMONICS'), findsOneWidget);
    });
  });
}
