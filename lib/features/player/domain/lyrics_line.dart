import 'package:flutter/foundation.dart';
import '../../../core/lyrics/east_asian_romanizer.dart';

/// Model baris lirik bersinkronisasi waktu dengan dukungan romanisasi Latin
@immutable
class LyricsLine {
  final Duration timestamp;
  final String text;
  final String? romanizedText;

  const LyricsLine({
    required this.timestamp,
    required this.text,
    this.romanizedText,
  });

  /// Transliterated Latin text or fallback to original text
  String get effectiveRomanized => romanizedText ?? text;

  /// Returns true if this line contains distinct East Asian characters
  bool get hasRomanization => romanizedText != null && romanizedText != text;

  LyricsLine copyWith({
    Duration? timestamp,
    String? text,
    String? romanizedText,
  }) {
    return LyricsLine(
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      romanizedText: romanizedText ?? this.romanizedText,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text &&
          romanizedText == other.romanizedText;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode ^ (romanizedText?.hashCode ?? 0);
}

/// Universal Parser Format LRC ([mm:ss.xx] Text)
class LrcParser {
  const LrcParser._();

  static final RegExp _lrcRegex = RegExp(
    r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)',
  );

  /// Parse isi teks file .lrc menjadi daftar baris lirik berurutan
  static List<LyricsLine> parse(String content, {bool autoRomanize = true}) {
    final lines = <LyricsLine>[];
    final rawLines = content.split('\n');

    for (final raw in rawLines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final match = _lrcRegex.firstMatch(trimmed);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final millisStr = match.group(3) ?? '0';
        int millis = int.tryParse(millisStr) ?? 0;

        // Tangani 2 digit (centiseconds) atau 3 digit (milliseconds)
        if (millisStr.length == 2) {
          millis *= 10;
        }

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );

        final text = (match.group(4) ?? '').trim();
        if (text.isNotEmpty) {
          String? romanized;
          if (autoRomanize && EastAsianRomanizer.hasEastAsianCharacters(text)) {
            romanized = EastAsianRomanizer.romanize(text);
          }
          lines.add(LyricsLine(
            timestamp: duration,
            text: text,
            romanizedText: romanized,
          ));
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Parse isi teks lirik biasa (plain text / embedded non-LRC) menjadi baris lirik berurutan
  static List<LyricsLine> parsePlain(String content, {bool autoRomanize = true}) {
    final lines = <LyricsLine>[];
    final rawLines = content.split('\n');

    for (int i = 0; i < rawLines.length; i++) {
      final trimmed = rawLines[i].trim();
      if (trimmed.isEmpty) continue;

      String? romanized;
      if (autoRomanize && EastAsianRomanizer.hasEastAsianCharacters(trimmed)) {
        romanized = EastAsianRomanizer.romanize(trimmed);
      }
      lines.add(LyricsLine(
        timestamp: Duration(seconds: i * 4),
        text: trimmed,
        romanizedText: romanized,
      ));
    }
    return lines;
  }

  /// Mencari indeks baris lirik yang sedang aktif sesuai posisi lagu dan timing offset
  static int findActiveIndex(
    List<LyricsLine> lines,
    Duration currentPosition, {
    Duration offset = Duration.zero,
  }) {
    if (lines.isEmpty) return -1;
    final effectivePosition = currentPosition + offset;
    final safePosition = effectivePosition < Duration.zero ? Duration.zero : effectivePosition;

    if (safePosition < lines.first.timestamp) return 0;

    for (int i = 0; i < lines.length; i++) {
      final isLast = i == lines.length - 1;
      if (isLast) return i;

      final nextTimestamp = lines[i + 1].timestamp;
      if (safePosition >= lines[i].timestamp && safePosition < nextTimestamp) {
        return i;
      }
    }

    return lines.length - 1;
  }

  /// Sample Demo LRC untuk uji coba Now Playing Screen
  static const String defaultSampleLrc = '''
[00:00.00]Audio Studio Mastering Session
[00:04.50]Baydev HiFi Audiophile Master System
[00:09.00]Direct C++ SoLoud Engine Initialized
[00:14.20]Sample Rate 96 kHz • 24-bit Lossless Stream
[00:20.10]High-Resolution Soundstage Immersion
[00:26.50]Parametric Pro-Q Biquad IIR Filter Active
[00:32.80]Analog Triode Tube Saturation Warmth
[00:39.00]Sub-Bass Resonance with Dynamic Headroom
[00:46.40]Crystal Clear Vocal Separation & Mid-Side Width
[00:54.00]Synchronized Acoustic Fidelity
[01:02.30]Zero-Overshoot Brickwall Limiter Protection
[01:10.00]Pure Audiophile Sound Delivered to Your Ears
[01:20.00]Studio Master Outro
''';
}
