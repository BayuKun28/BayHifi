# Baydev HiFi — Engineering & Design Rules (rules.md)

Aturan resmi arsitektur perangkat lunak, standar koding fungsi, pedoman antarmuka **100% Pure Material 3 Expressive** (`material_3_expressive: ^1.1.3`), dan struktur folder profesional untuk pengembangan pemutar musik audiophile **Baydev HiFi**.

---

## 1. Visi & Filosofi Rekayasa
1. **Audiophile First**: Akurasi suara (*bit-perfect*), zero latency jitter, dan perlindungan clipping digital (*safe headroom pre-amp*) adalah prioritas mutlak.
2. **60/120 FPS Fluidity**: Antarmuka visualizer spektrum, kurva Pro-Q, dan animasi tidak boleh menghambat pemutaran audio maupun mengalami frame drop.
3. **Clean & Modular**: Setiap fitur (*Feature-First*) harus independen, dapat diuji secara terisolasi, dan mudah dipelihara.
4. **Deterministic Audio Math**: Seluruh perhitungan matematika DSP (Biquad, FFT, SPL, AutoEQ) harus berupa fungsi murni (*pure functions*).
5. **Pure Material 3 Expressive Architecture**: Seluruh elemen antarmuka grafis (UI), layout bento, dialog, kontrol geser, tombol aksi, dan navigasi WAJIB 100% menggunakan ekosistem library resmi `material_3_expressive` (`material_ui`, `motor`, `material_new_shapes`).

---

## 2. Pedoman Desain Antarmuka (100% Pure Material 3 Expressive & Namida Architecture)

### 2.0 Mandat 100% Library `material_3_expressive` (Strictly Enforced)
Aplikasi Baydev HiFi secara arsitektural dibangun di atas fondasi **`material_3_expressive`** (`version: ^1.1.3`).
- **DILARANG KERAS** menggunakan widget Material 1/2 legacy atau widget standar `flutter/material.dart` jika padanan komponen resminya tersedia di dalam `material_3_expressive`.
- **Daftar Komponen Resmi & Pemetaan Wajib (`M3E*`)**:
  - **Aplikasi & Tema**: `M3EMaterialApp`, `M3ETheme`, `M3EThemeData`, `M3EColorStyles`, `M3EDimensions`.
  - **Tombol & Aksi (Buttons & Actions)**:
    - `M3EButton` (Filled, Tonal, Outlined, Elevated, Text).
    - `M3EIconButton` (Standard, Filled, Tonal, Outlined).
    - `M3EFab` & `M3EExtendedFab` (Floating Action Buttons).
    - `M3EFabMenu` (Speed dial / floating action menu).
    - `M3EButtonGroup` (Connected / grouped action buttons).
    - `M3ESegmentedButton` (Single & multi-selection segmented pills).
    - `M3ESplitButton` (Primary action + dropdown menu split).
  - **Kontrol Input & Seleksi (Selection & Inputs)**:
    - `M3ESwitch` (Expressive toggle switches dengan icon and state animation).
    - `M3ECheckbox` (Expressive rounded squircle checkboxes).
    - `M3ERadio` (Expressive radio selection pills).
    - `M3EChip` (Filter, Assist, Input, and Suggestion chips).
    - `M3ESlider` (Continuous, discrete, and expressive Wavy slider untuk seekbar audio & DSP parameter).
    - `M3ETextField` (Expressive text input fields).
    - `M3EDropdown` (Expressive dropdown selector).
  - **Kontainer, Permukaan & Layout (Containment & Surfaces)**:
    - `M3ECard` (Elevated, Filled, Outlined Bento Grid cards).
    - `M3ECarousel` (Multi-browse, hero, and uncontained carousels).
    - `M3EListTile` (Expressive list items dengan leading avatar, badges, and trailing action).
    - `M3EDivider` (Tonal studio dividers).
    - `M3EShapeContainer` (Container dengan expressive morphing shapes via `material_new_shapes`).
    - `M3EDialog` (Expressive modal, alert, confirmation, and full-screen dialogs).
    - `M3EBottomSheet` (Expressive modal & persistent bottom sheets dengan spring drag physics).
  - **Navigasi & App Bar (Navigation & Bars)**:
    - `M3EAppBar` (Pinned, scrolling, and large expressive app bars).
    - `M3ESearchBar` & `M3ESearchAnchor` (Expressive search view with expandable anchor).
    - `M3ENavigationBar` (Bottom navigation capsule bar with animated spring pill indicators).
    - `M3ENavigationRail` (Side navigation for landscape & desktop docking).
    - `M3EToolbar` (Floating / docked action toolbars).
    - `M3ETabBar` & `M3ETab` (Expressive tabs with fluid spring indicator).
    - `M3EMenu` & `M3EMenuItem` (Contextual popups and action sheets).
  - **Umpan Balik & Indikator (Feedback & Indicators)**:
    - `M3EBadge` (Hi-Res specs, bit-depth, format, count badges).
    - `M3EProgressIndicator` (Linear & circular expressive progress bars).
    - `M3ELoadingIndicator` (Indeterminate expressive loaders).
    - `M3ESnackbar` (Expressive snackbars with haptic feedback).
    - `M3ETooltip` (Expressive hover/long-press tooltips).
  - **Fisika Gerak & Haptik (Motion, Physics & Haptics)**:
    - Seluruh transisi, animasi lembar modal, gesture dragging, dan spring physics WAJIB menggunakan engine pegas **`motor`** (`SpringDescription`, expressive motion curves) bawaan `material_3_expressive`.
    - Respon sentuhan taktil WAJIB memanfaatkan **`M3EHaptics`** (`selectionClick()`, `lightImpact()`, `mediumImpact()`).

### 2.1 Sistem Warna & Theming (M3EThemeData & Studio Palette Engine)
- **Theme Modes (Dark / Light / System)**:
  - `ThemeMode.dark`: Studio Dark Obsidian (`#0D0F14`) atau *True OLED Black* (`#000000`).
  - `ThemeMode.light`: Clean Studio Light / Champagne (`#F5F7FA`) dengan kontras teks tinggi.
  - `ThemeMode.system`: Mengikuti preferensi tema perangkat (OS) secara otomatis.
- **M3E Dynamic Palette & Custom Colors**:
  - UI secara dinamis mengekstrak palet warna dari Album Art lagu aktif menggunakan `palette_generator` yang diselaraskan secara halus dan proporsional ke dalam `M3EThemeData`.
  - Pilihan preset palet audio studio terkurasi (Non-Neon & Restrained Studio Tones):
    - *Obsidian Cyan* (Refined Sky Studio `#38BDF8` / `#0284C7`)
    - *Amber Tube Glow* (Warm Analog Tube `#F59E0B` / `#D97706`)
    - *Emerald HiFi* (Studio Precision Mint `#10B981` / `#059669`)
    - *Electric Purple* (Studio Violet `#A855F7` / `#7C3AED`)
    - *Crimson Passion* (Mastering Rose Crimson `#F43F5E` / `#E11D48`)
    - *True OLED Black* (0% battery consumption AMOLED with `#38BDF8` precision accent)
  - Pengguna bebas memilih Accent Color custom (HEX / Swatch) untuk slider, indikator node, dan kurva glow.
- **Surface Elevation**: Gunakan tonal elevation Material 3 Expressive (`#161920`, `#1C202A`, `#242A38`), jangan gunakan drop shadow kasar.
- **Zero-Neon & Restrained Palette Policy (Strictly Enforced)**:
  - DILARANG KERAS menggunakan warna neon menyala atau saturasi berlebihan yang menyilaukan mata (seperti neon green `#00FF00`, neon cyan `#00F0FF`, atau garish blinding neons).
  - Seluruh warna kurva EQ, grafis RTA, kartu bento `M3ECard`, status badge `M3EBadge`, dan tombol aksi `M3EButton` wajib menggunakan warna studio terkalibrasi, berkelas, dan nyaman di mata dalam sesi mendengarkan yang panjang.
  - `EQ Curve`: Amber Warmth (`#F59E0B`) dengan soft subtle glow.
  - `Driver FR`: Muted Sky Blue (`#38BDF8`).
  - `Target FR`: Soft Mint Emerald (`#10B981`).
  - `Active Selection`: Studio Violet (`#A855F7`) atau Precision Mint (`#10B981`).
  - `Danger / Peak Clipping`: Soft Studio Red (`#F43F5E`).
- **Solid Surfaces & Minimal Restrained Gradients Policy (Strictly Enforced)**:
  - DILARANG KERAS menggunakan warna gradasi dekoratif/berlebihan pada komponen UI seperti cards, container bento, hero banners, list tiles, dialog, panel, atau settings overview.
  - Semua komponen UI wajib menggunakan warna **solid** murni yang bersumber langsung dari `M3EThemeData` dan `AppPalette` aktif (`theme.colorScheme.surface`, `surfaceContainer`, `surfaceContainerHighest`, `surfaceContainerLow`).
  - Penggunaan gradien HANYA diperbolehkan jika ultra-minimal dan murni fungsional, yaitu:
    1. Area fill di bawah kurva DSP / RTA spectrum analyzer (fade dari warna aksen ke transparan untuk visualisasi pembacaan data frekuensi).
    2. ShaderMask edge fade pada synchronized lyrics / list edge (agar teks memudar halus di batas atas/bawah layar).
    3. Sheen refleksi minimal pada vinyl disc animation.
    Di luar ketiga kebutuhan fungsional tersebut, seluruh kartu bento, overview, dan banner WAJIB menggunakan latar belakang warna solid dengan 1px crisp outline border.

### 2.2 Bentuk (Shapes), Morphing & Tipografi
- **Expressive Shapes & Morphing (`material_new_shapes`)**:
  - Gunakan shape tokens resmi Material 3 Expressive dan `M3EShapeContainer`:
    - Mini Buttons & Pills: `M3EDimensions` / `BorderRadius.circular(8)` s/d `(12)`.
    - Cards & Audio Nodes (`M3ECard`): `BorderRadius.circular(16)`.
    - Album Art Container: Pilihan corner radius dinamis (`0px`, `16px`, `28px`).
    - Bottom Sheets & Modals (`M3EBottomSheet`): `BorderRadius.vertical(top: Radius.circular(28))`.
- **Tipografi**: Gunakan font modern (misal: Inter / Roboto / JetBrains Mono untuk angka audio):
  - Semua angka frekuensi (`Hz`), gain (`dB`), Q-factor, dan audio badge (`24-bit / 192 kHz`) **wajib** menggunakan *tabular figures* (`FontFeature.tabularFigures()`) agar angka tidak bergetar saat nilainya berubah.

### 2.3 Aturan Performa CustomPainter & Visualizer
- **`RepaintBoundary`**: Semua canvas interaktif (`ProQCanvas`, `RtaVisualizerCanvas`, `WaveformCanvas`) **wajib** dibungkus dalam `RepaintBoundary` agar tidak memicu repaint pada keseluruhan widget tree.
- **Zero Allocations inside `paint()`**:
  - Dilarang membuat instance baru `Paint()`, `Path()`, atau `TextStyle()` di dalam method `paint()`.
  - Objek `Paint` harus di-cache sebagai field class dan hanya nilai warna/properti yang diperbarui.
- **Logarithmic Math Caching**: Nilai mapping koordinat piksel ke frekuensi logaritmik ($20\text{ Hz} \leftrightarrow 20,000\text{ Hz}$) harus diprekomputasi atau menggunakan lookup table saat resize canvas.

---

### 2.4 Arsitektur MiniPlayer & Navigasi (M3E Expandable Player & Dock)
- **Tanpa Tab Khusus Player**:
  - Layar pemutar musik utama (*Now Playing*) **tidak** menggunakan tab mandiri di Bottom Navigation Bar.
  - Tab utama aplikasi Baydev HiFi terdiri dari 4 tab yang dikelola via `M3ENavigationBar`:
    1. **Dashboard** (Index 0): Status engine SoLoud, DAC indicator, launcher Pro-Q, statistik library.
    2. **DSP Rack** (Index 1): 10+ modul mastering (Tube Exciter, Compressor, Crossfeed, Limiter).
    3. **Library** (Index 2): Pustaka terpadu offline lokal dan cloud Navidrome.
    4. **Settings** (Index 3): Kustomisasi tema, custom palette, dark/light/system, visualizer, dan DAC.
- **Omnipresent Expandable MiniPlayer**:
  - MiniPlayer selalu melayang (*docked*) tepat di atas `M3ENavigationBar` (atau di bagian bawah layar saat navigasi tersembunyi).
  - Menampilkan thumbnail album art (`M3EShapeContainer`), judul lagu bergeser halus (*marquee* jika panjang), nama artist, tombol `M3EIconButton` Play/Pause & Next, dan progress bar tipis `M3EProgressIndicator` (2.5px) di bagian bawah.
  - **Fluid Gestures & Motor Spring Physics**:
    - Ketukan (*tap*) atau gesekan ke atas (*swipe up*) membuka layar **NowPlayingScreen** secara penuh dengan transisi `M3EBottomSheet` berbasis fisika pegas `motor`.
    - Gesekan ke bawah (*swipe down*) atau tombol chevron collapse mengembalikan player ke bentuk MiniPlayer tanpa menghentikan pemutaran audio.

---

### 2.5 Standar Ikonografi Modern (`hugeicons`), Floating Dock & Anti-AI-Slop UI
- **Zero-Emoji Policy (Strictly Enforced)**:
  - DILARANG KERAS menggunakan emoji di seluruh komponen UI (widget, button label, title dialog, badge, snackbar, status text), kode sumber, komentar kode, maupun dokumentasi.
  - Seluruh visualisasi simbolis WAJIB menggunakan library ikon resmi (`hugeicons` via `HugeIcons.strokeRounded...` atau `HugeIcons.solidRounded...`).
- **Mandatory Icon Package (`hugeicons`)**:
  - Seluruh ikon di dalam aplikasi **wajib** menggunakan `HugeIcons` (stroke rounded style `HugeIcons.strokeRounded...` atau solid `HugeIcons.solidRounded...`).
  - **Dilarang keras** mencampur ikon generic Material 1/2 (`Icons.xxx`).
- **Floating Rounded Dock (`M3ENavigationBar` / `M3EToolbar`)**:
  - Bottom navigation bar diimplementasikan sebagai **Floating Capsule Dock** (`borderRadius: BorderRadius.circular(26)`), melayang di atas safe area dengan elevasi halus, batas border 1px, dan indikator pill aktif beranimasi `motor`.
- **Anti-AI-Slop UI Philosophy**:
  - Pertahankan *high information density* ala studio hardware (FabFilter, Universal Audio, Namida).
  - Gunakan *tabular figures* (`FontFeature.tabularFigures()`) pada semua display angka audio (frekuensi, gain, durasi, bitrate, preamp).
  - Hindari efek *frosted glass* buram berlebihan yang merusak keterbacaan teks.
  - Hindari penumpukan gradien neon secara acak tanpa konteks fungsional audio.

### 2.6 Konsistensi Desain Antarmuka & Referensi UI Fidelity
- **Kepatuhan Desain Referensi**:
  - Setiap penambahan screen, modal, bottom sheet, atau komponen baru **wajib konsisten** dengan desain yang telah ada (`collection_dark`, `collection_light`, `customization_settings`, `yt_miniplayer`, `pro_q_studio`).
  - Gunakan komponen dasar yang seragam: squircle rounded borders (`8px`, `12px`, `16px`, `24px`), dark studio surface containers `M3ECard`, 1px crisp outline border (`Border.all(color: theme.dividerColor, width: 1.0)`).
  - **100% English Language Policy**: Seluruh teks antarmuka pengguna (title, label, button, tooltip, snackbar, modal dialog) wajib menggunakan Bahasa Inggris formal.
  - **Tactile Micro-interactions**: Berikan haptic feedback halus (`M3EHaptics.selectionClick()`) dan transisi animasi halus (150-250ms) pada interaksi tombol, reordering, dan switching.

### 2.7 Standar Arsitektur Pure Material 3 Expressive & Pure Theme Palettes System
- **Pure Material 3 Expressive Semi-Minimalist Aesthetics**:
  - Terapkan tata letak antarmuka yang bersih, elegan, dan **semi-minimalist** (tidak terlalu ramai/padat/cluttered).
  - Berikan *breathing room* yang proporsional, struktur kartu `M3ECard` yang fokus dan lapang, serta hindari penumpukan badge dekoratif yang tidak esensial.
  - Standar squircle tokens:
    - `XS: 8px` (`M3EChip`, mini tags, status dots)
    - `S: 12px` (`M3EButton`, quick metric items)
    - `M: 16px` (Standard Bento `M3ECard`, dialogs `M3EDialog`, `M3ESlider`)
    - `L: 20px` (Feature cards, DSP tiles)
    - `XL: 28px` (Hero containers, album art, `M3EBottomSheet`)
    - `Pill: 999px` (Status badges `M3EBadge`, active pills, capsule docks)
  - 1px crisp studio borders (`Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 1.0)`) tanpa shadow buram berlebihan.
- **Strict Color Theming Palette Adherence (Zero Hardcoded Random Colors)**:
  - **DILARANG KERAS** menggunakan warna hardcoded arbitrer di luar palet tema aktif (seperti hardcoded `0xFFFF9F0A`, `0xFF00F0FF`, `0xFFBF5AF2`, dll pada komponen kartu dan teks).
  - Seluruh komponen antarmuka, kartu `M3ECard`, kurva visual, teks, border, dan icon **WAJIB** mengambil nilai warna dari `M3EThemeData` / `Theme.of(context).colorScheme` dan `AppPalette` aktif:
    - `colorScheme.primary`: Aksen utama kartu aktif, kurva EQ, highlight, dan indikator status.
    - `colorScheme.secondary`: Aksen sekunder dan badge pelengkap.
    - `colorScheme.tertiary`: Aksen tersier / target curve.
    - `colorScheme.surface`: Latar belakang kontainer dasar.
    - `colorScheme.surfaceContainer`: Kontainer elevasi sedang.
    - `colorScheme.outline`: Warna garis border 1px yang bersih.
    - `colorScheme.onSurface` & `colorScheme.onSurfaceVariant`: Tipografi judul dan teks sekunder.
  - Komponen harus beradaptasi secara otomatis 100% harmonis saat pengguna berganti palet warna di Pengaturan (*Obsidian Cyan*, *Amber Tube Glow*, *Emerald HiFi*, *Electric Purple*, *Crimson Passion*, *True OLED Black*, *Champagne Light*).
- **Expressive Motion & Motor Spring Physics**:
  - Gunakan kurva gerak pegas ekspresif dari package `motor` (`SpringDescription`, `Curves.easeOutBack`, `Curves.fastEaseInToSlowEase`, `Curves.easeOutCubic`).
  - Manfaatkan `flutter_animate` untuk *staggered entrance animations* (fade & slide-in dengan delay bertahap 40-60ms per tile).
  - Berikan haptic micro-feedback (`M3EHaptics.lightImpact()` atau `M3EHaptics.selectionClick()`) pada setiap interaksi pengguna.
- **High Information Density & Tabular Figures**:
  - Tampilkan data audio secara bersih dan presisi (sample rate, buffer latency, bit depth, total listening hours, format).
  - Wajib menerapkan `FontFeature.tabularFigures()` pada semua angka numerik dinamis agar tampilan tidak jittering saat data ter-refresh.

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

## 9. Ringkasan Eksekusi
Aturan di atas berlaku untuk seluruh penulisan kode pada project **Baydev HiFi**. Setiap penambahan atau pembaruan modul wajib mematuhi pemisahan layer, penamaan konsisten, presisi matematika DSP RYNLABS_HIFI, dan standar antarmuka Material 3 Expressive.


