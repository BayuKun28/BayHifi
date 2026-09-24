# 📐 Baydev HiFi — Engineering & Design Rules (`rules.md`)

Aturan resmi arsitektur perangkat lunak, standar koding fungsi, pedoman antarmuka **Material 3 Expressive**, dan struktur folder profesional untuk pengembangan pemutar musik audiophile **Baydev HiFi**.

---

## 1. Visi & Filosofi Rekayasa
1. **Audiophile First**: Akurasi suara (*bit-perfect*), zero latency jitter, dan perlindungan clipping digital (*safe headroom pre-amp*) adalah prioritas mutlak.
2. **60/120 FPS Fluidity**: Antarmuka visualizer spektrum, kurva Pro-Q, dan animasi tidak boleh menghambat pemutaran audio maupun mengalami frame drop.
3. **Clean & Modular**: Setiap fitur (*Feature-First*) harus independen, dapat diuji secara terisolasi, dan mudah dipelihara.
4. **Deterministic Audio Math**: Seluruh perhitungan matematika DSP (Biquad, FFT, SPL, AutoEQ) harus berupa fungsi murni (*pure functions*).

---

## 2. Pedoman Desain Antarmuka (Material 3 Expressive & Namida Architecture)

### 2.1 Sistem Warna & Theming (Namida Custom Palette Engine)
- **Theme Modes (Dark / Light / System)**:
  - `ThemeMode.dark`: Studio Dark Obsidian (`#0D0F14`) atau *True OLED Black* (`#000000`).
  - `ThemeMode.light`: Clean Studio Light / Champagne (`#F5F7FA`) dengan kontras teks tinggi.
  - `ThemeMode.system`: Mengikuti preferensi tema perangkat (OS) secara otomatis.
- **Namida Dynamic Palette & Custom Colors**:
  - UI secara dinamis mengekstrak palet warna dari Album Art lagu aktif menggunakan `palette_generator`.
  - Pilihan preset palet audio studio terkurasi:
    - *Obsidian Cyan* (Namida Cyber Neon `#00F0FF`)
    - *Amber Tube Glow* (Warm Analog Tube `#FF9F0A`)
    - *Emerald HiFi* (Mint Studio Precision `#00E676`)
    - *Electric Purple* (Audiophile Violet `#BF5AF2`)
    - *Crimson Passion* (Mastering Red `#FF3B30`)
    - *True OLED Black* (0% battery consumption AMOLED)
  - Pengguna bebas memilih Accent Color custom (HEX / Swatch) untuk slider, indikator node, dan kurva glow.
- **Surface Elevation**: Gunakan tonal elevation Material 3 (`#161920`, `#1C202A`, `#242A38`), jangan gunakan drop shadow kasar.
- **Neon Glow Palette**:
  - `EQ Curve`: Amber Warmth (`#FF9F0A`) dengan translusen glow.
  - `Driver FR`: Cyan Neon (`#00F0FF`).
  - `Target FR`: Mint Emerald (`#00FFA3`).
  - `Active Selection`: Electric Purple (`#BF5AF2`) atau Emerald (`#10B981`).
  - `Danger / Peak Clipping`: Crimson Red (`#FF3B30`).

### 2.2 Bentuk (Shapes) & Tipografi
- **Expressive Shapes**: Gunakan squircle dan rounded shape Material 3:
  - Mini Buttons & Pills: `BorderRadius.circular(8)` s/d `(12)`.
  - Cards & Audio Nodes: `BorderRadius.circular(16)`.
  - Album Art Container: Pilihan corner radius dinamis (`0px`, `16px`, `28px`).
  - Bottom Sheets & Modals: `BorderRadius.vertical(top: Radius.circular(28))`.
- **Tipografi**: Gunakan font modern (misal: Inter / Roboto / JetBrains Mono untuk angka audio):
  - Semua angka frekuensi (`Hz`), gain (`dB`), Q-factor, dan audio badge (`24-bit / 192 kHz`) **wajib** menggunakan *tabular figures* (`FontFeature.tabularFigures()`) agar angka tidak bergetar saat nilainya berubah.

### 2.3 Aturan Performa CustomPainter & Visualizer
- **`RepaintBoundary`**: Semua canvas interaktif (`ProQCanvas`, `RtaVisualizerCanvas`, `WaveformCanvas`) **wajib** dibungkus dalam `RepaintBoundary` agar tidak memicu repaint pada keseluruhan widget tree.
- **Zero Allocations inside `paint()`**:
  - Dilarang membuat instance baru `Paint()`, `Path()`, atau `TextStyle()` di dalam method `paint()`.
  - Objek `Paint` harus di-cache sebagai field class dan hanya nilai warna/properti yang diperbarui.
- **Logarithmic Math Caching**: Nilai mapping koordinat piksel ke frekuensi logaritmik ($20\text{ Hz} \leftrightarrow 20,000\text{ Hz}$) harus diprekomputasi atau menggunakan lookup table saat resize canvas.

---

### 2.4 Arsitektur MiniPlayer & Navigasi (Namida-Inspired Expandable Player)
- **Tanpa Tab Khusus Player**:
  - Layar pemutar musik utama (*Now Playing*) **tidak** menggunakan tab mandiri di Bottom Navigation Bar.
  - Tab utama aplikasi Baydev HiFi terdiri dari 4 tab:
    1. **Dashboard** (Index 0): Status engine SoLoud, DAC indicator, launcher Pro-Q, statistik library.
    2. **DSP Rack** (Index 1): 10+ modul mastering (Tube Exciter, Compressor, Crossfeed, Limiter).
    3. **Library** (Index 2): Pustaka terpadu offline lokal dan cloud Navidrome.
    4. **Settings** (Index 3): Kustomisasi tema, custom palette, dark/light/system, visualizer, dan DAC.
- **Omnipresent Expandable MiniPlayer**:
  - MiniPlayer selalu melayang (*docked*) tepat di atas Bottom Navigation Bar (atau di bagian bawah layar saat navigasi tersembunyi).
  - Menampilkan thumbnail album art (squircle rounded), judul lagu bergeser halus (*marquee* jika panjang), nama artist, tombol Play/Pause, tombol Next, dan progress bar tipis 2.5px di bagian bawah.
  - **Fluid Gestures & Spring Physics**:
    - Ketukan (*tap*) atau gesekan ke atas (*swipe up*) membuka layar **NowPlayingScreen** secara penuh dengan transisi bottom-sheet / sliding panel.
    - Gesekan ke bawah (*swipe down*) atau tombol chevron collapse mengembalikan player ke bentuk MiniPlayer tanpa menghentikan pemutaran audio.

## 3. Standar Koding & Pembuatan Fungsi

### 3.1 Aturan Penulisan Fungsi & Clean Code
- **Single Responsibility Principle (SRP)**: Satu fungsi hanya melakukan satu tugas spesifik. Panjang fungsi tidak boleh melebihi 40 baris kode jika memungkinkan.
- **Pure Functions untuk Audio Math**:
  - Fungsi koefisien filter biquad (Peaking, Shelf, Notch, HPF, LPF) harus murni menerima parameter $(f_0, \text{Gain}, Q, F_s)$ dan mengembalikan koefisien $(b_0, b_1, b_2, a_1, a_2)$.
  - Fungsi parser REW/Squiglink harus murni menerima `String` teks dan mengembalikan `List<FrequencyPoint>`.
- **Immutability**:
  - Semua model data (`Track`, `Album`, `EqBand`, `DspPreset`, `DriverProfile`) **wajib immutable** (`@immutable` atau Freezed).
  - Gunakan method `copyWith()` untuk perubahan state.
- **Dart 3 Modern Idioms**:
  - Gunakan Pattern Matching dan Exhaustive Switch untuk enum/sealed classes:
    ```dart
    sealed class DspEffect {}
    // Pattern match tanpa default case untuk menjamin compile-time safety
    ```
  - Gunakan Records `(double freq, double spl)` untuk data pair ringan.

### 3.2 Thread Safety & Isolates
- **Non-blocking UI Thread**:
  - Operasi scanning file lokal berukuran besar, ekstraksi tag ID3/FLAC, parsing file REW >500 baris, dan fitting kurva AutoEQ **wajib** dieksekusi di background worker menggunakan `Isolate.run()`.
  - UI thread Flutter hanya menerima hasil akhir untuk di-render.

### 3.3 Penanganan Error & Keandalan
- **No Swallowed Exceptions**: Dilarang menggunakan blok `catch (e) {}` kosong. Setiap error harus dicatat ke logger dan disajikan ke UI dengan pesan bersahabat.
- **Type-safe Results**: Gunakan tipe `Result<T, Failure>` untuk operasi I/O (Navidrome API, file import, codec decoding).
- **Audio Engine Resilience**: Jika format file audio gagal di-decode, player tidak boleh crash; harus otomatis memicu event `PlaybackError` dan memberikan opsi skip ke track berikutnya.

---

## 4. Struktur Folder Standar Profesional (Feature-First Architecture)

```
lib/
├── main.dart                             # Entry point aplikasi
├── app/
│   ├── app.dart                          # MaterialApp setup, theme, router
│   ├── theme/                            # Material 3 Expressive theme definitions
│   │   ├── app_colors.dart               # Palette studio obsidian, neon accents
│   │   ├── app_typography.dart           # Font weights, tabular figures
│   │   ├── color_schemes.dart            # M3 Light, Dark, True Black schemes
│   │   └── dynamic_theme_controller.dart # Album art color extraction
│   └── routes/                           # GoRouter / declarative routes
│
├── core/                                 # Utilitas global dan abstraksi bersama
│   ├── constants/                        # Konstanta audio (sample rates, buffer sizes)
│   ├── database/                         # SQLite / Drift database initialization
│   ├── errors/                           # Failure classes & exception handlers
│   ├── network/                          # Dio client, interceptors, retry policy
│   ├── utils/                            # Formatters, log-scale converters, math helpers
│   └── widgets/                          # Shared UI components (Pills, Sliders, Knobs)
│
├── audio_engine/                         # Low-Level Audio & Native Bridge
│   ├── soloud_controller.dart            # Wrapper instance flutter_soloud
│   ├── audio_decoders.dart               # Decoder routing (FLAC, MP3, WAV, DSD)
│   ├── buffer_stream_source.dart         # Streaming source handler
│   └── native_ffi/                       # C++ FFI bindings untuk custom DSP
│
└── features/                             # Modular Feature-First Layer
    ├── player/                           # Core Player & Now Playing Screen
    │   ├── domain/                       # Track, Album, PlaybackState models
    │   ├── data/                         # Player repository & audio session
    │   └── presentation/                 # Now Playing UI, Mini Player, Vinyl Art
    │
    ├── pro_q_studio/                     # Parametric EQ Studio (Sesuai Referensi Gambar)
    │   ├── domain/                       # EqBand, FilterType, BiquadCoefficients
    │   ├── data/                         # EQ presets storage & local save
    │   └── presentation/
    │       ├── pro_q_studio_screen.dart  # Main screen Pro-Q
    │       ├── widgets/
    │       │   ├── eq_curve_painter.dart # CustomPainter 20Hz-20kHz log grid
    │       │   ├── node_handle.dart      # Interactive draggable nodes
    │       │   ├── band_strip_bar.dart   # B1..B10 pill indicators
    │       │   └── rta_overlay.dart      # Real-time FFT spectrum overlay
    │       └── controllers/              # Riverpod state notifier for EQ nodes
    │
    ├── auto_eq/                          # AutoEQ & Driver/Target Matching Engine
    │   ├── domain/                       # FrequencyResponse, TargetCurve, DeltaCurve
    │   ├── data/
    │   │   ├── parsers/                  # REW V5 parser, Squiglink CSV parser
    │   │   └── repositories/             # Built-in targets (Harman, IEF, HBB)
    │   └── presentation/
    │       ├── auto_eq_modal.dart        # Modal dialog matching (seperti di screenshot 2)
    │       └── controllers/              # Biquad optimizer & headroom calculator
    │
    ├── dsp_rack/                         # Mastering DSP Modules
    │   ├── domain/                       # DSP node contracts & parameters
    │   │   ├── tube_exciter.dart         # Triode harmonic saturation
    │   │   ├── binaural_crossfeed.dart   # Meier/Chu-Moy algorithm
    │   │   ├── dynamic_compressor.dart   # Threshold, Attack, Release, Knee
    │   │   ├── stereo_widener.dart       # Mid-Side matrix processor
    │   │   └── brickwall_limiter.dart    # Peak limiter & ceiling protection
    │   ├── data/                         # DSP rack presets repository
    │   └── presentation/                 # DSP rack control panel UI
    │
    ├── library/                          # Local Offline Music Library
    │   ├── domain/                       # TrackScanner, MetadataReader, HiResDetector
    │   ├── data/                         # Local storage crawler, SQLite track DB
    │   └── presentation/                 # Tracks, Albums, Artists, Folders screens
    │
    ├── navidrome/                        # Navidrome Cloud Integration (Subsonic API)
    │   ├── domain/                       # SubsonicSong, SubsonicAlbum, ServerConfig
    │   ├── data/                         # Subsonic REST client, Offline Cache Manager
    │   └── presentation/                 # Cloud browser, Sync status, Download queue
    │
    └── settings/                         # Preferences & Customization
        ├── domain/                       # SettingsModel (Themes, Waveform, Album Art, DAC)
        ├── data/                         # Shared preferences / local key-value store
        └── presentation/                 # Settings screen & personalization tabs
```

---

## 5. Aturan Khusus Audio Engine: Integrasi Local Folder `flutter_soloud`

### 5.1 Local Path Dependency Mandate
- Paket `flutter_soloud` **wajib** menggunakan local path dependency yang berada setara di:
  `/mnt/01DC9A2666E1A190/Other/PROJECTS/flutter_soloud` (relatif: `../flutter_soloud`).
- **Dilarang keras** menarik dependensi `flutter_soloud` dari pub.dev cloud, karena proyek ini terintegrasi erat dengan repository lokal tersebut.
- Konfigurasi pada `pubspec.yaml`:
  ```yaml
  dependencies:
    flutter_soloud:
      path: ../flutter_soloud
  ```

### 5.2 Hak Akses & Pengembangan Native C++
- Direktori `/mnt/01DC9A2666E1A190/Other/PROJECTS/flutter_soloud` merupakan bagian sah dari konteks kerja proyek Baydev HiFi.
- Akses baca dan modifikasi diperbolehkan pada:
  - `src/`: Core engine SoLoud C++, backend miniaudio, dan implementasi filter native.
  - `lib/src/filters/`: Filter biquad, compressor, limiter, reverb, dan pitch shift.
  - `hook/` dan `linux/`/`windows/`: Build scripts native FFI dan CMake.
- Jika fitur DSP audio membutuhkan modul filter C++ baru (seperti *Tube Exciter triode saturation* atau *Meier crossfeed*), kode native dapat langsung dikembangkan atau dihubungkan melalui local package ini.
- Seluruh 14 dokumentasi skill resmi bawaan dari folder `flutter_soloud/skills/` telah disinkronkan ke dalam `.agents/skills/` proyek ini.

---

## 6. Ringkasan Eksekusi
Aturan di atas berlaku untuk seluruh penulisan kode pada project **Baydev HiFi**. Setiap perubahan atau penambahan modul baru wajib mematuhi pemisahan layer, penamaan konsisten, pengujian matematika DSP, dan performa tinggi pada rendering antarmuka.

