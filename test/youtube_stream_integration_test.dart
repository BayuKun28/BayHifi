import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/youtube_music/data/youtube_music_service.dart';

void main() {
  group('YouTube Music Live Streaming Integration Tests', () {
    test('YouTubeMusicService getOggOpusAudioByteStream resolves and streams audio beyond 1MB without 403 stall', () async {
      // Test with track 'juJkNKodgdE' (INSANE)
      final oggStream = await YouTubeMusicService.instance.getOggOpusAudioByteStream('yt_juJkNKodgdE');
      expect(oggStream, isNotNull);

      int totalBytes = 0;
      int chunkCount = 0;

      await for (final chunk in oggStream!) {
        totalBytes += chunk.length;
        chunkCount++;
        // Verify we easily stream past the previous 1MB limit (1,048,576 bytes)
        if (totalBytes > 1200000) {
          break;
        }
      }

      expect(chunkCount, greaterThan(15));
      expect(totalBytes, greaterThan(1048576));
    }, timeout: const Timeout(Duration(seconds: 40)));

    test('YouTubeMusicService getAudioStreamUrl returns verified stream URL', () async {
      final url = await YouTubeMusicService.instance.getAudioStreamUrl('yt_juJkNKodgdE');
      expect(url, isNotNull);
      expect(url!.startsWith('http'), isTrue);
    });
  });
}
