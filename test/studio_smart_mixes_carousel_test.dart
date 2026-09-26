import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_hero_showcase_carousel.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('StudioHeroShowcaseCarousel renders dynamic smart mixes and action buttons', (tester) async {
    final List<Track> mockTracks = List.generate(
      10,
      (i) => Track(
        id: 'track_$i',
        title: 'Audiophile Track $i',
        artist: 'HiFi Artist $i',
        album: 'Acoustic Master Album $i',
        duration: const Duration(minutes: 3, seconds: 30),
        filePath: '/music/track_$i.flac',
        format: AudioFormat.flac,
        bitDepth: 24,
        sampleRate: 96000,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            final notifier = UnifiedLibraryController();
            notifier.state = notifier.state.copyWith(tracks: mockTracks);
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudioHeroShowcaseCarousel(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('DYNAMIC STUDIO MIXES'), findsOneWidget);
    expect(find.text('Recommended Studio Mix'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);

    // Tap on the mix card to open tracklist modal bottom sheet
    await tester.tap(find.text('Recommended Studio Mix'));
    await tester.pumpAndSettle();

    expect(find.text('Play All'), findsOneWidget);
    expect(find.text('Shuffle Play'), findsOneWidget);
    expect(find.textContaining('Audiophile Track'), findsWidgets);
  });
}
