# Baydev HiFi — Engineering & Design Rules (rules.md)

Aturan resmi arsitektur perangkat lunak, standar koding fungsi, pedoman antarmuka **Simple-As-F Bespoke Minimalist Architecture** (terinspirasi dari referensi Dribbble 27089924), dan struktur folder profesional untuk pengembangan pemutar musik audiophile **Baydev HiFi**.

---

## 1. Visi & Filosofi Rekayasa
1. **Audiophile First**: Akurasi suara (*bit-perfect*), zero latency jitter, dan perlindungan clipping digital (*safe headroom pre-amp*) adalah prioritas mutlak.
2. **60/120 FPS Fluidity**: Antarmuka visualizer spektrum, kurva Pro-Q, dan animasi tidak boleh menghambat pemutaran audio maupun mengalami frame drop.
3. **Clean & Modular**: Setiap fitur (*Feature-First*) harus independen, dapat diuji secara terisolasi, dan mudah dipelihara.
4. **Deterministic Audio Math**: Seluruh perhitungan matematika DSP (Biquad, FFT, SPL, AutoEQ) harus berupa fungsi murni (*pure functions*).
5. **Simple-As-F Bespoke Minimalist Architecture**: Seluruh antarmuka dirancang ultra-minimalis, bernafas lega, elegan, dan estetik terinspirasi dari referensi Dribbble 27089924 (`Music App`). Library `material_3_expressive` tidak lagi menjadi basis kaku/wajib, melainkan dapat digunakan secara selektif/pragmatis jika memang sesuai. Prioritas utama adalah komponen Flutter bespoke yang bersih, tanpa boilerplate kartu tebal yang tidak esensial.

---

## 2. Pedoman Desain Antarmuka (Simple-As-F Minimalist Architecture — Dribbble 27089924 Reference)

### 2.0 Filosofi Desain "Simple as F***" & Kebijakan Library M3E
Pada branch `simple-as-f`, aplikasi Baydev HiFi bertransformasi dari arsitektur studio padat (heavy bento cards) menjadi antarmuka **ultra-minimalist, bernapas lega (*high breathability*), modern, dan berfokus murni pada pengalaman musik yang tenang dan elegan**.
- **Kebijakan M3E**: Paket `material_3_expressive` **TIDAK LAGI MENJADI BASIS WAJIB**. Komponen UI utama dibangun menggunakan widget Flutter bespoke dengan kustomisasi presisi tinggi sesuai referensi Dribbble. Komponen M3E (`M3ESwitch`, `M3ESlider`, `M3EButton`, `motor` spring physics) hanya diterapkan secara selektif jika benar-benar cocok dan tidak merusak estetika minimalis.
- **Prinsip Anti-Clutter**: Hindari penumpukan kartu (*nested cards*), hilangkan border tebal yang bertumpuk, dan minimalkan badge status dekoratif yang tidak perlu.

### 2.1 Palet Warna Neutral Matte Obsidian Carbon & Studio Emerald Mint
- **Warna Latar Belakang & Permukaan Solid (100% Opaque Solid Surfaces)**:
  - `Neutral Matte Obsidian Canvas`: `#0D0E12` sebagai latar kanvas utama.
  - `Pitch Black Foundation`: `#08090B` untuk kontras kedalaman maksimum.
  - `Surface Elevated / Cards`: `#16181F` untuk elevated cards, dialog cards, dan floating capsule dock.
  - `Active Playing Capsule`: `#1E212B` untuk membungkus lagu yang sedang aktif diputar di playlist / library.
  - `Unplayed Seekbar & Muted Containers`: `#252834` / `#12141A`.
- **Aksen Utama (Clean Studio Emerald Mint)**:
  - `#10B981` (dengan highlight `#34D399`): Digunakan untuk keyword highlight pada judul, tombol Play aktif, seekbar played progress, toggle active switch, dan audio wave icon.
- **Warna Teks & Tipografi**:
  - `Primary Text`: Pure Solid White (`#FFFFFF`).
  - `Secondary / Subtitle`: Neutral Slate Gray (`#94A3B8` / tertiary `#64748B`).
  - `Crisp Subtle Borders`: Halus 0.8–1px kontras struktural solid (`#262936` / `#2E3242`).
- **Zero-Neon & Pure Solid Policy**:
  - Dilarang keras menggunakan neon menyala yang menyilaukan mata, radial glowing halos, atau drop shadow colored blur tebal. Seluruh permukaan harus solid, elegan, dan berkelas studio (`SimpleAsFTheme`, `StudioSurfaceTheme`).

### 2.2 Tipografi Dinamis Two-Tone & Spaced Tracking
- **Two-Tone Title Keywords**:
  - Judul layar dan bagian header menggunakan kombinasi teks dua warna: kata pertama berwarna putih solid, kata kedua/aksen diberi warna Studio Emerald Mint:
    - `"Liked"` (White) + `"Songs"` (Emerald Mint `#10B981`).
    - `"Recently"` (White) + `"Played"` (Emerald Mint `#10B981`).
    - `"Equalizer"` (White) + `"Studio"` (Emerald Mint `#10B981`).
- **Small Uppercase Spaced Tracking Headers**:
  - Label metadata dan navigasi mini menggunakan huruf kapital dengan *letter-spacing* lebar (1.5 – 2.0):
    - `WELCOME, MATT`, `RECENTLY PLAYED`, `LOST IN SPACE`, `DOWNLOAD`, `2 FOLLOWERS`.
- **Tabular Figures**:
  - Semua durasi waktu lagu (`2.34`, `6.37`) dan angka audio tetap wajib menggunakan `FontFeature.tabularFigures()`.

### 2.3 Layar Now Playing dengan Interactive Waveform Seekbar & Compact Auxiliary Bar
- **Album Artwork Squircle Card**:
  - Album art ditampilkan besar di tengah dengan bentuk squircle elegan (`borderRadius: BorderRadius.circular(28)` hingga `(32)`).
  - Bayangan lembut terpadu dengan latar belakang obsidian tanpa border kasar.
- **Track Meta & Favorit**:
  - Di bawah artwork: Icon Heart favorit di kiri (`LucideIcons.heart`), Judul Lagu (Bold White, ~24px) & Nama Artis (Sage Slate, ~14px) di tengah, dan Icon More/Options di kanan.
- **Interactive Audio Waveform Seekbar**:
  - Menggantikan slider garis tradisional dengan baris **Waveform Bar Spectrum** (40–60 batang amplitudo audio vertikal).
  - Bagian lagu yang sudah diputar disorot dengan warna putih terang / emerald mint, sedangkan bagian belum diputar bernada abu-abu sage gelap.
  - Timestamp diposisikan di bawah waveform pada sisi kiri (`0:00`) dan kanan (`durasi total`).
- **Minimalist Playback Controls**:
  - Tombol kontrol sejajar horizontal: Shuffle, Previous, Tombol Play/Pause utama berbentuk pill/circle kontras, Next, dan Repeat.
- **Compact Auxiliary Action Bar**:
  - Baris bawah menggunakan tombol icon ramping berukuran 34x30px (solid studio charcoal `#16181F`, border `#262936`) dengan tooltip untuk EQ, AutoEQ (tombol terpadu Driver & Target matching dialog `AutoEqModalDialog`), Lyrics, dan format badge `[WAV 44.1kHz]` ringkas. Dilarang menggunakan teks tombol panjang yang memadati layar dan memicu horizontal overflow.

### 2.4 Daftar Lagu Uncarded Floating & Active Capsule Highlight
- **Uncarded Clean List**:
  - Lagu di dalam playlist/library tidak dibungkus dalam kartu bento individual yang berat.
  - Setiap item berupa baris mengambang bersih (*floating row*): Title (Bold White), Artis & Album (Sage Slate), dan menu `...` di kanan.
- **Active Playing Highlight & Spacing**:
  - Lagu yang sedang aktif diputar otomatis dibungkus dalam **Soft Dark Capsule** (`borderRadius: BorderRadius.circular(16)`, latar `#1E212B`, border halus emerald).
  - Wajib memiliki *breathing room* yang proporsional (`minVerticalPadding: 8`, `bottom: 12`) agar garis border bawah tidak menabrak badge format file (`WAV 44.1kHz 03:57`).
- **Pembersihan Dashboard**:
  - Baris toggle download ditiadakan dari layar Dashboard agar daftar lagu bernapas lega dan tidak sesak.

### 2.5 Dashboard Discovery Grid & Arsitektur Layar Utama
- **Urutan Hierarki Dashboard**:
  1. Header Personal (`WELCOME, MATT`, avatar profil).
  2. Studio Wrapped Recap Banner (ringkasan personal statistik).
  3. Discovery Smart Mix Suggestion Banner (`StudioInstantMixBanner` bertenaga `InstantMixEngine`).
  4. Quick YouTube Music HiFi Launcher Capsule.
  5. Recently Played Squircle Grid: Mengambil data riwayat putar nyata dari `LocalPersistenceService.instance.getPlaybackHistory()`. Pada layar mobile (<650px), wajib menggunakan **Grid 2x2** (tepat 4 kartu).
  6. Liked / Top Songs: Baris mengambang bersih tanpa toggle download yang mengganggu.
- **Floating Capsule MiniPlayer & Dock**:
  - MiniPlayer melayang ramping di atas navigation bar dengan thumbnail album art, teks berjalan halus (*marquee*), tombol play/pause dan next, serta indikator progress halus.
  - Transisi buka-tutup NowPlayingScreen menggunakan gestur drag yang halus.

### 2.6 Ikonografi Lucide, Pure Solid Dialogs & Penempatan YouTube HiFi
- **Lucide Icons Library Mandate**: Seluruh ikon di aplikasi wajib menggunakan `lucide_icons_flutter` (`LucideIcons.*`). Dilarang mencampur icon legacy Material 1/2 ataupun HugeIcons.
- **Zero-Emoji Policy (Strictly Enforced)**: Dilarang keras menggunakan emoji di UI, tombol, dialog, komentar kode, maupun dokumentasi. Selalu gunakan icon resmi dari `LucideIcons`.
- **Pure Solid & Anti-Neon Policy**:
  - Dilarang keras efek neon glow buram (glowing box-shadows dengan colored blur yang tebal) atau tombol flood-fill neon terang benderang.
  - Seluruh tombol dialog (AutoEQ, Cloud Browser, dll.) wajib menggunakan *Solid Studio Buttons* (`#1E212B` / `#16181F` dengan border `#262936`), icon aksen tajam kontras, dan teks putih pekat `#FFFFFF`.
- **Penempatan YouTube Music HiFi**:
  - Di Library: Ditempatkan pada Tab Kategori ke-2 (`YouTube HiFi`) tepat di samping `Tracks` serta tombol streaming cepat di AppBar.
  - Di Dashboard: Disediakan kapsul peluncur streaming cepat.
- **Desktop Mobile Mode CSD Offset**: Pada desktop window mode mobile (<650px), header bar (`NowPlayingScreen`) wajib diberi offset padding atas (`StudioDesktopTitleBar.barHeight`) dengan platform guard `isDesktopPlatform`, agar tombol aksi tidak tertutup oleh tombol kontrol CSD window desktop, tanpa merusak layout Android mobile/tablet.
- **100% English Language Policy**: Seluruh teks antarmuka wajib dalam Bahasa Inggris.

### 2.7 Aturan Performa CustomPainter & Visualizer
- **`RepaintBoundary`**: Semua canvas interaktif (`WaveformSeekbar`, `ProQCanvas`, `RtaVisualizerCanvas`) wajib dibungkus dalam `RepaintBoundary`.
- **Zero Allocations inside `paint()`**: Dilarang mengalokasikan objek `Paint`, `Path`, atau `TextStyle` baru di dalam loop `paint()`. Cache objek sebagai field class.

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

### 3.4 Aturan Pengujian Otomatis & Test Files Mandate
- **Mandatory Test Files**: Setiap penambahan fitur baru, perbaikan bug (*bugfix*), refaktorisasi UI/UX, dan state controller **wajib** disertai file pengujian (`test/..._test.dart`).
- **Regression Protection**: Setiap bug yang ditemukan pengguna harus memiliki test case spesifik yang memvalidasi bahwa bug tersebut telah teratasi dan tidak akan kambuh (*zero regression*).
- **Automated Verification**: Setiap selesai melakukan perubahan kode, wajib menjalankan `flutter test` dan `flutter analyze` dengan target 100% kelulusan (0 errors, 0 warnings).

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

## 7. Mandat Khusus DSP Audio Engine: Adopsi Penuh Logika RYNLABS_HIFI

### 7.1 Single Source of Truth (`VirtualDspService`)
- Seluruh kontrol filter SoLoud C++ native WAJIB dikonsolidasikan ke dalam satu servis tunggal (`VirtualDspService`) yang mengelola status aktivasi, kalkulasi transfer function, dan pembaruan parameter pada master bus.
- Dilarang keras memecah aktivasi filter SoLoud ke dalam controller UI independen tanpa sinkronisasi terpusat.

### 7.2 Parameter Unit Scaling Presisi (Anti-Distorsi)
- **Kompresor & Limiter**: Parameter waktu `attackTime` dan `releaseTime` WAJIB dikalikan `1000.0` ke satuan milidetik (`attackTime.value = compAttack * 1000.0`), bukan detik mentah.
- **Output Ceiling Limiter**: Parameter `outputCeiling` pada brickwall limiter WAJIB dikunci pada `-1.3 dBFS` untuk melindungi sinyal audio dari inter-sample peak distortion.
- **Auto-Headroom Safe Preamp**: Atenuasi pre-amp dihitung secara dinamis dari nilai penguatan positif puncak kurva EQ:
  $$\text{Preamp} = -\max(0, \max(\text{EQ Curve})) - 0.5\text{ dB}$$
  Dilarang mengalikan volume linier hingga > 1.0 pada `SoLoud.instance.setVolume()` karena akan langsung meng-overdrive mixer internal SoLoud.

### 7.3 Rantai Filter Deterministik (10 Modul Master Bus)
Urutan filter pada master audio bus wajib deterministik:
$$\text{Preamp Gain} \rightarrow \text{Parametric EQ} \rightarrow \text{Bass Boost} \rightarrow \text{Tube Exciter} \rightarrow \text{Compressor} \rightarrow \text{Stereo Widener} \rightarrow \text{Crossfeed} \rightarrow \text{Reverb} \rightarrow \text{Pitch Shift} \rightarrow \text{Limiter (-1.3 dBFS)}$$

---

## 8. Standar Fitur & Kustomisasi Namida Suite

### 8.1 Sistem Kustomisasi Visual, Parallax & Performa
- **Parallax 3D Motion**: Album art merespons gestur geser (*drag/scroll*) dengan transformasi matriks 3D yang halus.
- **Dynamic Backdrop Blur & Ambient Glow**: Blur terisolasi pada bottom sheets & capsule dock serta dynamic glow halus di sekeliling album art dari warna yang diekstrak secara otomatis.
- **Performance Mode Presets**: Menyediakan opsi `Studio HiFi (120fps)`, `Balanced (60fps)`, `Battery Saver`, dan `Custom`.
- **Artwork & Track Tile Gestures**: Handler interaktif untuk tap, double-tap, long-press, dan swipe actions pada item musik.

### 8.2 Smart Playlists & Dynamic Rules
- Generator playlist berbasis filter kondisi: Teks (`contains`, `regex`), Angka (`=`, `>`, `<`, `range`), Tanggal (`inLastNDays`), dan Boolean (`isFavorite`, `isHiRes`) dengan limit trek.

### 8.3 Physical Metadata Tagger
- Pembacaan dan penulisan tag fisik langsung ke berkas audio lokal (ID3v2, Vorbis Comments, MP4 Atoms) termasuk cover art.

### 8.4 East Asian Lyrics & Metadata Romanizer
- Transliterasi otomatis karakter Jepang (Romaji), Korea (Romaja), dan Mandarin (Pinyin) untuk lirik dan judul lagu.

---

## 9. Mandat Cross-Platform Architecture & Strict Platform Guards (Android & Linux Desktop)

### 9.1 Isolasi Fitur Platform (Zero Regression Guarantee)
- **Strict Platform Guards**: Seluruh pemanggilan native platform plugins atau OS-specific daemons (seperti `window_manager`, Linux D-Bus `mpris`, System Tray `tray_manager`, Android Scoped Storage, atau Android MediaNotification) WAJIB dilindungi dengan guard bersyarat `if (Platform.isLinux)`, `if (Platform.isAndroid)`, `if (Platform.isWindows)`, `if (Platform.isMacOS)`, atau abstract platform-interface service pattern.
- Dilarang keras mengeksekusi kode platform desktop di Android atau sebaliknya yang berpotensi memicu `MissingPluginException`, unhandled platform channel crashes, atau unexpected behavior.

### 9.2 Adaptive Layout Breakpoints & Platform-Aware Shell
- **Mobile/Phone Mode (`< 960px` atau Android Phone)**:
  - Antarmuka WAJIB mempertahankan 100% arsitektur mobile yang sudah terbukti: `NamidaExpandableMiniPlayer`, `FloatingRoundedDock`, gestur swipe expand/collapse, dan bottom sheet controls.
- **Tablet / Landscape Mode (`isLandscape && !isDesktopLayout`)**:
  - Antarmuka WAJIB mempertahankan arsitektur *Dual-Pane Workstation* (Fase 46).
- **Desktop Mode (`(Platform.isLinux || Platform.isWindows || Platform.isMacOS) && width >= 960px`)**:
  - Antarmuka mengaktifkan arsitektur *Desktop Studio Canvas*: Permanent Sidebar (`NavigationRail`), Main Content Stage, dan *Persistent Bottom Master Transport Deck*.
- Layout desktop DILARANG MERUSAK, menggantikan, atau mengubah tata letak mobile pada platform Android.

### 9.3 Input Device Ergonomics (Keyboard & Mouse vs Touch)
- Keyboard shortcuts (`Shortcuts` & `Actions`) hanya merespons penekanan tombol fisik dan tidak boleh menghalangi *touch interactions*, *virtual soft keyboard*, atau *gesture recognizers* pada perangkat layar sentuh Android.
- Drag-and-drop desktop (`desktop_drop`) hanya aktif pada event mouse drag dari OS file manager dan tidak boleh menginterupsi *touch scroll list view* di Android.

---

## 10. Ringkasan Eksekusi
Aturan di atas berlaku untuk seluruh penulisan kode pada project **Baydev HiFi**. Setiap penambahan atau pembaruan modul wajib mematuhi pemisahan layer, penamaan konsisten, presisi matematika DSP RYNLABS_HIFI, standar antarmuka Material 3 Expressive, dan isolasi ketat antar-platform.

---

## 11. Mandat Rekayasa Always-On: Integrasi Ponytail & RTK (Rust Token Killer)

### 11.1 Ponytail — Lazy Senior Dev Mode Mandate
- **The Best Code is Code Never Written**: Selesaikan setiap tugas dengan perubahan terkecil yang tuntas (*smallest complete change*).
- **Anti-Over-Engineering**: Jangan menambahkan abstraksi, wrapper, boilerplates, atau fitur spekulatif yang tidak diminta.
- **Tuntas & Bertanggung Jawab**: Bersikap hemat pada solusi, bukan pada kualitas eksekusi. Perubahan wajib menyelesaikan seluruh caller, unit/widget tests, dan fixtures yang terdampak.
- **Root Cause Single-Point Fix**: Untuk perbaikan bug, telusuri semua pemanggil fungsi terlebih dahulu via grep, lalu perbaiki akar masalah sekali di kode bersama.
- **Reporting Clarity**: Akhiri balasan dengan ringkasan apa yang dilewati/ditunda beserta risiko teknis yang perlu diketahui pengguna.

### 11.2 RTK — Token Optimization & Code Simplification Mandate
- **Efisiensi Token Terminal**: Hindari dump log/output yang masif pada perintah CLI. Gunakan paginasi (`-n <N>`) dan path spesifik.
- **Kode Idiomatik & Bersih**: Gunakan functional chains bawaan bahasa, early returns (`guard clauses`), dan minimalkan alokasi memori yang redundan.
- **Zero Regression**: Pertahankan error handling yang kuat dan verifikasi selalu dengan unit/widget tests yang deterministik (`flutter test` dan `flutter analyze`).

### 11.3 Aturan Eksekusi Pengujian & Quality Gate (Anti-Parallel / Sequential Only)
- **Targeted Test First**: Saat pengembangan dan perbaikan bug/fitur, utamakan menjalankan file tes spesifik (`flutter test test/specific_test.dart`) untuk menghemat resource dan waktu eksekusi.
- **Dilarang Menjalankan Pengujian Global Bersamaan**:
  - Jika menjalankan `flutter test` tanpa menentukan berkas spesifik (menjalankan seluruh test suite), DILARANG KERAS menjalankan `flutter test` lain atau `flutter analyze` secara paralel/bersamaan.
  - Pengujian suite global memakan konsumsi CPU, memori, dan I/O disk yang sangat berat. Menjalankan beberapa proses secara bersamaan dapat membekukan perangkat atau menyebabkan *high resource thrashing*.
  - **Wajib Tunggu Selesai**: Selalu tunggu proses `flutter test` atau `flutter analyze` selesai sepenuhnya (*100% finished*) sebelum memulai perintah analisis atau pengujian berikutnya. Seluruh pemeriksaan kualitas harus dieksekusi secara serial / sekuensial satu per satu.




