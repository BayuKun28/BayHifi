import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/lyrics/east_asian_romanizer.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/synchronized_lyrics_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('East Asian Romanizer Engine - Script Detection', () {
    test('Correctly detects Japanese scripts (Hiragana & Katakana)', () {
      expect(EastAsianRomanizer.detectScript('こんにちは世界'), equals(EastAsianScript.japanese));
      expect(EastAsianRomanizer.detectScript('ヨルシカ - だから僕は音楽を辞めた'), equals(EastAsianScript.japanese));
      expect(EastAsianRomanizer.detectScript('夜に駆ける (Yoasobi)'), equals(EastAsianScript.japanese));
      expect(EastAsianRomanizer.isJapanese('さようなら'), isTrue);
    });

    test('Correctly detects Korean script (Hangul)', () {
      expect(EastAsianRomanizer.detectScript('안녕하세요'), equals(EastAsianScript.korean));
      expect(EastAsianRomanizer.detectScript('뉴진스 (NewJeans) - Hype Boy'), equals(EastAsianScript.korean));
      expect(EastAsianRomanizer.detectScript('사랑해요'), equals(EastAsianScript.korean));
      expect(EastAsianRomanizer.isKorean('감사합니다'), isTrue);
    });

    test('Correctly detects Chinese script (Hanzi)', () {
      expect(EastAsianRomanizer.detectScript('你好世界'), equals(EastAsianScript.chinese));
      expect(EastAsianRomanizer.detectScript('周杰伦 - 青花瓷'), equals(EastAsianScript.chinese));
      expect(EastAsianRomanizer.detectScript('我爱你'), equals(EastAsianScript.chinese));
      expect(EastAsianRomanizer.isChinese('美丽的世界'), isTrue);
    });

    test('Correctly detects Latin / ASCII and Empty text', () {
      expect(EastAsianRomanizer.detectScript('Bohemian Rhapsody - Queen'), equals(EastAsianScript.latin));
      expect(EastAsianRomanizer.detectScript(''), equals(EastAsianScript.none));
      expect(EastAsianRomanizer.detectScript('   '), equals(EastAsianScript.none));
    });
  });

  group('East Asian Romanizer Engine - Japanese Hepburn Romanization', () {
    test('Transliterates Hiragana with digraphs and sokuon', () {
      expect(EastAsianRomanizer.romanizeJapanese('ありがとう'), equals('arigatou'));
      expect(EastAsianRomanizer.romanizeJapanese('さようなら'), equals('sayounara'));
      expect(EastAsianRomanizer.romanizeJapanese('きょう'), equals('kyou'));
      expect(EastAsianRomanizer.romanizeJapanese('しゃしん'), equals('shashin'));
      expect(EastAsianRomanizer.romanizeJapanese('ちょっと'), equals('chotto'));
      expect(EastAsianRomanizer.romanizeJapanese('がっこう'), equals('gakkou'));
      expect(EastAsianRomanizer.romanizeJapanese('きっぷ'), equals('kippu'));
    });

    test('Transliterates Katakana and Chōonpu (vowel extension)', () {
      expect(EastAsianRomanizer.romanizeJapanese('ラーメン'), equals('raamen'));
      expect(EastAsianRomanizer.romanizeJapanese('ピアノ'), equals('piano'));
      expect(EastAsianRomanizer.romanizeJapanese('コンピューター'), equals('konpyuutaa'));
    });

    test('Transliterates Common Kanji dictionary entries', () {
      expect(EastAsianRomanizer.romanizeJapanese('夜'), equals('yoru'));
      expect(EastAsianRomanizer.romanizeJapanese('青'), equals('ao'));
      expect(EastAsianRomanizer.romanizeJapanese('花'), equals('hana'));
      expect(EastAsianRomanizer.romanizeJapanese('心'), equals('kokoro'));
      expect(EastAsianRomanizer.romanizeJapanese('愛'), equals('ai'));
    });
  });

  group('East Asian Romanizer Engine - Korean Revised Romanization', () {
    test('Algorithmic Hangul syllabic decomposition (Choseong, Jungseong, Jongseong)', () {
      expect(EastAsianRomanizer.romanizeKorean('가나다'), equals('ganada'));
      expect(EastAsianRomanizer.romanizeKorean('사랑'), equals('sarang'));
      expect(EastAsianRomanizer.romanizeKorean('음악'), equals('eumak'));
      expect(EastAsianRomanizer.romanizeKorean('감사합니다'), equals('gamsahamnida'));
    });

    test('Handles Batchim sound assimilations and complex syllables', () {
      expect(EastAsianRomanizer.romanizeKorean('있어'), equals('isseo'));
      expect(EastAsianRomanizer.romanizeKorean('한국'), equals('hanguk'));
      expect(EastAsianRomanizer.romanizeKorean('서울'), equals('seoul'));
    });
  });

  group('East Asian Romanizer Engine - Mandarin Pinyin', () {
    test('Transliterates common Mandarin Hanzi to Pinyin without tones', () {
      expect(EastAsianRomanizer.romanizeChinese('你好'), equals('ni hao'));
      expect(EastAsianRomanizer.romanizeChinese('谢谢'), equals('xie xie'));
      expect(EastAsianRomanizer.romanizeChinese('我爱你'), equals('wo ai ni'));
      expect(EastAsianRomanizer.romanizeChinese('世界'), equals('shi jie'));
    });

    test('Transliterates common Mandarin Hanzi to Pinyin with toned accents', () {
      expect(EastAsianRomanizer.romanizeChinese('你好', includeTones: true), equals('nǐ hǎo'));
      expect(EastAsianRomanizer.romanizeChinese('我爱你', includeTones: true), equals('wǒ ài nǐ'));
    });
  });

  group('East Asian Romanizer - General Transliterate Auto-Router', () {
    test('Automatically detects script and transliterates accurately', () {
      expect(EastAsianRomanizer.romanize('さくら'), equals('sakura'));
      expect(EastAsianRomanizer.romanize('사랑해'), equals('saranghae'));
      expect(EastAsianRomanizer.romanize('你好'), equals('ni hao'));
      expect(EastAsianRomanizer.romanize('Stay With Me'), equals('Stay With Me'));
    });
  });

  group('LyricsLine & LrcParser East Asian Romanization & Timing Offset', () {
    test('LrcParser automatically romanizes East Asian lyrics lines', () {
      const lrcContent = '''
[00:02.00]さよならの夏
[00:08.50]감사합니다
[00:15.00]你好朋友
[00:22.00]English Classic HiFi
''';
      final lines = LrcParser.parse(lrcContent);
      expect(lines.length, equals(4));

      // Line 1: Japanese
      expect(lines[0].text, equals('さよならの夏'));
      expect(lines[0].hasRomanization, isTrue);
      expect(lines[0].romanizedText, isNotNull);
      expect(lines[0].effectiveRomanized, isNotEmpty);

      // Line 2: Korean
      expect(lines[1].text, equals('감사합니다'));
      expect(lines[1].hasRomanization, isTrue);
      expect(lines[1].romanizedText, equals('gamsahamnida'));

      // Line 3: Chinese
      expect(lines[2].text, equals('你好朋友'));
      expect(lines[2].hasRomanization, isTrue);
      expect(lines[2].romanizedText, contains('ni hao'));

      // Line 4: English
      expect(lines[3].text, equals('English Classic HiFi'));
      expect(lines[3].hasRomanization, isFalse);
      expect(lines[3].effectiveRomanized, equals('English Classic HiFi'));
    });

    test('LrcParser.findActiveIndex supports real-time timing offset calibration', () {
      const lrcContent = '''
[00:10.00]First Line
[00:20.00]Second Line
[00:30.00]Third Line
''';
      final lines = LrcParser.parse(lrcContent);

      // Without offset at 9.5s -> line 0 is active (first line starts at 10s)
      expect(LrcParser.findActiveIndex(lines, const Duration(milliseconds: 9500)), equals(0));

      // At 19.5s with zero offset -> line 0 is still active
      expect(LrcParser.findActiveIndex(lines, const Duration(milliseconds: 19500)), equals(0));

      // At 19.5s with +600ms offset -> effective pos is 20.1s -> line 1 becomes active!
      expect(
        LrcParser.findActiveIndex(
          lines,
          const Duration(milliseconds: 19500),
          offset: const Duration(milliseconds: 600),
        ),
        equals(1),
      );

      // At 20.5s with -600ms offset -> effective pos is 19.9s -> line 0 is active!
      expect(
        LrcParser.findActiveIndex(
          lines,
          const Duration(milliseconds: 20500),
          offset: const Duration(milliseconds: -600),
        ),
        equals(0),
      );
    });
  });

  group('SynchronizedLyricsView Widget & Display Modes Tests', () {
    setUp(() async {
      await LocalPersistenceService.instance.init();
    });

    testWidgets('Renders in DUAL-LINE mode and displays both original and romanized lines', (WidgetTester tester) async {
      const lrcResult = LyricsResult(
        rawLyrics: '[00:02.00]さよなら\n[00:08.00]감사합니다',
        lines: [
          LyricsLine(timestamp: Duration(seconds: 2), text: 'さよなら', romanizedText: 'sayonara'),
          LyricsLine(timestamp: Duration(seconds: 8), text: '감사합니다', romanizedText: 'gamsahamnida'),
        ],
        isSynced: true,
        source: LyricsSource.embedded,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SynchronizedLyricsView(
                lyricsResult: lrcResult,
                currentPosition: Duration(seconds: 3),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Original text
      expect(find.text('さよなら'), findsOneWidget);
      expect(find.text('감사합니다'), findsOneWidget);

      // Romanized subtitles in DUAL mode
      expect(find.text('sayonara'), findsOneWidget);
      expect(find.text('gamsahamnida'), findsOneWidget);

      // Top control pills
      expect(find.text('ORIG'), findsOneWidget);
      expect(find.text('ROM'), findsOneWidget);
      expect(find.text('DUAL'), findsOneWidget);
      expect(find.text('SYNC'), findsOneWidget);
    });

    testWidgets('Switching display mode to ROM renders romanized text primarily', (WidgetTester tester) async {
      const lrcResult = LyricsResult(
        rawLyrics: '[00:02.00]さよなら',
        lines: [
          LyricsLine(timestamp: Duration(seconds: 2), text: 'さよなら', romanizedText: 'sayonara'),
        ],
        isSynced: true,
        source: LyricsSource.embedded,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SynchronizedLyricsView(
                lyricsResult: lrcResult,
                currentPosition: Duration(seconds: 3),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap 'ROM' mode button
      await tester.tap(find.text('ROM'));
      await tester.pumpAndSettle();

      // Primary text should now be 'sayonara'
      expect(find.text('sayonara'), findsOneWidget);
    });

    testWidgets('Tapping SYNC button opens LRC Timing Synchronizer sheet with steppers', (WidgetTester tester) async {
      const lrcResult = LyricsResult(
        rawLyrics: '[00:02.00]さよなら',
        lines: [
          LyricsLine(timestamp: Duration(seconds: 2), text: 'さよなら', romanizedText: 'sayonara'),
        ],
        isSynced: true,
        source: LyricsSource.embedded,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SynchronizedLyricsView(
                lyricsResult: lrcResult,
                currentPosition: Duration(seconds: 3),
                trackId: 'test_track_offset_1',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap 'SYNC' button
      await tester.tap(find.text('SYNC'));
      await tester.pumpAndSettle();

      // Verify modal sheet is displayed
      expect(find.text('LRC TIMING SYNCHRONIZER'), findsOneWidget);
      expect(find.text('Active Offset Delay'), findsOneWidget);
      expect(find.text('0 ms'), findsOneWidget);
      expect(find.text('+100ms'), findsOneWidget);
      expect(find.text('-100ms'), findsOneWidget);
      expect(find.text('+500ms'), findsOneWidget);
      expect(find.text('-500ms'), findsOneWidget);

      // Tap '+100ms' stepper
      await tester.tap(find.text('+100ms'));
      await tester.pumpAndSettle();

      expect(find.text('+100 ms'), findsOneWidget);
      expect(find.text('RESET'), findsOneWidget);

      // Tap 'RESET'
      await tester.tap(find.text('RESET'));
      await tester.pumpAndSettle();

      expect(find.text('0 ms'), findsOneWidget);
    });
  });
}
