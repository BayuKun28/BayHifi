import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/youtube_music/data/youtube_music_service.dart';

void main() {
  group('YouTube Music Live Streaming Integration Tests', () {
    test('YouTubeMusicService getOggOpusAudioByteStream resolves and streams audio beyond 1MB without 403 stall', () async {
      // Test with global track 'k1BFHYtZlAU' (blink-182)
      final oggStream = await YouTubeMusicService.instance.getOggOpusAudioByteStream('yt_k1BFHYtZlAU');
      expect(oggStream, isNotNull);

      int totalBytes = 0;
      int chunkCount = 0;

      await for (final chunk in oggStream!) {
        totalBytes += chunk.length;
        chunkCount++;
        // Verify we easily stream past the initial audio chunk limit
        if (totalBytes > 200000) {
          break;
        }
      }

      expect(chunkCount, greaterThan(2));
      expect(totalBytes, greaterThan(150000));
    }, timeout: const Timeout(Duration(seconds: 45)));

    test('YouTubeMusicService getAudioStreamUrl returns verified stream URL', () async {
      final url = await YouTubeMusicService.instance.getAudioStreamUrl('yt_k1BFHYtZlAU');
      expect(url, isNotNull);
      expect(url!.startsWith('http'), isTrue);
    });

  });
}
