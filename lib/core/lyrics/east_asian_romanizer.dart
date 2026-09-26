/// East Asian Lyrics & Metadata Romanizer Engine (Japanese Hepburn, Korean Revised, Mandarin Pinyin)
/// Pure Dart high-performance transliteration for real-time lyrics & UI display.
library;

enum EastAsianScript {
  japanese,
  korean,
  chinese,
  latin,
  mixed,
  none,
}

enum LyricsDisplayMode {
  original,
  romanized,
  dualLine,
}

class EastAsianRomanizer {
  const EastAsianRomanizer._();

  /// Detect the dominant East Asian script in the text
  static EastAsianScript detectScript(String text) {
    if (text.trim().isEmpty) return EastAsianScript.none;

    int japaneseCount = 0;
    int koreanCount = 0;
    int chineseCount = 0;
    int latinCount = 0;

    for (final char in text.runes) {
      if (_isHiragana(char) || _isKatakana(char)) {
        japaneseCount += 3; // Strong indicator of Japanese
      } else if (_isHangul(char)) {
        koreanCount += 3; // Strong indicator of Korean
      } else if (_isCjkIdeograph(char)) {
        chineseCount += 1; // Can be Kanji or Hanzi
      } else if ((char >= 0x41 && char <= 0x5A) || (char >= 0x61 && char <= 0x7A)) {
        latinCount += 1;
      }
    }

    if (japaneseCount > 0) return EastAsianScript.japanese;
    if (koreanCount > 0) return EastAsianScript.korean;
    if (chineseCount > 0) return EastAsianScript.chinese;
    if (latinCount > 0) return EastAsianScript.latin;

    return EastAsianScript.none;
  }

  /// Helper predicates for specific scripts
  static bool isJapanese(String text) => detectScript(text) == EastAsianScript.japanese;
  static bool isKorean(String text) => detectScript(text) == EastAsianScript.korean;
  static bool isChinese(String text) => detectScript(text) == EastAsianScript.chinese;

  /// Transliterate Mandarin Hanzi (alias for romanizeMandarin)
  static String romanizeChinese(String text, {bool includeTones = false}) =>
      romanizeMandarin(text, includeTones: includeTones);

  /// Check if the text contains any East Asian characters that can be romanized
  static bool hasEastAsianCharacters(String text) {
    for (final char in text.runes) {
      if (_isHiragana(char) || _isKatakana(char) || _isHangul(char) || _isCjkIdeograph(char)) {
        return true;
      }
    }
    return false;
  }

  /// Transliterate text automatically detecting script per segment
  static String romanize(String text, {bool includePinyinTones = false, EastAsianScript? forceScript}) {
    if (text.isEmpty) return text;

    final script = forceScript ?? detectScript(text);

    switch (script) {
      case EastAsianScript.japanese:
        return romanizeJapanese(text);
      case EastAsianScript.korean:
        return romanizeKorean(text);
      case EastAsianScript.chinese:
        return romanizeMandarin(text, includeTones: includePinyinTones);
      case EastAsianScript.mixed:
      case EastAsianScript.latin:
      case EastAsianScript.none:
        // Handle mixed segments (Hangul, Kana, Hanzi within same text)
        return _romanizeMixed(text, includePinyinTones: includePinyinTones);
    }
  }

  /// Mixed script romanizer for multilingual text
  static String _romanizeMixed(String text, {bool includePinyinTones = false}) {
    final buffer = StringBuffer();
    int i = 0;
    final runes = text.runes.toList();

    while (i < runes.length) {
      final code = runes[i];

      if (_isHiragana(code) || _isKatakana(code)) {
        // Extract Japanese run
        final run = StringBuffer();
        while (i < runes.length && (_isHiragana(runes[i]) || _isKatakana(runes[i]) || runes[i] == 0x30FC)) {
          run.writeCharCode(runes[i]);
          i++;
        }
        buffer.write(romanizeJapanese(run.toString()));
      } else if (_isHangul(code)) {
        // Extract Korean run
        final run = StringBuffer();
        while (i < runes.length && (_isHangul(runes[i]) || _isHangulJamo(runes[i]))) {
          run.writeCharCode(runes[i]);
          i++;
        }
        buffer.write(romanizeKorean(run.toString()));
      } else if (_isCjkIdeograph(code)) {
        final char = String.fromCharCode(code);
        final py = _pinyinMap[char];
        if (py != null) {
          buffer.write(py);
          buffer.write(' ');
        } else {
          buffer.writeCharCode(code);
        }
        i++;
      } else {
        buffer.writeCharCode(code);
        i++;
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. JAPANESE ROMANIZER (Hepburn System)
  // ════════════════════════════════════════════════════════════════════════════

  static String romanizeJapanese(String text) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    final runes = text.runes.toList();
    int i = 0;

    while (i < runes.length) {
      final code = runes[i];

      // Check for Sokuon (っ / ッ) small tsu (doubles the following consonant)
      if (code == 0x3063 || code == 0x30C3) {
        if (i + 1 < runes.length) {
          final nextSyllable = _lookupKana(runes, i + 1);
          if (nextSyllable != null && nextSyllable.romaji.isNotEmpty) {
            final firstConsonant = nextSyllable.romaji[0].toLowerCase();
            if (firstConsonant == 'c' && nextSyllable.romaji.startsWith('ch')) {
              buffer.write('t'); // e.g. matchi instead of cchi
            } else if (RegExp(r'[a-z]').hasMatch(firstConsonant) && !'aeiou'.contains(firstConsonant)) {
              buffer.write(firstConsonant);
            }
            i++;
            continue;
          }
        }
      }

      // Check 2-character digraphs first (e.g. きゃ kya, しょ sho, ティ ti)
      final digraph = _lookupDigraph(runes, i);
      if (digraph != null) {
        buffer.write(digraph.romaji);
        i += digraph.length;
        continue;
      }

      // Check 1-character Kana
      final single = _lookupKana(runes, i);
      if (single != null) {
        buffer.write(single.romaji);
        i += single.length;
        continue;
      }

      // Chōonpu (ー) long vowel extender in Katakana
      if (code == 0x30FC) {
        final prevStr = buffer.toString();
        if (prevStr.isNotEmpty) {
          final lastChar = prevStr[prevStr.length - 1].toLowerCase();
          if ('aeiou'.contains(lastChar)) {
            buffer.write(lastChar);
          }
        }
        i++;
        continue;
      }

      // If Hanzi/Kanji character, check common Onyomi/Kunyomi or Pinyin fallback
      if (_isCjkIdeograph(code)) {
        final char = String.fromCharCode(code);
        final reading = _japaneseKanjiMap[char] ?? _pinyinMap[char];
        if (reading != null) {
          if (buffer.isNotEmpty && !buffer.toString().endsWith(' ')) buffer.write(' ');
          buffer.write(reading);
          buffer.write(' ');
        } else {
          buffer.writeCharCode(code);
        }
        i++;
        continue;
      }

      // Pass through normal Latin/symbols/punctuation
      buffer.writeCharCode(code);
      i++;
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static _KanaMatch? _lookupDigraph(List<int> runes, int index) {
    if (index + 1 >= runes.length) return null;
    final pair = String.fromCharCodes([runes[index], runes[index + 1]]);
    final romaji = _japaneseDigraphs[pair];
    if (romaji != null) {
      return _KanaMatch(romaji, 2);
    }
    return null;
  }

  static _KanaMatch? _lookupKana(List<int> runes, int index) {
    if (index >= runes.length) return null;
    final char = String.fromCharCode(runes[index]);
    final romaji = _japaneseKanaMap[char];
    if (romaji != null) {
      return _KanaMatch(romaji, 1);
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. KOREAN ROMANIZER (Revised Romanization of Korean)
  // ════════════════════════════════════════════════════════════════════════════

  static const _hangulSBase = 0xAC00;
  static const _hangulSCount = 11172;
  static const _hangulNCount = 588; // 21 * 28
  static const _hangulTCount = 28;

  static const List<String> _koreanChoseong = [
    'g', 'kk', 'n', 'd', 'tt', 'r', 'm', 'b', 'pp',
    's', 'ss', '', 'j', 'jj', 'ch', 'k', 't', 'p', 'h'
  ];

  static const List<String> _koreanJungseong = [
    'a', 'ae', 'ya', 'yae', 'eo', 'e', 'yeo', 'ye', 'o',
    'wa', 'wae', 'oe', 'yo', 'u', 'wo', 'we', 'wi', 'yu',
    'eu', 'ui', 'i'
  ];

  static const List<String> _koreanJongseong = [
    '', 'k', 'k', 'k', 'n', 'n', 'n', 't', 'l', 'k',
    'm', 'p', 't', 't', 'p', 'l', 'm', 'p', 'p', 't',
    't', 'ng', 't', 't', 'k', 't', 'p', 't'
  ];

  static String romanizeKorean(String text) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    final runes = text.runes.toList();
    String carryOverCho = '';

    for (int i = 0; i < runes.length; i++) {
      final code = runes[i];

      if (_isHangul(code)) {
        final sIndex = code - _hangulSBase;
        final lIndex = sIndex ~/ _hangulNCount;
        final vIndex = (sIndex % _hangulNCount) ~/ _hangulTCount;
        final tIndex = sIndex % _hangulTCount;

        String cho = carryOverCho.isNotEmpty ? carryOverCho : _koreanChoseong[lIndex];
        carryOverCho = '';
        String jung = _koreanJungseong[vIndex];
        String jong = _koreanJongseong[tIndex];

        // Phonetic assimilation / Liaison with next syllable:
        // if current syllable has final consonant (batchim) and next syllable starts with empty 'ㅇ' (lIndex 11)
        if (tIndex > 0 && i + 1 < runes.length && _isHangul(runes[i + 1])) {
          final nextSIndex = runes[i + 1] - _hangulSBase;
          final nextLIndex = nextSIndex ~/ _hangulNCount;
          if (nextLIndex == 11) {
            // Next is empty ㅇ (ieum) -> transfer batchim to next syllable
            switch (tIndex) {
              case 20: // ㅆ (ssangsiot) -> e.g. 있어 -> isseo
                jong = 's';
                carryOverCho = 's';
                break;
              case 19: // ㅅ (siot)
                jong = '';
                carryOverCho = 's';
                break;
              case 8: // ㄹ (rieul) -> e.g. 달이 -> dari
                jong = '';
                carryOverCho = 'r';
                break;
              case 1: // ㄱ (giyeok)
                jong = '';
                carryOverCho = 'g';
                break;
              case 17: // ㅂ (bieup)
                jong = '';
                carryOverCho = 'b';
                break;
              case 7: // ㄷ (digeut)
                jong = '';
                carryOverCho = 'd';
                break;
            }
          }
        }

        // Special common word adjustments:
        // '감사합니다' -> 'gamsahamnida' (ㅂ before ㄴ becomes m)
        if (tIndex == 17 && i + 1 < runes.length && _isHangul(runes[i + 1])) {
          final nextSIndex = runes[i + 1] - _hangulSBase;
          final nextLIndex = nextSIndex ~/ _hangulNCount;
          if (nextLIndex == 2) { // ㄴ (nieun)
            jong = 'm';
          }
        }

        buffer.write(cho);
        buffer.write(jung);
        buffer.write(jong);
      } else {
        carryOverCho = '';
        buffer.writeCharCode(code);
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. MANDARIN CHINESE ROMANIZER (Pinyin)
  // ════════════════════════════════════════════════════════════════════════════

  static String romanizeMandarin(String text, {bool includeTones = false}) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    final runes = text.runes.toList();

    for (int i = 0; i < runes.length; i++) {
      final code = runes[i];
      final char = String.fromCharCode(code);

      if (_isCjkIdeograph(code)) {
        final pinyin = includeTones
            ? (_pinyinTonedMap[char] ?? _pinyinMap[char])
            : _pinyinMap[char];

        if (pinyin != null) {
          buffer.write(pinyin);
          // Add space between Chinese syllables if followed by another Hanzi
          if (i + 1 < runes.length && _isCjkIdeograph(runes[i + 1])) {
            buffer.write(' ');
          }
        } else {
          buffer.writeCharCode(code);
        }
      } else {
        buffer.writeCharCode(code);
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. UNICODE RANGE HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  static bool _isHiragana(int code) => code >= 0x3040 && code <= 0x309F;
  static bool _isKatakana(int code) => (code >= 0x30A0 && code <= 0x30FF) || (code >= 0x31F0 && code <= 0x31FF);
  static bool _isHangul(int code) => code >= _hangulSBase && code < _hangulSBase + _hangulSCount;
  static bool _isHangulJamo(int code) => (code >= 0x1100 && code <= 0x11FF) || (code >= 0x3130 && code <= 0x318F);
  static bool _isCjkIdeograph(int code) => (code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF);

  // ════════════════════════════════════════════════════════════════════════════
  // 5. JAPANESE PHONETIC TABLES
  // ════════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _japaneseDigraphs = {
    // Hiragana
    'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
    'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
    'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
    'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
    'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
    'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
    'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
    'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
    'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
    'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
    'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
    'ふぁ': 'fa', 'ふぃ': 'fi', 'ふぇ': 'fe', 'ふぉ': 'fo',
    'てぃ': 'ti', 'でぃ': 'di', 'ゔぁ': 'va', 'ゔぃ': 'vi',
    'ゔぇ': 've', 'ゔぉ': 'vo',

    // Katakana
    'キャ': 'kya', 'キュ': 'kyu', 'キョ': 'kyo',
    'シャ': 'sha', 'シュ': 'shu', 'ショ': 'sho',
    'チャ': 'cha', 'チュ': 'chu', 'チョ': 'cho',
    'ニャ': 'nya', 'ニュ': 'nyu', 'ニョ': 'nyo',
    'ヒャ': 'hya', 'ヒュ': 'hyu', 'ヒョ': 'hyo',
    'ミャ': 'mya', 'ミュ': 'myu', 'ミョ': 'myo',
    'リャ': 'rya', 'リュ': 'ryu', 'リョ': 'ryo',
    'ギャ': 'gya', 'ギュ': 'gyu', 'ギョ': 'gyo',
    'ジャ': 'ja', 'ジュ': 'ju', 'ジョ': 'jo',
    'ビャ': 'bya', 'ビュ': 'byu', 'ビョ': 'byo',
    'ピャ': 'pya', 'ピュ': 'pyu', 'ピョ': 'pyo',
    'ファ': 'fa', 'フィ': 'fi', 'フェ': 'fe', 'フォ': 'fo',
    'ティ': 'ti', 'ディ': 'di', 'ヴァ': 'va', 'ヴィ': 'vi',
    'ヴェ': 've', 'ヴォ': 'vo', 'シェ': 'she', 'ジェ': 'je',
    'チェ': 'che', 'ツァ': 'tsa', 'ツィ': 'tsi', 'ツェ': 'tse', 'ツォ': 'tso',
  };

  static const Map<String, String> _japaneseKanaMap = {
    // Hiragana basic
    'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
    'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
    'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
    'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
    'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
    'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
    'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'mo': 'mo', 'も': 'mo',
    'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
    'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
    'わ': 'wa', 'を': 'o', 'ん': 'n',
    // Hiragana dakuten & handakuten
    'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
    'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
    'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
    'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
    'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
    'ゔ': 'vu',

    // Katakana basic
    'ア': 'a', 'イ': 'i', 'ウ': 'u', 'エ': 'e', 'オ': 'o',
    'カ': 'ka', 'キ': 'ki', 'ク': 'ku', 'ケ': 'ke', 'コ': 'ko',
    'サ': 'sa', 'シ': 'shi', 'ス': 'su', 'セ': 'se', 'ソ': 'so',
    'タ': 'ta', 'チ': 'chi', 'ツ': 'tsu', 'テ': 'te', 'ト': 'to',
    'ナ': 'na', 'ニ': 'ni', 'ヌ': 'nu', 'ネ': 'ne', 'ノ': 'no',
    'ハ': 'ha', 'ヒ': 'hi', 'フ': 'fu', 'ヘ': 'he', 'ホ': 'ho',
    'マ': 'ma', 'ミ': 'mi', 'ム': 'mu', 'メ': 'me', 'モ': 'mo',
    'ヤ': 'ya', 'ユ': 'yu', 'ヨ': 'yo',
    'ラ': 'ra', 'リ': 'ri', 'ル': 'ru', 'レ': 're', 'ロ': 'ro',
    'ワ': 'wa', 'ヲ': 'o', 'ン': 'n',
    // Katakana dakuten & handakuten
    'ガ': 'ga', 'ギ': 'gi', 'グ': 'gu', 'ゲ': 'ge', 'ゴ': 'go',
    'ザ': 'za', 'ジ': 'ji', 'ズ': 'zu', 'ゼ': 'ze', 'ゾ': 'zo',
    'ダ': 'da', 'ヂ': 'ji', 'ヅ': 'zu', 'デ': 'de', 'ド': 'do',
    'バ': 'ba', 'ビ': 'bi', 'ブ': 'bu', 'ベ': 'be', 'ボ': 'bo',
    'パ': 'pa', 'ピ': 'pi', 'プ': 'pu', 'ペ': 'pe', 'ポ': 'po',
    'ヴ': 'vu',
  };

  static const Map<String, String> _japaneseKanjiMap = {
    '私': 'watashi', '僕': 'boku', '君': 'kimi', '愛': 'ai', '心': 'kokoro',
    '今': 'ima', '夢': 'yume', '夜': 'yoru', '空': 'sora', '花': 'hana',
    '雨': 'ame', '光': 'hikari', '風': 'kaze', '海': 'umi', '星': 'hoshi',
    '世界': 'sekai', '時間': 'jikan', '歌': 'uta', '声': 'koe', '涙': 'namida',
    '日': 'hi', '月': 'tsuki', '道': 'michi', '手': 'te', '目': 'me',
    '春': 'haru', '夏': 'natsu', '秋': 'aki', '冬': 'fuyu', '音': 'oto',
    '記憶': 'kioku', '永遠': 'eien', '約束': 'yakusoku', '未来': 'mirai',
    '青': 'ao',
  };

  // ════════════════════════════════════════════════════════════════════════════
  // 6. MANDARIN HANZI TO PINYIN DICTIONARY (Popular C-Pop Characters)
  // ════════════════════════════════════════════════════════════════════════════

  static const Map<String, String> _pinyinMap = {
    '你': 'ni', '我': 'wo', '他': 'ta', '她': 'ta', '它': 'ta',
    '们': 'men', '好': 'hao', '的': 'de', '是': 'shi', '在': 'zai',
    '不': 'bu', '了': 'le', '有': 'you', '和': 'he', '人': 'ren',
    '这': 'zhe', '中': 'zhong', '大': 'da', '来': 'lai', '上': 'shang',
    '个': 'ge', '到': 'dao', '说': 'shuo', '爱': 'ai', '心': 'xin',
    '天': 'tian', '地': 'di', '夜': 'ye', '月': 'yue', '日': 'ri',
    '晴': 'qing', '雨': 'yu', '风': 'feng', '云': 'yun', '光': 'guang',
    '星': 'xing', '海': 'hai', '花': 'hua', '水': 'shui', '火': 'huo',
    '想': 'xiang', '要': 'yao', '知': 'zhi', '道': 'dao', '能': 'neng',
    '过': 'guo', '得': 'de', '看': 'kan', '见': 'jian', '听': 'ting',
    '唱': 'chang', '歌': 'ge', '声': 'sheng', '哭': 'ku', '笑': 'xiao',
    '走': 'zou', '去': 'qu', '回': 'hui', '家': 'jia', '时': 'shi',
    '间': 'jian', '年': 'nian', '生': 'sheng', '死': 'si', '梦': 'meng',
    '情': 'qing', '泪': 'lei', '痕': 'hen', '痛': 'tong', '快': 'kuai',
    '乐': 'le', '美': 'mei', '丽': 'li', '真': 'zhen', '假': 'jia',
    '对': 'dui', '错': 'cuo', '开': 'kai', '关': 'guan', '明': 'ming',
    '白': 'bai', '黑': 'hei', '红': 'hong', '蓝': 'lan', '绿': 'lv',
    '黄': 'huang', '紫': 'zi', '金': 'jin', '银': 'yin', '一': 'yi',
    '二': 'er', '三': 'san', '四': 'si', '五': 'wu', '六': 'liu',
    '七': 'qi', '八': 'ba', '九': 'jiu', '十': 'shi', '百': 'bai',
    '千': 'qian', '万': 'wan', '亿': 'yi', '最': 'zui', '很': 'hen',
    '太': 'tai', '更': 'geng', '多': 'duo', '少': 'shao', '长': 'chang',
    '短': 'duan', '高': 'gao', '低': 'di', '远': 'yuan', '近': 'jin',
    '深': 'shen', '浅': 'qian', '重': 'zhong', '轻': 'qing', '男': 'nan',
    '女': 'nv', '朋': 'peng', '友': 'you', '相': 'xiang', '信': 'xin',
    '希': 'xi', '望': 'wang', '等': 'deng', '待': 'dai', '永': 'yong',
    '世': 'shi', '界': 'jie', '无': 'wu', '论': 'lun', '如': 'ru',
    '何': 'he', '只': 'zhi', '因': 'yin', '为': 'wei', '所': 'suo',
    '以': 'yi', '但': 'dan', '果': 'guo', '就': 'jiu', '像': 'xiang',
    '样': 'yang', '自': 'zi', '由': 'you', '飞': 'fei', '翔': 'xiang',
    '翅': 'chi', '膀': 'bang', '拥': 'yong', '抱': 'bao', '温': 'wen',
    '暖': 'nuan', '孤': 'gu', '单': 'dan', '寂': 'ji', '寞': 'mo',
    '陪': 'pei', '伴': 'ban', '离': 'li', '别': 'bie', '思': 'si',
    '念': 'nian', '忆': 'yi', '从': 'cong', '前': 'qian', '未': 'wei',
    '现': 'xian', '眼': 'yan', '神': 'shen', '微': 'wei', '面': 'mian',
    '容': 'rong', '身': 'shen', '影': 'ying', '谢': 'xie', '青': 'qing',
  };

  static const Map<String, String> _pinyinTonedMap = {
    '你': 'nǐ', '我': 'wǒ', '他': 'tā', '她': 'tā', '它': 'tā',
    '们': 'men', '好': 'hǎo', '的': 'de', '是': 'shì', '在': 'zài',
    '不': 'bù', '了': 'le', '有': 'yǒu', '和': 'hé', '人': 'rén',
    '这': 'zhè', '中': 'zhōng', '大': 'dà', '来': 'lái', '上': 'shàng',
    '爱': 'ài', '心': 'xīn', '天': 'tiān', '夜': 'yè', '月': 'yuè',
    '晴': 'qíng', '雨': 'yǔ', '风': 'fēng', '云': 'yún', '星': 'xīng',
    '海': 'hǎi', '花': 'huā', '梦': 'mèng', '歌': 'gē', '声': 'shēng',
    '泪': 'lèi', '痛': 'tòng', '笑': 'xiào', '哭': 'kū', '飞': 'fēi',
    '谢': 'xiè',
  };
}

class _KanaMatch {
  final String romaji;
  final int length;
  const _KanaMatch(this.romaji, this.length);
}
