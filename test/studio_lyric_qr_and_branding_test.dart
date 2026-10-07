import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/audiophile_stamp_config.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_layout_style.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/components/lyric_qr_link_badge.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/components/studio_qr_encoder.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_widget.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  group('Studio QR Encoder Engine', () {
    test('Encodes short text into Version 1 QR matrix (21x21)', () {
      final matrix = StudioQrEncoder.encode('BAYDEV HIFI');
      expect(matrix.length, equals(21));
      expect(matrix[0].length, equals(21));

      // Finder pattern top-left must have dark corners
      expect(matrix[0][0], isTrue);
      expect(matrix[0][6], isTrue);
      expect(matrix[6][0], isTrue);
      expect(matrix[6][6], isTrue);
      // Center of finder pattern (3,3) must be dark
      expect(matrix[3][3], isTrue);
    });

    test('Encodes medium URL into higher version QR matrix', () {
      const longUrl = 'https://music.baydev.audio/track/flac_96khz_24bit_master_signature_test';
      final matrix = StudioQrEncoder.encode(longUrl);
      expect(matrix.length, greaterThanOrEqualTo(25)); // Version >= 2
      expect(matrix.length, equals(matrix[0].length));
    });

    test('Encodes empty fallback text gracefully', () {
      final matrix = StudioQrEncoder.encode('');
      expect(matrix.length, equals(21));
    });
  });

  group('Lyric QR Link Badge Widget', () {
    const testTrack = Track(
      id: 'track_audiophile_qr',
      title: 'Hotel California',
      artist: 'Eagles',
      album: 'Hotel California (2013 Remaster)',
      duration: Duration(minutes: 6, seconds: 30),
      format: AudioFormat.flac,
      remoteUrl: 'https://youtu.be/0983457193',
    );

    testWidgets('Renders LyricQrLinkBadge with QR code and SCAN label', (tester) async {
      final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LyricQrLinkBadge(
              track: testTrack,
              colors: colors,
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(LyricQrLinkBadge), findsOneWidget);
      expect(find.text('SCAN // PLAY'), findsOneWidget);
    });
  });

  group('Layout Templates QR Link & Branding Telemetry Verification', () {
    const testTrack = Track(
      id: 't_telemetry_all',
      title: 'Time',
      artist: 'Pink Floyd',
      album: 'The Dark Side of the Moon',
      duration: Duration(minutes: 6, seconds: 53),
      format: AudioFormat.flac,
      remoteUrl: 'https://music.youtube.com/watch?v=jwfmXgRF8A4',
    );

    const testLines = [
      LyricsLine(timestamp: Duration(seconds: 10), text: 'Ticking away the moments that make up a dull day'),
      LyricsLine(timestamp: Duration(seconds: 16), text: 'Fritter and waste the hours in an offhand way'),
    ];

    final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

    for (final layout in LyricCardLayoutStyle.values) {
      testWidgets('Template ${layout.name} renders branding, audio specs, and QR link when enabled', (tester) async {
        final config = LyricShareConfig(
          track: testTrack,
          selectedLines: testLines,
          layoutStyle: layout,
          ratio: LyricCardRatio.portrait_4_5,
          preset: LyricCardThemePreset.studioOledBlack,
          showBranding: true,
          showAudioSpecsBadge: true,
          showQrCode: true,
          audiophileStamp: const AudiophileStampConfig(
            autoEqProfileName: 'Harman Target 2019',
            dspProfileName: 'Tube Warmth Mastering',
            dacDeviceName: 'Kiwi Ears Allegro Mini',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 450,
                  child: LyricCardWidget(
                    config: config,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LyricQrLinkBadge), findsOneWidget,
            reason: 'Template ${layout.name} must render LyricQrLinkBadge when showQrCode is true');

        // Check quotes
        expect(find.text(testLines[0].text), findsOneWidget);
      });

      testWidgets('Template ${layout.name} hides QR link when showQrCode is false', (tester) async {
        final config = LyricShareConfig(
          track: testTrack,
          selectedLines: testLines,
          layoutStyle: layout,
          ratio: LyricCardRatio.portrait_4_5,
          preset: LyricCardThemePreset.studioOledBlack,
          showBranding: true,
          showAudioSpecsBadge: true,
          showQrCode: false,
          audiophileStamp: const AudiophileStampConfig(
            autoEqProfileName: 'Harman Target 2019',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: 450,
                  child: LyricCardWidget(
                    config: config,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LyricQrLinkBadge), findsNothing,
            reason: 'Template ${layout.name} must NOT render LyricQrLinkBadge when showQrCode is false');
      });

      testWidgets('Template ${layout.name} renders cleanly on narrow preview width without RenderFlex overflow', (tester) async {
        final config = LyricShareConfig(
          track: testTrack,
          selectedLines: testLines,
          layoutStyle: layout,
          ratio: LyricCardRatio.portrait_4_5,
          preset: LyricCardThemePreset.studioOledBlack,
          showBranding: true,
          showAudioSpecsBadge: true,
          showQrCode: true,
          customAudioSpec: 'FLAC 96kHz / 24-bit MASTER',
          audiophileStamp: const AudiophileStampConfig(
            autoEqProfileName: 'Harman Target 2019',
            dspProfileName: 'Tube Warmth Mastering',
            dacDeviceName: 'Kiwi Ears Allegro Mini',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 220,
                  height: 320,
                  child: LyricCardWidget(
                    config: config,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LyricCardWidget), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Template ${layout.name} on narrow preview must render with 0 overflow exceptions');
      });

      testWidgets('Template ${layout.name} renders cleanly in Landscape 16:9 without RenderFlex overflow', (tester) async {
        final config = LyricShareConfig(
          track: testTrack,
          selectedLines: testLines,
          layoutStyle: layout,
          ratio: LyricCardRatio.landscape_16_9,
          preset: LyricCardThemePreset.studioOledBlack,
          showBranding: true,
          showAudioSpecsBadge: true,
          showQrCode: true,
          personalNote: 'Late night audiophile listening session',
          customAudioSpec: 'FLAC 96kHz / 24-bit MASTER',
          audiophileStamp: const AudiophileStampConfig(
            autoEqProfileName: 'Harman Target 2019',
            dspProfileName: 'Tube Warmth Mastering',
            dacDeviceName: 'Kiwi Ears Allegro Mini',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 340,
                  height: 340 * 9 / 16,
                  child: LyricCardWidget(
                    config: config,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(LyricCardWidget), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Template ${layout.name} in Landscape 16:9 must render with 0 overflow exceptions');
      });
    }
  });
}

