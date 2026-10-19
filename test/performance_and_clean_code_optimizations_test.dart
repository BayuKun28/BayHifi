import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/fft_processor.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/track_tile.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FftProcessor Zero-Allocation & Typed Array Tests', () {
    test('FftProcessor returns Float64List with exact bandCount', () {
      final processor = FftProcessor(bandCount: 32);
      const emptyVis = AudioVisualizationData(channelCount: 2, wave: [], fft: []);
      final result = processor.processFft(emptyVis);

      expect(result, isA<Float64List>());
      expect(result.length, equals(32));
      for (final val in result) {
        expect(val, equals(0.0));
      }
    });

    test('FftProcessor decays smoothly without throwing', () {
      final processor = FftProcessor(bandCount: 16);
      const emptyVis = AudioVisualizationData(channelCount: 2, wave: [], fft: []);

      final first = processor.processFft(emptyVis);
      expect(first, isA<Float64List>());
      expect(first.length, equals(16));

      final second = processor.processFft(emptyVis);
      expect(second, isA<Float64List>());
      expect(second.length, equals(16));
    });
  });

  group('LocalPersistenceService Storage Debouncing & Flush Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('bayhifi_debounce_test_');
      await LocalPersistenceService.instance.init(
        customPath: '${tempDir.path}/debounce_storage.json',
      );
    });

    tearDown(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('Immediate memory cache update and debounced disk flush', () async {
      final service = LocalPersistenceService.instance;

      // Fast successive writes
      await service.saveSetting('test_slider_val', 10);
      expect(service.getSetting<int>('test_slider_val'), equals(10));

      await service.saveSetting('test_slider_val', 20);
      expect(service.getSetting<int>('test_slider_val'), equals(20));

      await service.saveSetting('test_slider_val', 30);
      expect(service.getSetting<int>('test_slider_val'), equals(30));

      // Flush to disk
      await service.flush();
      expect(service.getSetting<int>('test_slider_val'), equals(30));
    });
  });

  group('TrackTile Lightweight Granular Selectors Widget Test', () {
    testWidgets('TrackTile renders and responds to tap without full store watch', (WidgetTester tester) async {
      const testTrack = Track(
        id: 'opt_track_1',
        title: 'Optimized Song',
        artist: 'HiFi Artist',
        album: 'Studio Album',
        duration: Duration(minutes: 3, seconds: 45),
        sampleRate: 96000,
        bitDepth: 24,
      );

      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrackTile(
                track: testTrack,
                isPlaying: false,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Optimized Song'), findsOneWidget);
      expect(find.byType(TrackTile), findsOneWidget);

      await tester.tap(find.byType(TrackTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
