import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/audio_service/baydev_audio_handler.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/pro_q_studio/data/auto_eq_cloud_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_cloud_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BaydevAudioHandler Tests', () {
    test('syncPlaybackState updates mediaItem and playbackState correctly', () {
      final handler = BaydevAudioHandler.instance;

      const track = Track(
        id: 'audiophile_1',
        title: 'Master Audio Track',
        artist: 'HiFi Studio Ensemble',
        album: 'Acoustic Reference',
        duration: Duration(minutes: 5, seconds: 12),
        bitDepth: 24,
        sampleRate: 96000,
      );

      handler.syncPlaybackState(
        currentTrack: track,
        isPlaying: true,
        position: const Duration(minutes: 1, seconds: 30),
        duration: const Duration(minutes: 5, seconds: 12),
        currentQueue: [track],
        currentQueueIndex: 0,
      );

      expect(handler.mediaItem.value?.title, 'Master Audio Track');
      expect(handler.mediaItem.value?.artist, 'HiFi Studio Ensemble');
      expect(handler.mediaItem.value?.duration, const Duration(minutes: 5, seconds: 12));
      expect(handler.playbackState.value.playing, isTrue);
      expect(handler.playbackState.value.updatePosition, const Duration(minutes: 1, seconds: 30));
    });
  });

  group('AutoEqCloudService Tests', () {
    test('searchItems filters curated targets and measurements', () {
      final service = AutoEqCloudService.instance;

      final allItems = service.getAllItems();
      expect(allItems.isNotEmpty, isTrue);

      final castorResults = service.searchItems(query: 'Castor');
      expect(castorResults.isNotEmpty, isTrue);
      expect(castorResults.first.name, contains('Castor'));

      final targets = service.searchItems(category: AutoEqCloudCategory.target);
      expect(targets.every((t) => t.category == AutoEqCloudCategory.target), isTrue);
    });

    test('downloadItem parses curve into FrCurveData', () async {
      final service = AutoEqCloudService.instance;
      final chu2Item = service.searchItems(query: 'Chu II').first;

      final curve = await service.downloadItem(chu2Item);
      expect(curve.name, chu2Item.name);
      expect(curve.frequencies.isNotEmpty, isTrue);
    });
  });
}
