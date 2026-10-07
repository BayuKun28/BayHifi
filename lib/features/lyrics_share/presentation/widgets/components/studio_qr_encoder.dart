import 'dart:typed_data';

/// Pure Dart high-performance QR Code Encoder supporting Versions 1 through 7 (Byte mode)
/// Generates a deterministic 2D boolean matrix for high-resolution canvas rendering.
class StudioQrEncoder {
  /// Encodes input [text] into a 2D boolean matrix (true = dark module, false = light module)
  static List<List<bool>> encode(String text, {int? forcedVersion}) {
    final utf8Bytes = Uint8List.fromList(text.codeUnits);
    final dataLength = utf8Bytes.length;

    // Determine minimum QR version needed for Byte mode with Error Correction Level M
    final version = forcedVersion ?? _calculateMinVersion(dataLength);
    final moduleCount = version * 4 + 17;

    // Allocate module grid
    final grid = List.generate(moduleCount, (_) => List.filled(moduleCount, false));
    final isFunction = List.generate(moduleCount, (_) => List.filled(moduleCount, false));

    // 1. Place Finder Patterns (7x7 at 3 corners)
    _placeFinder(grid, isFunction, 0, 0);
    _placeFinder(grid, isFunction, moduleCount - 7, 0);
    _placeFinder(grid, isFunction, 0, moduleCount - 7);

    // 2. Place Alignment Patterns (for version >= 2)
    final alignCoords = _getAlignmentCoords(version);
    for (final r in alignCoords) {
      for (final c in alignCoords) {
        if (!isFunction[r][c]) {
          _placeAlignment(grid, isFunction, r, c);
        }
      }
    }

    // 3. Place Timing Patterns
    for (int i = 8; i < moduleCount - 8; i++) {
      final val = (i % 2) == 0;
      if (!isFunction[6][i]) {
        grid[6][i] = val;
        isFunction[6][i] = true;
      }
      if (!isFunction[i][6]) {
        grid[i][6] = val;
        isFunction[i][6] = true;
      }
    }

    // 4. Reserve Format Info areas
    for (int i = 0; i < 9; i++) {
      if (i < moduleCount) {
        isFunction[8][i] = true;
        isFunction[i][8] = true;
      }
    }
    for (int i = moduleCount - 8; i < moduleCount; i++) {
      isFunction[8][i] = true;
      isFunction[i][8] = true;
    }
    // Dark module
    grid[moduleCount - 8][8] = true;
    isFunction[moduleCount - 8][8] = true;

    // 5. Generate Data + EC Codewords
    final dataCodewords = _generateDataCodewords(utf8Bytes, version);
    final ecCount = _getEcCodewordsCount(version);
    final ecCodewords = _generateEcCodewords(dataCodewords, ecCount);

    // Interleave/combine data and EC codewords
    final finalCodewords = <int>[...dataCodewords, ...ecCodewords];

    // Convert codewords to bits
    final bitStream = <bool>[];
    for (final byte in finalCodewords) {
      for (int b = 7; b >= 0; b--) {
        bitStream.add(((byte >> b) & 1) == 1);
      }
    }
    // Add remainder bits if any
    final remainderBits = _getRemainderBits(version);
    for (int i = 0; i < remainderBits; i++) {
      bitStream.add(false);
    }

    // 6. Place Codeword Bits in 2-module zig-zag columns
    int bitIndex = 0;
    int col = moduleCount - 1;
    bool upward = true;

    while (col > 0) {
      if (col == 6) col--; // Skip vertical timing pattern column

      final rows = upward
          ? List.generate(moduleCount, (i) => moduleCount - 1 - i)
          : List.generate(moduleCount, (i) => i);

      for (final row in rows) {
        for (int c = 0; c < 2; c++) {
          final currentCol = col - c;
          if (!isFunction[row][currentCol]) {
            bool bit = false;
            if (bitIndex < bitStream.length) {
              bit = bitStream[bitIndex++];
            }
            // Mask pattern 0: (row + col) % 2 == 0
            final mask = ((row + currentCol) % 2) == 0;
            grid[row][currentCol] = bit ^ mask;
          }
        }
      }

      col -= 2;
      upward = !upward;
    }

    // 7. Place Format Information (Mask 0, Level M: 0x00 XOR with 0x5412 => 0x5412 = 0101010000010010)
    _placeFormatInfo(grid, moduleCount, 0x5412);

    return grid;
  }

  static void _placeFinder(List<List<bool>> grid, List<List<bool>> isFunction, int row, int col) {
    for (int r = -1; r <= 7; r++) {
      for (int c = -1; c <= 7; c++) {
        final nr = row + r;
        final nc = col + c;
        if (nr >= 0 && nr < grid.length && nc >= 0 && nc < grid.length) {
          isFunction[nr][nc] = true;
          if (r >= 0 && r <= 6 && c >= 0 && c <= 6) {
            if (r == 0 || r == 6 || c == 0 || c == 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4)) {
              grid[nr][nc] = true;
            } else {
              grid[nr][nc] = false;
            }
          } else {
            grid[nr][nc] = false; // Separator
          }
        }
      }
    }
  }

  static void _placeAlignment(List<List<bool>> grid, List<List<bool>> isFunction, int centerR, int centerC) {
    for (int r = -2; r <= 2; r++) {
      for (int c = -2; c <= 2; c++) {
        final nr = centerR + r;
        final nc = centerC + c;
        isFunction[nr][nc] = true;
        if (r.abs() == 2 || c.abs() == 2 || (r == 0 && c == 0)) {
          grid[nr][nc] = true;
        } else {
          grid[nr][nc] = false;
        }
      }
    }
  }

  static void _placeFormatInfo(List<List<bool>> grid, int size, int formatBits) {
    // 15-bit format representation
    final bits = List.generate(15, (i) => ((formatBits >> (14 - i)) & 1) == 1);

    // Around Top-Left finder
    grid[8][0] = bits[0];
    grid[8][1] = bits[1];
    grid[8][2] = bits[2];
    grid[8][3] = bits[3];
    grid[8][4] = bits[4];
    grid[8][5] = bits[5];
    grid[8][7] = bits[6];
    grid[8][8] = bits[7];
    grid[7][8] = bits[8];
    grid[5][8] = bits[9];
    grid[4][8] = bits[10];
    grid[3][8] = bits[11];
    grid[2][8] = bits[12];
    grid[1][8] = bits[13];
    grid[0][8] = bits[14];

    // Around Bottom-Left & Top-Right finders
    for (int i = 0; i < 7; i++) {
      grid[size - 1 - i][8] = bits[i];
    }
    for (int i = 0; i < 8; i++) {
      grid[8][size - 8 + i] = bits[7 + i];
    }
  }

  static int _calculateMinVersion(int dataLen) {
    // Capacities in Byte mode with Level M:
    // V1: 14, V2: 26, V3: 42, V4: 62, V5: 84, V6: 106, V7: 122
    if (dataLen <= 14) return 1;
    if (dataLen <= 26) return 2;
    if (dataLen <= 42) return 3;
    if (dataLen <= 62) return 4;
    if (dataLen <= 84) return 5;
    if (dataLen <= 106) return 6;
    return 7;
  }

  static int _getTotalCodewords(int version) {
    const totals = [0, 26, 44, 70, 100, 134, 172, 196];
    return totals[version.clamp(1, 7)];
  }

  static int _getEcCodewordsCount(int version) {
    const ecCounts = [0, 10, 16, 26, 36, 48, 64, 72];
    return ecCounts[version.clamp(1, 7)];
  }

  static int _getRemainderBits(int version) {
    const remainders = [0, 0, 7, 7, 7, 7, 7, 0];
    return remainders[version.clamp(1, 7)];
  }

  static List<int> _getAlignmentCoords(int version) {
    if (version == 1) return [];
    if (version == 2) return [6, 18];
    if (version == 3) return [6, 22];
    if (version == 4) return [6, 26];
    if (version == 5) return [6, 30];
    if (version == 6) return [6, 34];
    return [6, 22, 38];
  }

  static List<int> _generateDataCodewords(Uint8List data, int version) {
    final maxDataBytes = _getTotalCodewords(version) - _getEcCodewordsCount(version);

    // Byte mode indicator: 0100 (4 bits)
    // Character count indicator: 8 bits for V1-V9
    final bits = <bool>[];
    // 0100
    bits.addAll([false, true, false, false]);
    // 8-bit count
    for (int i = 7; i >= 0; i--) {
      bits.add(((data.length >> i) & 1) == 1);
    }
    // Data bytes
    for (final byte in data) {
      for (int i = 7; i >= 0; i--) {
        bits.add(((byte >> i) & 1) == 1);
      }
    }

    // Terminator (up to 4 zeroes)
    final totalDataBits = maxDataBytes * 8;
    final termLen = (totalDataBits - bits.length).clamp(0, 4);
    for (int i = 0; i < termLen; i++) {
      bits.add(false);
    }

    // Pad to multiple of 8
    while ((bits.length % 8) != 0) {
      bits.add(false);
    }

    // Convert to bytes
    final bytes = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int b = 0;
      for (int j = 0; j < 8; j++) {
        if (bits[i + j]) b |= (1 << (7 - j));
      }
      bytes.add(b);
    }

    // Fill with pad codewords 0xEC and 0x11
    final padCodewords = [0xEC, 0x11];
    int padIdx = 0;
    while (bytes.length < maxDataBytes) {
      bytes.add(padCodewords[padIdx % 2]);
      padIdx++;
    }

    return bytes;
  }

  static List<int> _generateEcCodewords(List<int> data, int ecCount) {
    // Reed-Solomon Error Correction via Galois Field GF(256)
    final exp = List.filled(512, 0);
    final log = List.filled(256, 0);

    int x = 1;
    for (int i = 0; i < 255; i++) {
      exp[i] = x;
      exp[i + 255] = x;
      log[x] = i;
      x = (x << 1);
      if ((x & 0x100) != 0) {
        x ^= 0x11D; // Primitive polynomial for QR codes
      }
    }

    int gfMul(int a, int b) {
      if (a == 0 || b == 0) return 0;
      return exp[log[a] + log[b]];
    }

    // Generator polynomial of degree ecCount
    var gen = [1];
    for (int i = 0; i < ecCount; i++) {
      final nextGen = List.filled(gen.length + 1, 0);
      for (int j = 0; j < gen.length; j++) {
        nextGen[j] ^= gfMul(gen[j], exp[i]);
        nextGen[j + 1] ^= gen[j];
      }
      gen = nextGen;
    }

    // Polynomial division
    final result = List<int>.from(data)..addAll(List.filled(ecCount, 0));
    for (int i = 0; i < data.length; i++) {
      final factor = result[i];
      if (factor != 0) {
        for (int j = 0; j < gen.length; j++) {
          result[i + j] ^= gfMul(gen[j], factor);
        }
      }
    }

    return result.sublist(result.length - ecCount);
  }
}
