import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_album_art_view.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/synchronized_lyrics_view.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LyricsService & LrcParser Unit Tests', () {
    test('LrcParser correctly parses timestamped lines', () {
      const sampleLrc = '''
[00:00.00]Intro
[00:10.50]First line of lyrics
[01:20.00]Second line of lyrics
''';
      final lines = LrcParser.parse(sampleLrc);
      expect(lines.length, equals(3));
      expect(lines[0].text, equals('Intro'));
      expect(lines[0].timestamp, equals(Duration.zero));
      expect(lines[1].text, equals('First line of lyrics'));
      expect(lines[1].timestamp, equals(const Duration(seconds: 10, milliseconds: 500)));
      expect(lines[2].text, equals('Second line of lyrics'));
      expect(lines[2].timestamp, equals(const Duration(minutes: 1, seconds: 20)));
    });

    test('LrcParser.findActiveIndex finds accurate line index by position', () {
      const sampleLrc = '''
[00:05.00]Line 1
[00:15.00]Line 2
[00:30.00]Line 3
''';
      final lines = LrcParser.parse(sampleLrc);
      expect(LrcParser.findActiveIndex(lines, const Duration(seconds: 2)), equals(0));
      expect(LrcParser.findActiveIndex(lines, const Duration(seconds: 10)), equals(0));
      expect(LrcParser.findActiveIndex(lines, const Duration(seconds: 20)), equals(1));
      expect(LrcParser.findActiveIndex(lines, const Duration(seconds: 40)), equals(2));
    });

    test('LyricsService extracts embedded lyrics correctly', () async {
      const embeddedLrc = '[00:01.00]Embedded Studio Master Lyrics';
      const track = Track(
        id: 'track_test_1',
        title: 'Master Track',
        artist: 'Studio Artist',
        album: 'Lossless Album',
        duration: Duration(minutes: 3),
        lyrics: embeddedLrc,
      );

      final result = await LyricsService.instance.getLyricsForTrack(track);
      expect(result.isNotEmpty, isTrue);
      expect(result.source, equals(LyricsSource.embedded));
      expect(result.lines.length, equals(1));
      expect(result.lines.first.text, equals('Embedded Studio Master Lyrics'));
    });

    test('LrcParser.parsePlain parses raw plain text lyrics into structured LyricsLine list', () {
      const plainText = '''
First line of plain song
Second line of plain song
Third line of plain song
''';
      final lines = LrcParser.parsePlain(plainText);
      expect(lines.length, equals(3));
      expect(lines[0].text, equals('First line of plain song'));
      expect(lines[1].text, equals('Second line of plain song'));
      expect(lines[2].text, equals('Third line of plain song'));
    });

    test('LyricsService converts embedded plain text lyrics to selectable lines for share feature', () async {
      const embeddedPlain = 'Line 1: Hello Studio\nLine 2: Lossless HiFi\nLine 3: Pure Sound';
      const track = Track(
        id: 'track_plain_embedded',
        title: 'Plain Track',
        artist: 'Acoustic Artist',
        album: 'Acoustic Album',
        duration: Duration(minutes: 4),
        lyrics: embeddedPlain,
      );

      final result = await LyricsService.instance.getLyricsForTrack(track);
      expect(result.isNotEmpty, isTrue);
      expect(result.isSynced, isFalse);
      expect(result.source, equals(LyricsSource.embedded));
      expect(result.lines.length, equals(3));
      expect(result.lines[0].text, equals('Line 1: Hello Studio'));
      expect(result.lines[1].text, equals('Line 2: Lossless HiFi'));
      expect(result.lines[2].text, equals('Line 3: Pure Sound'));
    });
  });

  group('Player Customization Controller & Models', () {
    test('PlayerCustomizationSettings defaults and copyWith', () {
      const settings = PlayerCustomizationSettings();
      expect(settings.albumArtStyle, equals(AlbumArtStyle.cdJewel));
      expect(settings.spectrumStyle, equals(SpectrumStyle.m3Expressive));
      expect(settings.timeBarStyle, equals(TimeBarStyle.wavy));
      expect(settings.ambientGlow, isTrue);

      final updated = settings.copyWith(
        albumArtStyle: AlbumArtStyle.vinyl,
        spectrumStyle: SpectrumStyle.wave,
        timeBarStyle: TimeBarStyle.capsule,
        ambientGlow: false,
      );
      expect(updated.albumArtStyle, equals(AlbumArtStyle.vinyl));
      expect(updated.spectrumStyle, equals(SpectrumStyle.wave));
      expect(updated.timeBarStyle, equals(TimeBarStyle.capsule));
      expect(updated.ambientGlow, isFalse);
    });

    test('Enum parsing from strings with safe fallback', () {
      expect(AlbumArtStyle.fromString('vinyl'), equals(AlbumArtStyle.vinyl));
      expect(AlbumArtStyle.fromString('invalid'), equals(AlbumArtStyle.cdJewel));

      expect(SpectrumStyle.fromString('dots'), equals(SpectrumStyle.dots));
      expect(SpectrumStyle.fromString('invalid'), equals(SpectrumStyle.m3Expressive));

      expect(TimeBarStyle.fromString('segmented'), equals(TimeBarStyle.segmented));
      expect(TimeBarStyle.fromString('invalid'), equals(TimeBarStyle.wavy));
    });
  });

  group('Player Display Widgets Tests', () {
    testWidgets('CustomAlbumArtView renders all 4 styles without errors', (WidgetTester tester) async {
      const track = Track(
        id: 'art_track_1',
        title: 'Art Title',
        artist: 'Art Artist',
        album: 'Art Album',
        duration: Duration(minutes: 4),
      );

      for (final style in AlbumArtStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomAlbumArtView(
                track: track,
                isPlaying: true,
                style: style,
                ambientGlow: true,
                primaryColor: const Color(0xFF00E5FF),
                size: 200,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CustomAlbumArtView), findsOneWidget);
      }
    });

    testWidgets('CustomTimeBar renders all 4 styles and handles seek', (WidgetTester tester) async {
      for (final style in TimeBarStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomTimeBar(
                position: const Duration(seconds: 45),
                duration: const Duration(minutes: 3),
                style: style,
                primaryColor: const Color(0xFF00E5FF),
                onSeek: (val) {},
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(CustomTimeBar), findsOneWidget);
        expect(find.text('00:45'), findsOneWidget);
        expect(find.text('03:00'), findsOneWidget);
      }
    });

    testWidgets('SynchronizedLyricsView renders synced and plain lyrics cleanly', (WidgetTester tester) async {
      const syncedResult = LyricsResult(
        rawLyrics: '[00:02.00]Hello HiFi\n[00:06.00]World Audio',
        lines: [
          LyricsLine(timestamp: Duration(seconds: 2), text: 'Hello HiFi'),
          LyricsLine(timestamp: Duration(seconds: 6), text: 'World Audio'),
        ],
        isSynced: true,
        source: LyricsSource.embedded,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SynchronizedLyricsView(
                lyricsResult: syncedResult,
                currentPosition: Duration(seconds: 3),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hello HiFi'), findsOneWidget);
      expect(find.text('World Audio'), findsOneWidget);
      expect(find.text('EMBEDDED LRC'), findsOneWidget);
    });
  });
}
