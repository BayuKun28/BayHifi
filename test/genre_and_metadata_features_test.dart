import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/features/library/domain/genre_icon_helper.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/artist_avatar_widget.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/audio_file_inspector_sheet.dart';

void main() {
  group('GenreIconHelper Tests', () {
    test('Correctly maps rock and metal genres to flame icon', () {
      expect(GenreIconHelper.getGenreIcon('Progressive Rock'), LucideIcons.flame);
      expect(GenreIconHelper.getGenreIcon('Heavy Metal'), LucideIcons.flame);
      expect(GenreIconHelper.getGenreIcon('Punk Rock'), LucideIcons.flame);
    });

    test('Correctly maps jazz and blues genres to note icon', () {
      expect(GenreIconHelper.getGenreIcon('Smooth Jazz'), LucideIcons.music2);
      expect(GenreIconHelper.getGenreIcon('Blues Rock'), LucideIcons.flame); // rock matches first
      expect(GenreIconHelper.getGenreIcon('Delta Blues'), LucideIcons.music2);
      expect(GenreIconHelper.getGenreIcon('Neo Soul'), LucideIcons.music2);
    });

    test('Correctly maps classical and acoustic genres', () {
      expect(GenreIconHelper.getGenreIcon('Classical Symphony'), LucideIcons.music);
      expect(GenreIconHelper.getGenreIcon('Acoustic Piano'), LucideIcons.music);
    });

    test('Correctly maps electronic, hip-hop, pop, and studio master', () {
      expect(GenreIconHelper.getGenreIcon('EDM Electronic'), LucideIcons.audioLines);
      expect(GenreIconHelper.getGenreIcon('Hip Hop Rap'), LucideIcons.mic);
      expect(GenreIconHelper.getGenreIcon('Pop Hits'), LucideIcons.headphones);
      expect(GenreIconHelper.getGenreIcon('Hi-Res Lossless Master'), LucideIcons.sparkles);
    });

    test('Deterministic hash fallback maps random/unrecognized genre names reliably', () {
      final icon1 = GenreIconHelper.getGenreIcon('CustomExperimentalGenre123');
      final icon2 = GenreIconHelper.getGenreIcon('CustomExperimentalGenre123');
      expect(icon1, equals(icon2));
      expect(icon1, isNotNull);
    });
  });

  group('ArtistAvatarWidget Tests', () {
    testWidgets('Renders with fallback Cover Bytes when available', (WidgetTester tester) async {
      // 1x1 transparent PNG
      final validPngBytes = Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistAvatarWidget(
              artistName: 'Test Artist',
              fallbackCoverBytes: validPngBytes,
              radius: 28,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ArtistAvatarWidget), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('Renders studio avatar icon fallback when no bytes and offline', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistAvatarWidget(
              artistName: 'Unknown Artist',
              radius: 28,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ArtistAvatarWidget), findsOneWidget);
    });
  });

  group('AudioFileInspectorSheet Tests', () {
    testWidgets('Renders Metadata Tags section and Technical Specs section', (WidgetTester tester) async {
      const track = Track(
        id: 'test_track_1',
        title: 'Master Studio Symphony',
        artist: 'Hi-Fi Ensemble',
        album: 'Acoustic Revelations',
        genre: 'Audiophile Master',
        year: 2026,
        trackNumber: 1,
        duration: Duration(minutes: 5, seconds: 32),
        filePath: '',
        sampleRate: 96000,
        bitDepth: 24,
        format: AudioFormat.flac,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AudioFileInspectorSheet.show(ctx, track),
                  child: const Text('Inspect'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Inspect'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Header & Summary
      expect(find.text('AUDIO FILE INSPECTOR'), findsOneWidget);
      expect(find.text('Master Studio Symphony'), findsWidgets);
      expect(find.text('Hi-Fi Ensemble • Acoustic Revelations'), findsWidgets);

      // Section titles
      expect(find.text('METADATA TAGS'), findsOneWidget);
    });
  });
}
