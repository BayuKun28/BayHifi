# Baydev HiFi — Master Task Tracker (task.md)

Dokumen pelacakan tugas mendalam untuk pengembangan pemutar musik audiophile **Baydev HiFi**. Setiap tugas dirancang secara modular, mengacu pada arsitektur DSP studio presisi tinggi serta referensi UI/UX Expressive modern (Icon, Layout, Multi-tab Collection, Expandable MiniPlayer, Customization Settings).

---

## Status Dashboard
- **Total Fase**: 28 Fase (Phase 1-28 Completed — 100% Done)
- **Arsitektur UI**: *Material 3 Expressive Studio UI, Bento Grid Modular System, Floating Rounded Dock, Unified HugeIcons & Anti-AI-Slop Restrained Aesthetics (100% English)*
- **Status Proyek**: *Phase 28 (YouTube Music Streaming, Opus 160kbps Extraction, C++ SoLoud DSP Chain Mastering, YouTube Discovery Bento Hub, Playlist Importer, Smart Radio & Offline Cache) Completed — 236/236 Tests Passing (100%), 0 Analyzer Warnings*

---

## Fase 13: DSP Rack Collapsible Units, Bottom Floating Category Dock, Pastel Palettes & Expressive Controls
Penyempurnaan ergonomi satu tangan dan visual Material 3 Expressive studio di seluruh antarmuka utama Baydev HiFi.

- [x] **13.1 DSP Rack Collapsible Units & Reset Confirmation Modal**
  - [x] `RackUnitCard` collapsible state: otomatis terminimize saat bypass (OFF) ke faceplate ramping ~46px, auto-expand saat dinyalakan, dan tap header untuk expand manual dengan indikator chevron.
  - [x] Modal dialog konfirmasi Material 3 untuk aksi *Reset to Flat Reference* dengan tombol Cancel dan Reset All.
- [x] **13.2 Library Bottom Floating Category Dock**
  - [x] Mengganti static top horizontal category bar dengan ergonomic bottom floating action pill di atas miniplayer.
  - [x] Secondary floating category dock animasi halus yang menampilkan opsi Tracks, Albums, Artists, Genres, Folders, dan Playlists.
- [x] **13.3 Curated Pastel Studio Color Palettes & Accent Options**
  - [x] Menambahkan 6 preset palet pastel studio non-neon di `AppPalette` (`Pastel Lavender`, `Pastel Sage Mint`, `Pastel Powder Sky`, `Pastel Soft Peach`, `Pastel Blush Rose`, `Pastel Butter Cream`).
  - [x] Menambahkan swatches warna aksen pastel pada menu Theming Settings.
- [x] **13.4 Material 3 Expressive Playback Controls di NowPlayingScreen**
  - [x] Upgrade Previous, Next, Shuffle, Repeat, dan Play/Pause ke kontainer squircle geometris Material 3 Expressive dengan border crisp 1px selaras dengan mode Desk/Car Docking.
- [x] **13.5 Dedicated Widget & Unit Tests Validation**
  - [x] Menambahkan `m3_expressive_enhancements_test.dart` dan memastikan 100% passing tests (73 tests total) dengan 0 warnings dan 0 errors di `flutter analyze`.

---

## Fase 12: Material 3 Expressive UI/UX Architecture & Bento Grid System
Implementasi arsitektur antarmuka Material 3 Expressive modern dengan sistem Bento Grid modular, token squircle, elevasi tonal 5-layer, physics spring, dan animasi staggered entrance.

- [x] **12.1 Standardisasi Aturan Material 3 Expressive & Zero-Emoji Policy di `rules.md` & `GEMINI.md`**
  - [x] Tambahkan section arsitektur M3 Expressive, Bento Grid layout, token squircle (`8px`, `12px`, `16px`, `20px`, `28px`, `999px`), 1px crisp borders, Zero-Emoji Policy, dan tabular figures policy.
- [x] **12.2 Bento Module 1: C++ SoLoud Engine & Hardware Telemetry Hero Card**
  - [x] Live C++ audio engine telemetry, source specs (kHz, bit depth, format), safe preamp level, and Bit-Perfect DAC status badge.
- [x] **12.3 Studio Hero Showcase Carousel (Horizontal Showcase)**
  - [x] Horizontal M3 Expressive showcase banner directly above Audiophile Stats card with 4 rich cards (*32-Band Pro-Q Studio*, *Mastering DSP Rack*, *AutoEQ & Target Solver*, *Studio Desk Docking*), page indicator dots, and direct navigation.
- [x] **12.4 Semi-Minimalist Dashboard Streamlining**
  - [x] Removed redundant Pro-Q and DSP Rack mini cards and top header quick chips to produce an uncrowded, semi-minimalist Material 3 Expressive studio layout.
- [x] **12.5 Bento Module 2: Audiophile Listening Statistics Card**
  - [x] High-density telemetry for listening time, lossless FLAC vs Standard distribution, and favorite tracks.
- [x] **12.6 Bento Module 3: Recent Lossless Sessions Bento Carousel**
  - [x] Horizontal Bento carousel for recently played/discovered lossless tracks with squircle artwork, format badges (Hi-Res / FLAC), and 1-tap play.
- [x] **12.7 Pure Theme Palette System Compliance (Zero Hardcoded Random Colors)**
  - [x] 100% compliance across all dashboard bento widgets with `theme.colorScheme` tokens (`primary`, `secondary`, `tertiary`, `surface`, `surfaceContainer`, `outline`, `onSurface`, `onSurfaceVariant`).
- [x] **12.8 Unit & Widget Test Suite Validation**
  - [x] 100% test coverage with passing tests and 0 analyzer warnings across the entire repository.
- [x] **12.9 Flush Carousel Alignment, Header Minimalist Clean-up & Dynamic Album Art Palette**
  - [x] Fixed `StudioHeroShowcaseCarousel` left-edge alignment with `viewportFraction: 1.0` and 0 horizontal insets, aligning flush with Bento cards.
  - [x] Removed `'Studio Command & Telemetry'` subtitle text for a minimalist studio header.
  - [x] Integrated automatic dynamic album art palette extraction via `palette_generator` with `Track.albumArtBytes` / `Track.albumArtUrl`.
  - [x] Mandated Zero-Neon & Restrained Studio Palette standard in `rules.md` and `GEMINI.md` and refactored all theme presets and accent swatches to elegant studio tones.

---

## Fase 11: Pure Custom Local Library & Storage Directory Management
Pembersihan seluruh data demo/sampling audio bawaan dan integrasi pemilihan direktori & file fisik lokal dengan database persisten.

- [x] **11.1 Penghapusan Seluruh Dummy / Sampling Track Bawaan**
  - [x] `LocalAudioScanner.defaultLocalTracks` dikembalikan kosong (`const []`)
  - [x] Inisialisasi library murni membaca data hasil scan direktori pengguna yang tersimpan di `LocalPersistenceService`
- [x] **11.2 Pemilih Direktori & File Audio Lokal Kustom**
  - [x] Implementasi `pickAndScanDirectory()` dengan `FilePicker.getDirectoryPath()` dan pemindaian rekursif seluruh format audiophile (`.flac`, `.wav`, `.mp3`, `.opus`, `.ogg`, `.alac`, `.dsf`, `.dff`, `.m4a`, `.aac`)
  - [x] Implementasi `pickAudioFiles()` untuk pemilihan file spesifik
  - [x] Ekstraksi cerdas format bitrate/sample rate, penamaan album dari folder induk, dan parsing judul "Artist - Title"
- [x] **11.3 Database Persisten Koleksi Lagu & Folder Pengguna**
  - [x] Penyimpanan otomatis track dan daftar direktori ke file JSON storage di dokumen aplikasi
  - [x] Fitur `rescanSavedFolders()` untuk sinkronisasi ulang seluruh folder musik tersimpan
  - [x] Fitur `clearLibrary()` dengan dialog konfirmasi untuk membersihkan katalog library
- [x] **11.4 Studio Empty State & Quick Actions**
  - [x] Desain empty state studio high-fidelity saat library kosong dengan tombol aksi langsung: `[SELECT MUSIC FOLDER]`, `[PICK AUDIO FILES]`, dan `[CONNECT NAVIDROME CLOUD]`
  - [x] Popup menu AppBar lengkap di `UnifiedLibraryScreen`: *Pick & Scan Music Folder*, *Pick Audio Files*, *Rescan Music Folders*, *Connect Navidrome Cloud*, *Clear Music Library*

---

## Fase 1: Setup Foundation & Audio Engine Core

Fondasi aplikasi, integrasi low-level engine SoLoud C++, pemutaran audio dasar, dan ekstraksi data spektrum real-time.

- [x] **1.1 Inisialisasi Project Flutter**
  - [x] Buat project Flutter dengan `flutter create --platforms=linux,windows,macos,android baydev_hifi`
  - [x] Konfigurasi `rules.md` dan struktur folder Feature-First sesuai arsitektur
  - [x] Setup Git repository dan ignore files
- [x] **1.2 Setup Dependencies & Audio Libraries**
  - [x] Tambahkan `flutter_soloud` dari folder lokal (`path: ../flutter_soloud`) ke `pubspec.yaml`
  - [x] Tambahkan `flutter_riverpod` untuk state management
  - [x] Tambahkan `palette_generator` untuk ekstraksi warna dinamis
  - [x] Tambahkan `dio` untuk HTTP networking
  - [x] Tambahkan `audiotags` / metadata parser
- [x] **1.3 Audio Controller & State Management**
  - [x] Buat singleton / provider `AudioEngineController` membungkus SoLoud
  - [x] Implementasikan fungsi dasar: `init()`, `play(path)`, `pause()`, `resume()`, `seek()`, `setVolume()`
  - [x] Buat state provider reaktif: `PlaybackStatus` (idle, loading, playing, paused, stopped, error)
  - [x] Implementasikan tracking posisi dan durasi lagu secara presisi (ms)
- [x] **1.4 Dukungan Codec & Pengujian Format Hi-Res**
  - [x] Deteksi format MP3, WAV Lossless, OGG, OPUS
  - [x] Deteksi & ekstraksi streaminfo FLAC Hi-Res 24-bit / 96 kHz dan 192 kHz
  - [x] Magic bytes parser dan generator badge audiophile
  - [x] Penanganan graceful error jika format file rusak/tidak didukung
- [x] **1.5 Pipeline FFT Spectrum Analyzer (RTA Data Stream)**
  - [x] Konfigurasi ekstraksi data FFT (512 bins) dari SoLoud engine
  - [x] Implementasikan smoothing / decay algoritma agar visualizer tidak melompat kasar
  - [x] Buat stream provider audio spectrum data untuk konsumsi UI di 60fps
  - [x] Implementasikan `SpectrumVisualizer` dengan `RepaintBoundary` dan 0 allocations di `paint()`

---

## Fase 2: Pro-Q Studio & Canvas Interaktif
Implementasi antarmuka Parametric EQ studio presisi tinggi sesuai tangkapan layar referensi.

- [x] **2.1 Domain Model Parametric EQ**
  - [x] Buat model `EqBand` (id, frequency, gain, q, filterType, isEnabled, color)
  - [x] Buat enum `FilterType` (peaking, lowShelf, highShelf, lowPass, highPass, notch)
  - [x] Buat data class `BiquadCoefficients` ($b_0, b_1, b_2, a_1, a_2$)
- [x] **2.2 Matematika Filter Biquad & Transfer Function $H(f)$**
  - [x] Implementasikan perhitungan koefisien Audio EQ Cookbook untuk setiap tipe filter
  - [x] Implementasikan evaluasi respon frekuensi $|H(f)|$ pada rentang 20 Hz – 20,000 Hz
  - [x] Implementasikan kalkulasi kurva komposit (penjumlahan logaritmik seluruh band aktif)
- [x] **2.3 CustomPainter Logarithmic Grid (20 Hz – 20,000 Hz)**
  - [x] Buat grid sumbu frekuensi logaritmik dengan garis pandu (20, 60, 250, 500, 2k, 4k, 10k, 20k)
  - [x] Render 7 pembagian zona frekuensi di header:
    - `SUB BASS` (20-60 Hz), `MID BASS` (60-250 Hz), `LOWER MIDRANGE` (250-500 Hz), `UPPER MIDRANGE` (500-2kHz), `PRESENCE REGION` (2k-4kHz), `MID TREBLE` (4k-10kHz), `AIR` (10k-20kHz)
  - [x] Dual Y-axis: Kiri level sinyal (0 dBFS s/d -60 dBFS), Kanan filter gain (+24 dB s/d -24 dB)
- [x] **2.4 Interaksi Node Draggable & Kontrol Q-Factor**
  - [x] Render handle lingkaran bernomor (B1, B2, ..., B10+) dengan warna aksen neon
  - [x] Deteksi gesture drag: Geser horizontal mengubah Frekuensi, geser vertikal mengubah Gain
  - [x] Deteksi scroll mouse / gesture pinch dua jari untuk mengubah nilai **Q**
  - [x] Snap-to-zero dB dengan haptic/visual feedback lembut
- [x] **2.5 Shading Gradien Translusen Kurva EQ**
  - [x] Buat path lengkung spline halus kurva EQ aktif dengan warna amber bersinar
  - [x] Isi area antara kurva dan garis baseline 0 dB dengan gradien translusen hangat
- [x] **2.6 Bottom Control Strip (Band Pills & Action Buttons)**
  - [x] Tampilkan baris pill band yang dapat digeser secara horizontal (`B1: 63Hz -1.1dB`, dll)
  - [x] Tombol aksi: `[+] Add Band`, `[Trash] Delete Band`, `[Undo/Redo] Revert Band`
  - [x] Readout knop presisi: `FREQ (Hz)`, `GAIN (dB)`, `Q (factor)`
  - [x] Indikator Pre-amp Readout: `PRE: -4.3 dB`
- [x] **2.7 Auto-Headroom Safe Preamp Calculator**
  - [x] Hitung secara dinamis puncak penguatan positif tertinggi dari seluruh filter aktif
  - [x] Terapkan atenuasi pre-amp otomatis: $\text{Preamp} = -\max(0, \max(\text{EQ Curve})) - 0.5\text{ dB}$
  - [x] Lindungi output dari bahaya distorsi clipping digital
- [x] **2.8 Real-time RTA Spectrum Overlay**
  - [x] Tampilkan visualizer spectrum FFT di latar belakang kurva EQ
  - [x] Tombol toggle `[RTA]` untuk menyalakan/mematikan visualizer

---

## Fase 3: AutoEQ & Squiglink Import Engine
Modul kalkulasi pencocokan respons frekuensi IEM/headphone terhadap kurva target (Harman/HBB) dan impor format Squiglink.

- [x] **3.1 Parser Universal File Pengukuran Driver**
  - [x] Implementasikan parser REW V5 untuk membaca `KZ CASTOR BLACK DUDU R.txt`
  - [x] Ekstraksi titik data frekuensi ($f$) dan tingkat tekanan suara ($SPL$)
  - [x] Sanitasi data: Abaikan komentar header (`*` atau `#`) dan tangani delimiter whitespace/tab
- [x] **3.2 Parser Universal File Target Respon**
  - [x] Implementasikan parser Squiglink CSV untuk membaca `HBB Target.txt`
  - [x] Ekstraksi titik pasangan `Freq,SPL` dari file target
- [x] **3.3 Normalisasi 1 kHz & Kalkulator Selisih $\Delta SPL$**
  - [x] Sejajarkan kedua kurva pada frekuensi referensi $1,000\text{ Hz}$ ($SPL_{norm} = SPL - SPL_{1kHz}$)
  - [x] Hitung kurva deviasi: $\Delta SPL(f) = SPL_{\text{Target}}(f) - SPL_{\text{Driver}}(f)$
- [x] **3.4 AutoEQ Biquad Optimizer Solver**
  - [x] Algoritma deteksi titik resonansi puncak dan lembah pada $\Delta SPL(f)$
  - [x] Generator konfigurasi filter sesuai pilihan resolusi band: `5 B`, `10 B`, `16 B`, `20 B`, `32 B`
  - [x] Terapkan hasil optimasi langsung ke node Pro-Q Canvas dan filter engine
- [x] **3.5 Modal Dialog "Auto EQ Studio & Target Matching"**
  - [x] Dropdown seleksi Driver (misal: "KZ CASTOR BLACK DUDU R") + tombol Hapus
  - [x] Dropdown seleksi Target (misal: "HBB Target") + tombol Hapus
  - [x] Tombol aksi samping: `[IMPORT DRIVER]`, `[IMPORT TARGET]`, `[SQUIGLINK EQ]`
  - [x] Pilihan tombol Band Resolution (`5 B`, `10 B`, `16 B`, `20 B`, `32 B`)
  - [x] Pilihan Tuning Mode (`Normal` vs `Safe`)
  - [x] Tombol eksekusi utama: `[APPLY TO DSP]` (warna emerald menyala)
- [x] **3.6 Parser & Exporter Teks Squiglink EQ**
  - [x] Parsing format teks Squiglink (`Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414`)
  - [x] Ekspor konfigurasi EQ saat ini ke format teks Squiglink / Wavelet
- [x] **3.7 Fitur A/B Comparison Switch**
  - [x] Tombol instan beralih antara `[A: RAW]` (audio murni) dan `[B: ACTIVE]` (audio ber-tuning)
  - [x] Transisi crossfade halus (10ms) untuk mencegah bunyi *pop/click* saat switching

---

## Fase 4: Mastering DSP Studio Rack (10+ Modul)
Rantai pemrosesan audio kelas profesional untuk mastering dan personalisasi karakter suara.

- [x] **4.1 Pre-Amp Gain Stage**
  - [x] Slider headroom input (-24 dB s/d +12 dB) dengan visualizer level meter
- [x] **4.2 Dynamic Bass Boost**
  - [x] Peningkatan frekuensi sub-bass (40–160 Hz) dengan harmonik psychoacoustic
- [x] **4.3 Tube Exciter / Triode Saturation**
  - [x] Algoritma nonlinearitas analog ($y = \tanh(k \cdot x)$) untuk distorsi harmonik genap (*even harmonics*)
  - [x] Kontrol Drive/Warmth, Harmonics Blend, dan Tube Bias
- [x] **4.4 Dynamic Compressor**
  - [x] Implementasi parameter: Threshold (-60 s/d 0 dB), Ratio (1:1 s/d 20:1), Attack (0.1–100ms), Release (10–1000ms), Makeup Gain
  - [x] Visualizer gain reduction (GR Meter)
- [x] **4.5 Stereo Width (Mid-Side Matrix)**
  - [x] Dekomposisi sinyal ke $M = (L+R)/2$ dan $S = (L-R)/2$
  - [x] Kontrol pelebaran soundstage (0% Mono s/d 200% Super-Wide)
- [x] **4.6 Binaural Crossfeed (Meier / Chu-Moy Algorithm)**
  - [x] Simulasi tata letak speaker stereo untuk headphone guna mengurangi kelelahan telinga (*listener fatigue*)
  - [x] Kontrol Cutoff Frequency (650 Hz) dan Crossfeed Level (-3 dB s/d -9 dB)
- [x] **4.7 Spatial Studio Reverb**
  - [x] Algoritma Freeverb stereo: Room Size, Damping, Width, Predelay, dan Decay Time
- [x] **4.8 Pitch Shifter Engine**
  - [x] Pengubah nada granular tanpa mengubah tempo: Semitones (-12 s/d +12) dan Fine Cents (-50 s/d +50)
- [x] **4.9 Peak Brickwall Limiter**
  - [x] Zero-overshoot lookahead limiter untuk memastikan sinyal tidak pernah melampaui 0 dBFS
- [x] **4.10 Master Wet/Dry Matrix & DSP Presets**
  - [x] Kontrol perbandingan sinyal terproses vs sinyal asli (0% – 100%)
  - [x] Manajemen preset DSP: Audiophile Pure, Warm Tube Acoustic, Deep Bass Impact, Spacious Cinema, Vocal Clarity

---

## Fase 5: UI/UX Studio Collection, Multi-Tab Navigation & Layout Rework
Penyesuaian tata letak (layout), icon, struktur menu, dan alur interaksi mengacu pada referensi *Expressive Music App Screen Designs* (`collection_dark`, `collection_light`, `customization_settings`, `yt_miniplayer`).

- [x] **5.1 Pembersihan & Penataan Terminologi UI**
  - [x] Hapus/ganti seluruh penyebutan kata eksternal di halaman Settings & Theming menjadi standar Studio Audiophile / Baydev HiFi
  - [x] Standardisasi nama palet warna: *Obsidian Cyan*, *Amber Tube Glow*, *Emerald HiFi*, *Electric Purple*, *Crimson Passion*, *True OLED Black*, *Champagne Light*
- [x] **5.2 Multi-Tab Collection Screen (Tracks, Albums, Artists, Genres, Playlists, Folders)**
  - [x] **Top Header & Action Bar**:
    - [x] Search Bar interaktif dengan live filtering
    - [x] Tombol Sort Dropdown (`Title`, `Date Added`, `Artist`, `Duration`, `File Size`, `Hi-Res`) + Ascending/Descending Toggle
    - [x] Multi-tab horizontal pills navigation: `[Tracks]`, `[Albums]`, `[Artists]`, `[Genres]`, `[Playlists]`, `[Folders]`
  - [x] **Tracks Tab View**:
    - [x] List view dengan squircle album art cover (rounded corners)
    - [x] Title, Artist, Album, Durasi & badge format audio (FLAC/Hi-Res/MP3)
    - [x] Trailing 3-dot popup menu: *Play Next*, *Add to Queue*, *Add to Playlist*, *Track Details*, *Favorite Heart*
  - [x] **Albums & Artists Grid View** (Sesuai `collection_dark_2` & `collection_light_2`):
    - [x] 2-column squircle grid card layout responsif
    - [x] Album card: Cover art besar, Album Name, Artist Name, Year, Jumlah Tracks
    - [x] Artist card: Circular / Squircle portrait avatar, Artist Name, Total Album & Tracks count
    - [x] Toggle switch tampilan: Grid View (2 kolom) vs List View (1 kolom)
  - [x] **Genres & Playlists Tab View**:
    - [x] Tampilan kategori Genre dengan badge pill dan hitungan lagu
    - [x] Manajemen Custom Playlists: Buat playlist baru, tambah lagu ke playlist
  - [x] **Folders Browser Tab View**:
    - [x] Navigasi folder direktori dengan hitungan file audio lagu
    - [x] Filter sumber lagu (Semua, Offline Local, Navidrome Cloud, Hi-Res)
- [x] **5.3 Floating MiniPlayer & Gestur Interaktif** (Sesuai `yt_miniplayer`)
  - [x] Squircle cover art dengan border halus
  - [x] Track title & subtitle dengan format badge
  - [x] Tombol Play/Pause dengan accent glow, tombol Next, dan tombol Favorite Heart
  - [x] Thin micro progress bar line di tepi bawah miniplayer
  - [x] Gestur fluida: Swipe-up atau tap untuk expand ke full player, swipe-down untuk collapse tanpa distorsi audio
- [x] **5.4 Full Now Playing Screen Layout & Quick Controls**
  - [x] Large Squircle Album Art dengan dynamic ambient color glow dari palette generator
  - [x] Top action row: Collapse Chevron, Hi-Res Gold Badge, Sync Lyrics toggle, Pro-Q Studio shortcut button
  - [x] Waveform / RTA Spectrum Bar responsive
  - [x] Timestamp seekbar presisi (elapsed & remaining time)
  - [x] Main playback deck: Shuffle, Previous, Play/Pause (neon glow ring), Next, Repeat (Off/All/One)
  - [x] Quick DSP Toggles strip di bawah player: `[Bypass DSP]`, `[Bass Boost]`, `[Tube Warmth]`, `[Crossfeed]`
- [x] **5.5 Synchronized Lyrics Player (LRC)**
  - [x] Parser file `.lrc` universal ([mm:ss.xx] timestamp)
  - [x] Layar Scrolling Lyrics real-time dengan baris aktif yang disorot neon glow dan auto-scroll mengikuti posisi lagu
  - [x] Tap-to-seek: Sentuh baris lirik tertentu untuk melompatkan pemutaran lagu langsung ke timestamp tersebut

---

## Fase 6: Advanced Customization Settings & Local Database Persistence
Implementasi kustomisasi mendalam sesuai `customization_settings` dan penyimpanan data lokal persisten.

- [x] **6.1 Unified Local Persistence (Database SQLite / SharedPreferences / Cache)**
  - [x] Penyimpanan persisten track metadata hasil scan (tidak perlu re-scan setiap kali app dibuka)
  - [x] Penyimpanan persisten Custom Playlists, History Pemutaran, dan Favorite Tracks
  - [x] Penyimpanan persisten konfigurasi DSP Master Rack dan Custom EQ Presets
  - [x] Indeks pencarian offline super cepat
- [x] **6.2 Customization Settings: Visualizer & Display Options** (Sesuai `customization_settings`)
  - [x] **Visualizer Style**: Pilihan gaya visualizer (*Spectrum Bars*, *Spline Smooth Waveform*, *Dual Analog VU Meters*, *Circular Halo*)
  - [x] **Visualizer Tuning**: FFT Bins selector (256, 512, 1024, 2048) & Decay Falloff Speed slider
  - [x] **Album Art Styling**: Squircle corner radius selector (`0px` sharp, `14px` squircle, `28px` rounded)
  - [x] **Ambient Glow & Effects**: Slider intensitas blur ambient shadow & toggle animasi vinyl spinning
- [x] **6.3 Customization Settings: Hardware Audio & DAC Engine**
  - [x] Pilihan Output Device (ALSA direct, USB DAC Exclusive Mode)
  - [x] Buffer Size / Output Latency tuning slider
  - [x] Bit-perfect playback & direct resampling policy
- [x] **6.4 Customization Settings: Library & Scanner Rules**
  - [x] Included & Excluded Folders manager (tambah/hapus path folder musik)
  - [x] Minimum Audio Duration filter (misal: abaikan file < 30 detik / ringtones)
  - [x] Minimum Audio File Size filter (misal: abaikan file < 500 KB)

---

## Fase 7: Queue Management, Playback History & Session Memory
Pengelolaan antrean pemutaran lagu dinamis, pencatatan histori dan statistik mendengarkan, serta pemulihan sesi pemutaran audio.

- [x] **7.1 Now Playing Queue Sheet & Reordering**
  - [x] Lembar antrean lagu aktif (*Up Next Queue Sheet*) dapat diakses dari Now Playing Screen
  - [x] Drag-to-reorder untuk mengubah urutan lagu dalam antrean secara interaktif
  - [x] Swipe-to-dismiss untuk menghapus lagu dari antrean pemutaran
  - [x] Tombol aksi: `[Play Next]` dan `[Clear Queue]`
- [x] **7.2 Playback History Tracking & Listening Statistics**
  - [x] Pencatatan otomatis setiap lagu yang telah diputar (disimpan persisten di Local Persistence DB)
  - [x] Panel statistik audiophile di Dashboard: Total waktu mendengarkan (jam), jumlah pemutaran Hi-Res FLAC vs Standar, dan Top 5 lagu paling sering diputar
- [x] **7.3 Last Session Resume & State Restoration**
  - [x] Penyimpanan otomatis track terakhir, posisi pemutaran (timestamp ms), dan status antrean saat aplikasi ditutup
  - [x] Opsi otomatis memulihkan lagu dan posisi saat aplikasi dibuka kembali

---

## Fase 8: Sleep Timer, File Inspector & Metadata Tag Editor
Fitur utilitas audio audiophile: pengatur waktu tidur dengan fade out halus, inspeksi teknis mendalam file audio, dan pengeditan metadata tag.

- [x] **8.1 Smart Sleep Timer dengan Gradual Fade-Out**
  - [x] Pilihan timer tidur: 15 menit, 30 menit, 45 menit, 60 menit, atau kustom
  - [x] Opsi *Stop at end of track* (berhenti otomatis setelah lagu yang sedang berjalan selesai)
  - [x] Gradual volume fade-out (penurunan volume secara bertahap selama 15 detik sebelum pemutaran berhenti agar tidak mengagetkan)
- [x] **8.2 Technical Audio File Inspector Modal**
  - [x] Dialog inspeksi teknis mendalam file audio: Codec profile, Bitrate real-time (kbps), Channels (Stereo/Mono), Container format, File size asli, Magic bytes header, dan MD5 checksum
- [x] **8.3 Metadata Tag Editor**
  - [x] Antarmuka pengeditan tag lagu lokal: Judul, Artis, Album, Tahun Rilis, Genre, Nomor Trek
  - [x] Kemampuan mengganti cover art file audio lokal

---

## Fase 9: Studio Landscape & Dual-Pane Adaptive Layout
Optimalisasi tata letak responsif untuk orientasi lanskap, tablet, dan docking desktop DAC.

- [x] **9.1 Adaptive Dual-Pane Layout (Tablet / Landscape / Desktop)**
  - [x] Tampilan split dua kolom saat orientasi horizontal (Kiri: Now Playing Album Art & Synchronized Lyrics, Kanan: Pro-Q Studio EQ / DSP Mastering Rack)
  - [x] Responsive navigation rail di sisi kiri untuk layar lebar
- [x] **9.2 Studio Desk & Car Docking Fullscreen Mode**
  - [x] Mode tampilan layar penuh kontras tinggi dengan tombol kontrol besar dan jam studio untuk docking USB DAC di meja kerja

---

## Fase 10: AutoEQ Online Target Downloader (Squiglink Cloud Database)
Integrasi cloud downloader untuk kurva target dan pengukuran IEM/Headphone langsung ke Pro-Q Studio.

- [x] **10.1 Cloud Catalog Client untuk Squiglink / AutoEQ Targets**
  - [x] Pencarian online basis data kurva target (Harman 2019v2, IEF Neutral, HBB, Crinacle, Bad Guy, Super Review, Oratory1990, Diffuse Field 5128)
  - [x] Basis data pengukuran IEM dan Headphone populer (KZ, Moondrop, Tangzu, 7Hz, Truthear, Sennheiser, HiFiMAN, Sony)
  - [x] Pengunduhan instan dan caching file target CSV/TXT langsung ke database persisten lokal
- [x] **10.2 Direct AutoEQ Solver Integration**
  - [x] Dialog browser cloud terintegrasi (`AutoEqCloudBrowserDialog`) diakses langsung dari Pro-Q Studio toolbar dan AutoEQ modal
  - [x] Terapkan kurva target dan pengukuran driver online langsung ke AutoEQ Biquad Optimizer Solver dengan tombol `[SOLVE]` 1-klik tanpa perlu transfer file manual

---

## Fase 14: Adopsi & Stabilisasi DSP Audio Engine (RYNLABS_HIFI Flow)
Adopsi arsitektur SoLoud C++ FFI `VirtualDspService` dan `AudioService` dari RYNLABS_HIFI untuk menjamin reproduksi suara bit-perfect, crash-free, dan perbaikan parameter unit scaling (anti-distorsi).

- [x] **14.1 Unified `VirtualDspService` (Single Source of Truth)**
  - [x] Konsolidasi seluruh kontrol filter SoLoud C++ native ke satu servis terpusat `VirtualDspService`
  - [x] Perbaikan unit parameter scaling: milidetik presisi `attackTime * 1000.0` dan `releaseTime * 1000.0` untuk kompresor dan limiter
- [x] **14.2 Integrasi Master Filter Chain Deterministik (10 Modul)**
  - [x] Urutan filter master bus: Preamp $\rightarrow$ Parametric EQ $\rightarrow$ Bass Boost $\rightarrow$ Tube Exciter $\rightarrow$ Compressor $\rightarrow$ Stereo Width $\rightarrow$ Crossfeed $\rightarrow$ Reverb $\rightarrow$ Pitch Shift $\rightarrow$ Brickwall Limiter
- [x] **14.3 Auto-Headroom Safe Preamp & Hard Brickwall Limiter (-1.3 dBFS)**
  - [x] Formula kalkulasi atenuasi pre-amp otomatis: $\text{Preamp} = -\max(0, \max(\text{EQ})) - 0.5\text{ dB}$
  - [x] Kunci brickwall limiter pada hard ceiling `-1.3 dBFS` untuk proteksi distorsi inter-sample peak
- [x] **14.4 Isolate-based AutoEQ Biquad Solver Engine**
  - [x] Algoritma isolat non-blocking `auto_eq_optimizer.dart` dari RYNLABS_HIFI dengan deteksi resonansi dan kalkulasi weighted RMSE
- [x] **14.5 Telemetri Spektrum RTA & Ballistic VU Meters**
  - [x] Event stream `SoLoud.instance.audioVisualizationEvents` terhubung ke RTA 512-bin, VU Meter analog jarum balistik, dan LED bars
- [x] **14.6 Dedicated Unit & DSP Math Tests Validation**
  - [x] Test suite komprehensif memvalidasi aktivasi filter, nilai parameter, auto-headroom math, dan AutoEQ solver (`dsp_audio_engine_fusion_test.dart` with 92 passing tests)

---

## Fase 15: Customization, Parallax, Blur, Gestures & Visual Dynamics (Namida Flow)
Implementasi sistem kustomisasi visual mendalam, efek 3D parallax, gaussian blur, dynamic ambient glow, performa adaptif, dan gestur album art.

- [x] **15.1 Parallax 3D Motion Physics Engine**
  - [x] Controller parallax interaktif pada album art cover di Now Playing dan MiniPlayer (`ParallaxArtworkCard`)
- [x] **15.2 Dynamic Backdrop Blur & Ambient Glow Subsystem**
  - [x] Backdrop gaussian blur terisolasi dengan parameter sigma yang dapat diatur (`blurSigma`)
  - [x] Ambient dynamic glow lembut di sekeliling album art & playback buttons
  - [x] Audio-reactive breathing artwork pulse yang merespons bass transients dari FFT stream
- [x] **15.3 Adaptive Performance Mode Presets**
  - [x] Preset `Studio HiFi (120fps)`, `Balanced (60fps)`, `Battery Saver`, dan `Custom` di `PlayerCustomizationSettings`
- [x] **15.4 Artwork & Track Tile Gestures Configuration**
  - [x] Single-tap, double-tap, dan long-press handler pada album art
  - [x] Swipe-to-action pada track tile library (Swipe Left: Queue/Play Next, Swipe Right: Playlist/Fav)
- [x] **15.5 Track Tile Display Layout Customizer**
  - [x] Pilihan urutan judul (*Artist - Title* vs *Title - Artist*), kustomisasi baris ke-3, dan direct favorite button
- [x] **15.6 Dedicated Tests Validation**
  - [x] Unit & widget tests untuk parallax controller, performance mode, track tile layout, dan gestures (`customization_and_parallax_test.dart` with 99 passing tests)

---

## Fase 16: Advanced Playback Engine & Interruption Policies (Namida Flow)
Pengaturan pemutaran audio, transisi, dan kebijakan interupsi perangkat dari Namida.

- [x] **16.1 Smooth Play/Pause Volume Fade Engine**
  - [x] Fade-in volume saat Play dan Fade-out saat Pause (100ms – 1500ms)
- [x] **16.2 Audio Device Interruption & Headphone Unplug Manager**
  - [x] Auto-pause saat earphone/DAC/Bluetooth terputus; auto-resume cerdas jika tersambung kembali dalam batas waktu
  - [x] Auto-pause saat volume perangkat bernilai 0
- [x] **16.3 Speed & Pitch Semitone Engine**
  - [x] Kontrol playback speed (0.25x s/d 3.0x) dan Pitch (-12 s/d +12 semitones, cents) dengan link switch
- [x] **16.4 ReplayGain Normalization & Skip Silence Engine**
  - [x] Normalisasi loudness otomatis berbasis tag ReplayGain (Track/Album dB) dan skip bagian hening
- [x] **16.5 Custom Seek Stepper & Time Display Modes**
  - [x] Langkah tombol seek kustom (detik konstan / persentase durasi) dan toggle Remaining vs Total time
- [x] **16.6 Dedicated Tests Validation**
  - [x] Unit test untuk volume fade, interruption policies, dan ReplayGain (118/118 passing tests)

---

## Fase 17: Smart Playlists Dynamic Rule Engine (Namida Feature)
Generator playlist dinamis berbasis aturan multi-filter yang terbarui otomatis.

- [x] **17.1 Domain Model & Filter Condition Framework**
  - [x] Model `SmartPlaylist`, `SmartPlaylistRule`, dan `FilterCondition` (Text, Number, Date, Boolean)
- [x] **17.2 Dynamic Query Evaluator & Auto-Refresh**
  - [x] Evaluator query lokal deterministik dengan auto-refresh saat library berubah
- [x] **17.3 Material 3 Expressive `CreateSmartPlaylistDialog`**
  - [x] Antarmuka pembuatan aturan multi-kondisi dengan chips operator dan live counter
- [x] **17.4 Smart Playlists Management & Tracks Subpage**
  - [x] Tab Smart Playlists di Library, menu edit aturan, export playlist ke M3U8
- [x] **17.5 Dedicated Tests Validation**
  - [x] Unit test untuk seluruh operator filter dan eksekusi evaluator (130/130 passing tests)

---

## Fase 18: Multi-Track Metadata Tagger & Tag Extraction System (Namida Feature)
Editor metadata fisik audio lokal yang tangguh untuk single maupun batch files.

- [x] **18.1 Native/Pure Dart Metadata Tag Read & Write Service**
  - [x] Dukungan format: ID3v2.3/v2.4 (MP3), Vorbis Comments (FLAC/OGG/OPUS), MP4 Atoms (M4A/AAC), RIFF (WAV) melalui `MetadataTaggerService` dan `AudioTagData`
- [x] **18.2 Single & Batch `EditTagsDialog` (Material 3 Expressive)**
  - [x] Mode Single Track (`MetadataTagEditorSheet`: edit field lengkap, album art image picker, format tech badge) dan Mode Batch Tracks (`BatchTrackTagEditorModal`: edit bersama, album art batching, auto-numbering sequencer 1..N, filename pattern parser)
- [x] **18.3 Library Database Cache Synchronization**
  - [x] Sinkronisasi instan metadata baru ke persistent storage database di `UnifiedLibraryController` dan update real-time antrean/lagu aktif di `PlayerController`
- [x] **18.4 Dedicated Tests Validation**
  - [x] Validasi penulisan tag ke file fisik, parser pola nama file, sequencer auto-numbering, dan controller state synchronization (`metadata_tagger_test.dart` dengan 138 passing tests total)

---

## Fase 19: East Asian Lyrics & Metadata Romanizer Engine (Namida Feature)
Transliterasi otomatis karakter teks lirik dan judul lagu dari bahasa Asia Timur ke alfabet Latin.

- [x] **19.1 Romanizer Core Engine**
  - [x] Modul Jepang (Romaji Hepburn dengan digraph, sokuon, chōonpu, kamus kanji), Korea (Romaja Revised via dekomposisi matematis silabel Hangul), dan Mandarin (Pinyin dengan/tanpa nada) di `EastAsianRomanizer`
- [x] **19.2 Synchronized Lyrics Modes Integration**
  - [x] Mode *Original Text* (`ORIG`), *Romanized Text* (`ROM`), dan *Dual-Line Display* (`DUAL`) di `SynchronizedLyricsView` dengan persistensi lokal
- [x] **19.3 LRC Timing Synchronizer & Offset Adjuster**
  - [x] Bottom sheet modal penyesuaian offset waktu lirik sub-second precision (`±100ms`, `±500ms`, continuous slider, reset) dengan kalkulasi real-time di `LrcParser.findActiveIndex()` dan persistensi per-track
- [x] **19.4 Dedicated Tests Validation**
  - [x] Unit test transliterasi teks sampel bahasa Jepang, Korea, dan Mandarin, auto-romanizer di parser LRC, timing offset calculator, serta widget tests (`east_asian_romanizer_test.dart` dengan total 155/155 passing tests)

---

## Fase 20: Advanced Library Indexer, Storage Cache, Backup & Settings Fusion
Utilitas pemeliharaan database, penanganan file hilang/duplikat, manajemen kuota cache, pencadangan, dan reorganisasi pengaturan.

- [x] **20.1 Missing Tracks & Duplicate Resolver**
  - [x] Deteksi file berpindah folder (*missing tracks resolver*) dan pembersihan lagu duplikat berbasis audiophile fidelity rating (`LibraryIndexerService`, `MissingTracksResolverSheet`, `DuplicateTracksResolverModal`)
- [x] **20.2 Storage & Cache Quota Manager**
  - [x] Monitoring ukuran cache (Artwork, Lyrics, DB, Playback history) dan pembersihan granular serta 1-klik *Purge All Caches* (`StorageCacheManager`, `StorageCacheSettingsScreen`)
- [x] **20.3 Full Backup & Restore System (`.bayhifi` JSON Archive)**
  - [x] Ekspor dan impor seluruh konfigurasi tema, playlists kustom, smart rules, DSP presets, history, and favorites (`BackupRestoreService`, `BackupRestoreSettingsScreen`)
- [x] **20.4 Reorganisasi 7 Kategori Pengaturan Studio**
  - [x] Menu terstruktur rapi: *Theming & Color Palettes*, *Visualizer & Display*, *Gestures & Track Tiles*, *Studio Workstation & Car Dock*, *Audio Hardware & DAC Engine*, *Library Scanner & Sleep Timer*, *Storage & Cache Quota*, *Backup & Restore Archive*
- [x] **20.5 Multi-Select Batch Actions Bar**
  - [x] Seleksi multi-track di library: Play Next, Add to Queue, Add to Playlist, Batch Tag Editor, Deselect All (`LibraryBatchActionsBar`, `TrackTile` multi-selection mode)
- [x] **20.6 Dedicated Tests Validation**
  - [x] Unit & widget tests untuk indexer, cache quota calculator, backup/restore JSON validator, batch action dock, dan sub-screens (`storage_backup_and_indexer_test.dart` dengan total 170/170 passing tests dan 0 analyzer issues)

---

## Fase 21: Master Quality Assurance, Performance Profiling & 100% Passing Tests
Pengujian stabilitas menyeluruh, benchmarking performa, dan pemenuhan 100% test passing.

- [x] **21.1 Eksekusi Menyeluruh Test Suite (`flutter test`)**
  - [x] Memastikan seluruh unit dan widget tests lulus 100% (177/177 passing tests di 32 test files)
- [x] **21.2 Analisis Kode Statis (`flutter analyze`)**
  - [x] Memastikan 0 analyzer errors dan 0 warnings di seluruh codebase (No issues found!)
- [x] **21.3 Verifikasi Integrasi End-to-End**
  - [x] Uji alur lengkap dari scan file lokal $\rightarrow$ play audio bit-perfect $\rightarrow$ DSP mastering $\rightarrow$ parallax/blur $\rightarrow$ tagger $\rightarrow$ smart playlist $\rightarrow$ backup/restore (`master_e2e_integration_test.dart`)
- [x] **21.4 Kepatuhan Standar Zero-Emoji, Solid Surfaces & 100% HugeIcons**
  - [x] 0 emojis di seluruh `lib/`, 100% HugeIcons icons (`HugeIcons.strokeRounded...`), solid Material 3 surfaces, and tabular figures formatting untuk metadata audio/angka.
- [x] **21.5 Android System Back Navigation & MiniPlayer PopScope Resolver (Bugfix)**
  - [x] Implementasi `PopScope(canPop: !isExpanded && !_isCategoryDockExpanded, onPopInvokedWithResult: ...)` di `NamidaExpandableMiniPlayer` sehingga penekanan tombol navigasi kembali bawaan Android atau swipe back gesture saat screen player terbuka akan menciutkan player menjadi miniplayer dan kembali ke screen sebelumnya tanpa keluar dari aplikasi.
  - [x] Integrasi `PopScope(canPop: !_isMultiSelecting, ...)` di `UnifiedLibraryScreen` untuk membatalkan multi-seleksi batch tracks saat menekan back.
  - [x] Validasi test suite di `back_navigation_and_miniplayer_collapse_test.dart` (180/180 tests passing total, 0 analyzer issues).

---

## Fase 22: Deterministic Bidirectional Shuffle Queue Engine & Original Context Restoration
Penyempurnaan arsitektur antrean putar dengan pelestarian konteks asal dan visualisasi queue acak yang deterministik.

- [x] **22.1 Pelestarian Antrean Orisinal (`originalQueue` in `PlaybackState`)**
  - [x] Penambahan atribut immutable `originalQueue` pada `PlaybackState` untuk menyimpan urutan asli album, playlist, library, genre, artist, folder, atau top mix dari mana lagu mulai diputar.
- [x] **22.2 Sinkronisasi Pengacakan Antrean Deterministik (`shuffleQueue` & `setQueue`)**
  - [x] Saat *Shuffle ON*: Mengacak daftar antrean aktif (`queue`) dengan menyematkan (*pin*) track yang sedang diputar di posisi index 0. Daftar antrean yang terlihat pada `NowPlayingQueueSheet` merefleksikan urutan acak tersebut.
  - [x] Navigasi *Next* (`skipNext()`) maju secara sekuensial mengikuti urutan acak yang terlihat di antrean (`0 -> 1 -> 2 -> ...`), mengeliminasi bug *double randomization*.
- [x] **22.3 Pemulihan Konteks Asal saat Shuffle Dimatikan (`toggleShuffle`)**
  - [x] Saat *Shuffle OFF*: Memulihkan urutan asli secara instan dari `originalQueue`. Track yang sedang diputar tetap aktif di index aslinya pada daftar asal tersebut, dan navigasi *Next/Previous* kembali mengikuti urutan album/playlist awal.
- [x] **22.4 Sinkronisasi Mutasi Antrean & Sesi Persistence**
  - [x] Sinkronisasi `originalQueue` pada semua operasi mutasi: `addToQueue`, `playNext`, `reorderQueue`, `removeFromQueue`, `clearQueue`, `_saveSession`, dan `_restoreSession`.
- [x] **22.5 Dedicated Tests Validation**
  - [x] Unit test komprehensif di `shuffle_queue_preservation_test.dart` (7 unit tests menguji aktivasi shuffle, penempatan pin index 0, navigasi sekuensial skip next/previous, restorasi instan context asal saat shuffle off, mutasi antrean, dan persistensi sesi dengan total 187/187 passing tests).

---

## Fase 23: Queue Auto-Centering & Ordering-Aware Contextual Scrollbars Engine
Ergonomi navigasi antrean putar dengan auto-fokus di tengah dan scrollbar kontekstual cerdas pada library musik.

- [x] **23.1 Queue Sheet Active Track Auto-Focus Centering**
  - [x] Implementasi auto-centering di `NowPlayingQueueSheet` menggunakan `ScrollController` dengan post-frame calculation: `(queueIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2)` yang secara otomatis memusatkan lagu yang sedang aktif di tengah viewport saat pergantian lagu (`skipNext`/`skipPrevious`/`skipToQueueIndex`) maupun saat antrean dibuka.
- [x] **23.2 Queue Sheet Studio Scrollbar**
  - [x] Penambahan Material 3 Studio regular `Scrollbar` di sisi kanan `NowPlayingQueueSheet` dengan interactive thumb dragging, pill radius, dan aksen warna tema.
- [x] **23.3 Library Alphabetical Fast-Scroller (`StudioAlphabeticalScroller`)**
  - [x] Komponen scroller kustom berkinerja tinggi dengan rel alfabet interaktif (`#`, `A`–`Z`) di sisi kanan saat library diurutkan berdasarkan Nama / Judul / Artis (`SortField.title`, `SortField.artist`, `SortField.album`).
  - [x] Navigasi instan via tap & drag dengan haptic feedback halus (`HapticFeedback.selectionClick()`), pencocokan huruf otomatis, sinkronisasi highlighting huruf aktif saat scroll normal, dan indikator huruf mengambang (*floating studio bubble indicator*).
- [x] **23.4 Fallback Scrollbar Standar untuk Pengurutan Non-Alfabetis**
  - [x] Saat library diurutkan berdasarkan kriteria non-alfabetis (`SortField.duration`, `SortField.dateAdded`, `SortField.hiRes`), sistem otomatis menampilkan standard Studio Material 3 `Scrollbar`.
---

## Fase 24: RYNLABS DSP Parity, Bidirectional Pro-Q Sync & Offline AutoEQ Caching
Sinkronisasi mendalam arsitektur DSP Rack dengan RYNLABS_HIFI, sinkronisasi dua arah PreAmp dengan Pro-Q Studio, penyimpanan offline otomatis kurva AutoEQ / target / driver, dan optimalisasi UI/UX layar DSP Rack dan modal dialog portrait.

- [x] **24.1 RYNLABS DSP Mathematical & Logic Parity (`VirtualDspService`)**
  - [x] Verifikasi 100% keselarasan rumus dan arsitektur pemrosesan audio C++ mastering chain dengan `/mnt/01DC9A2666E1A190/Other/PROJECTS/DSP/RYNLABS_HIFI` (Master Bypass deactivation tanpa kehilangan parameter, Freeverb volume compensation formula $-1.0 \times (\text{wet} \times 0.75)\text{ dB}$, Tube warmth & drive scaling, dynamic compressor lookahead, limiter true peak output ceiling, dan biquad filter transfer function).
- [x] **24.2 Bidirectional PreAmp & Headroom Synchronization**
  - [x] Integrasi sinkronisasi dua arah (*bidirectional sync*) Pre-Amp gain antara `DspRackController`, `EqController`, dan `VirtualDspService` (Single Source of Truth).
  - [x] Modifikasi PreAmp di Unit 01 DSP Rack langsung memutasi headroom dan safe preamp di Pro-Q Studio, dan sebaliknya perubahan PreAmp atau Auto-Headroom di Pro-Q Studio langsung memperbarui slider PreAmp dan level meter di DSP Rack.
  - [x] Pembuatan komponen interaktif `_PreampBox` pada `BandStripBar` di Pro-Q Studio yang membuka *Material 3 Studio PreAmp & Headroom bottom sheet* lengkap dengan slider input gain, toggle auto-headroom protection, dan quick gain preset chips (`-12 dB`, `-6 dB`, `-3 dB`, `-1 dB`, `0 dB FLAT`, `+3 dB`).
- [x] **24.3 Automatic Persistent Offline Storage for AutoEQ Cloud Presets & Target Curves**
  - [x] Penambahan serialisasi dan deserialisasi `FrCurveData.toMap()` / `FrCurveData.fromMap()`.
  - [x] Penambahan metode `saveFrCurve()`, `getSavedFrCurves()`, `deleteFrCurve()`, `saveDownloadedAutoEqIds()`, dan `getDownloadedAutoEqIds()` di `LocalPersistenceService`.
  - [x] Saat pengguna mengunduh kurva target atau pengukuran IEM/headphone via `AutoEqCloudService.downloadItem()` atau mengimpor URL Squiglink, kurva tersebut secara otomatis disimpan ke penyimpanan offline persisten dan langsung terhidrasi ke daftar target/driver di `EqController`.
- [x] **24.4 UI/UX Optimization for DSP Rack & Compact Mobile Portrait Viewports (360x780)**
  - [x] Penambahan baris *Quick Gain Selector Chips* pada Unit 01 Pre-Amp Gain Stage di `DspRackScreen` (`-12 dB`, `-6 dB`, `-3 dB`, `-1 dB`, `0 dB Flat`, `+3 dB`).
  - [x] Optimalisasi tata letak responsif `AutoEqCloudBrowserDialog` dengan `LayoutBuilder` (tampilan 2-tier stacked cards yang nyaman pada layar portrait sempit 360px tanpa overlap / overflow).
  - [x] Optimalisasi `SquiglinkDialog` dan `AutoEqModalDialog` dengan pembungkus `Wrap` dan `BoxConstraints` fleksibel, mengeliminasi seluruh risiko `RenderFlex` overflow pada mode portrait.
---

## Fase 25: Studio Stability, DSP Profile Saving, Navidrome Full Sync & Spotify-Grade Audio Caching
Penyempurnaan stabilitas interaksi, penyimpanan profil DSP (paritas RYNLABS), sinkronisasi penuh library Navidrome, proteksi konkurensi streaming audio ganda, dan engine caching audio/download offline Spotify-grade.

- [x] **25.1 Search Focus & Soft Keyboard Popup Resolver**
  - [x] Pasang `_searchFocusNode` pada search TextField di `UnifiedLibraryScreen`.
  - [x] Unfocus keyboard secara otomatis saat track diputar, saat pencarian ditutup, dan saat miniplayer disentuh/ditarik ke `NowPlayingScreen`.
- [x] **25.2 DSP Rack & Pro-Q User Profile Saving & Auto-Restore (100% RYNLABS Parity)**
  - [x] Tambahkan `toMap()` / `fromMap()` pada `DspRackState` dan simpan seluruh parameter DSP (Tube, Bass Boost, Compressor, Reverb, Limiter, Stereo Width, PreAmp) ke `LocalPersistenceService`.
  - [x] Auto-restore state DSP aktif terakhir saat aplikasi dijalankan ulang.
  - [x] Implementasikan custom user DSP profiles manager (`saveCustomProfile`, `loadCustomProfile`, `deleteCustomProfile`).
  - [x] Tambahkan tombol `SAVE` interaktif di top bar `ProQStudioScreen` (di sebelah kiri tombol Power) yang aktif saat ada perubahan pada kurva/filter/driver/target untuk menyimpan preset baru atau memperbarui preset aktif.
- [x] **25.3 Queue Sheet Dynamic Auto-Scroll & Centering on Track Advance**
  - [x] Perbaiki post-frame positioning dan scroll dimensions pada `NowPlayingQueueSheet` dengan reactive listener `queueIndex`.
  - [x] Pastikan saat pergantian lagu (next/prev/auto-advance), track aktif di posisi mana pun (tengah/bawah antrean) langsung bergulir mulus dan terpusat di tengah layar.
- [x] **25.4 Navidrome Subsonic Full Library Sync & Playback Concurrency Guard**
  - [x] Ganti limit hardcoded `getRandomSongs(size: 50)` dengan `fetchAllSongs` (paginated Subsonic search/album sync untuk memuat seluruh ribuan lagu).
  - [x] Pasang atomic token `_playRequestId` pada `SoLoudController` dan `PlayerController` untuk mencegah overlapping audio ganda saat user menekan lagu streaming berulang kali.
- [x] **25.5 Spotify-Grade Audio Caching, Offline Downloads & Next-Track Smart Prefetch Engine**
  - [x] Buat `AudioCacheService` untuk mengelola cache audio lokal (`${appDocDir}/audio_cache/`).
  - [x] Auto-caching saat remote track diputar (streaming sekaligus menyimpan ke cache, pemutaran berikutnya 0ms dari file lokal).
  - [x] Smart Next-Track Prefetching: Mengunduh 1 track berikutnya di antrean di background saat lagu sedang diputar.
  - [x] Download Manager: Sediakan tombol manual "Download Track / Album" untuk pemutaran offline tanpa koneksi server.
- [x] **25.6 Comprehensive Test Suite & Zero Analyzer Issues Validation**
  - [x] Buat unit & widget tests di `test/phase_25_stability_and_caching_test.dart` dan validasi 100% passing tests (214/214 total passing tests) dengan 0 analyzer warnings.

---

## Fase 26: Dedicated Detail Screens (Spotify/Namida Grade), Full Scrollbars & Android Release Notification Resolver
Migrasi arsitektur dari bottom modal sheets ke dedicated Material 3 Expressive screens (`AlbumDetailScreen`, `ArtistDetailScreen`, `GenreDetailScreen`, `FolderDetailScreen`), perbaikan artwork dan scrollbar interaktif, hirarki diskografi artis (carousel album + daftar seluruh lagu), navigasi dua arah Album ⇄ Artis, dan pemecahan masalah notifikasi status bar Android di mode release.

- [x] **26.1 Android Release Mode Status Bar Playback Notification Resolver**
  - [x] Tambahkan izin `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` di `android/app/src/main/AndroidManifest.xml`.
  - [x] Buat file `android/app/proguard-rules.pro` untuk memproteksi paket `com.ryanheise.audioservice.**`, `androidx.media.**`, `android.support.v4.media.**`, `io.flutter.**`, dan `com.flutter.soloud.**` dari R8/ProGuard code shrinking & obfuscation.
  - [x] Konfigurasikan `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")` di `buildTypes.release` pada `android/app/build.gradle.kts`.
  - [x] Buat icon vector status bar `ic_stat_music.xml` di `android/app/src/main/res/drawable/` dan tautkan ke `AudioServiceConfig(androidNotificationIcon: 'drawable/ic_stat_music')` di `lib/main.dart`.
  - [x] Tambahkan otomatisasi `Permission.notification.request()` pada `ensureStoragePermissions()` di `LibraryController`.
- [x] **26.2 Dedicated Album Detail Screen (`AlbumDetailScreen`)**
  - [x] Cover art album resolusi penuh dengan `StudioArtworkWidget`, badge Lossless Hi-Res studio, dan total durasi berformat angka tabular.
  - [x] Dynamic Collapsing Sliver Header: Saat discroll, cover besar dan metadata bertransisi mulus (cross-fade) menjadi mini squircle thumbnail (34x34) dan judul album + nama artis di pinned AppBar.
  - [x] Pinned Sticky Action Bar (`_StickyActionBarDelegate`): Tombol `Play All` (dengan status reaktif Playing/Paused) dan `Shuffle` tetap tersemat (pinned) di atas daftar track saat pengguna menggulir ke bawah.
  - [x] Tautan nama artis interaktif yang membuka `ArtistDetailScreen` (navigasi dua arah).
  - [x] Action header studio: `Play All`, `Shuffle`, dan `Edit Album Tags` modal.
  - [x] Daftar track berurutan sesuai track number dengan thumbnail lagu, format badge, durasi tabular, waveform aktif saat lagu berputar, dan context menu aksi 3-dots.
  - [x] Material 3 Studio `Scrollbar` interaktif.
- [x] **26.3 Dedicated Artist Detail Screen (`ArtistDetailScreen`)**
  - [x] Hero header artis dengan `ArtistAvatarWidget`, nama artis, dan statistik total album serta total track.
  - [x] Dynamic Collapsing Sliver Header: Bertransisi mulus menjadi mini circular avatar + nama artis + jumlah lagu di pinned AppBar saat discroll.
  - [x] Pinned Sticky Action Bar: Tombol `Play All` & `Shuffle` tetap tersemat (pinned) selama navigasi scroll.
  - [x] Carousel horizontal diskografi album artis (cover art squircle + tahun rilis) dengan tap action langsung navigasi ke `AlbumDetailScreen`.
  - [x] Daftar seluruh lagu milik artis dengan `StudioArtworkWidget`, format badge, durasi tabular, dan Material 3 Studio `Scrollbar`.
- [x] **26.4 Dedicated Genre Detail Screen (`GenreDetailScreen`)**
  - [x] Hero header kategori genre dengan icon genre, nama genre, dan jumlah lagu.
  - [x] Dynamic Collapsing Sliver Header: Bertransisi ke mini genre icon + nama genre di pinned toolbar.
  - [x] Pinned Sticky Action Bar: `Play All` dan `Shuffle` tetap pinned di atas tracklist.
  - [x] Daftar seluruh lagu dalam genre dengan `StudioArtworkWidget`, format badge, dan Material 3 Studio `Scrollbar`.
- [x] **26.5 Dedicated Folder Explorer Detail Screen (`FolderDetailScreen`)**
  - [x] Hero header direktori lokal dengan breadcrumb path direktori fisik dan jumlah audio file.
  - [x] Dynamic Collapsing Sliver Header: Bertransisi ke mini folder icon + nama folder di pinned toolbar.
  - [x] Pinned Sticky Action Bar: `Play All` dan `Shuffle`.
  - [x] Memperbaiki perilaku klik item folder di tab Folders: membuka daftar isi file di `FolderDetailScreen` (tidak langsung memutar lagu).
  - [x] Action header studio: `Play All`, `Shuffle`, dan `Batch Edit Folder Tags`.
  - [x] Daftar lagu dalam folder dengan `StudioArtworkWidget` dan Material 3 Studio `Scrollbar`.
- [x] **26.6 Bidirectional Cross-Navigation & Unified Library Integration**
  - [x] Hubungkan navigasi `_openAlbumDetail`, `_openArtistDetail`, `_openGenreDetail`, `_openFolderDetail` di `UnifiedLibraryScreen` menggunakan `Navigator.push`.
  - [x] Cross-navigation mulus antara Album ⇄ Artist.
- [x] **26.7 Unified Studio Track Action Bottom Sheet (`StudioTrackActionSheet`)**
  - [x] Menyatukan seluruh interaksi tombol 3-dots lagu di seluruh aplikasi (`TrackTile` di Library, `AlbumDetailScreen`, `ArtistDetailScreen`, `GenreDetailScreen`, dan `FolderDetailScreen`) ke dalam satu modal bottom sheet studio yang konsisten 100%.
  - [x] Header visual terpadu: Thumbnail squircle artwork, judul lagu, artis • album, badge Hi-Res/FLAC, dan status cache offline.
  - [x] Daftar aksi lengkap: *Play Next*, *Add to Queue*, *Add to Playlist*, *Go to Album*, *Go to Artist*, *Add/Remove Favorite*, *Download/Cache Offline*, *Edit Metadata Tags*, dan *Inspect Audio Specs*.
- [x] **26.8 Unit & Widget Test Suite Validation (223/223 Tests Passing)**
  - [x] Buat suite pengujian komprehensif di `test/phase_26_library_detail_screens_test.dart` dan `test/studio_track_action_sheet_test.dart` menguji rendering ke-4 screen detail, scroll parallax collapse behavior, integrasi action sheet terpadu, dan navigasi silang dua arah.
  - [x] Validasi 100% test lulus (223/223 tests) dengan 0 errors dan 0 warnings pada `flutter analyze`.

---

## Fase 27: Streamlined NowPlayingScreen UX & Unified Studio DSP Bento Capsule
Penyederhanaan tata letak vertikal `NowPlayingScreen`, penggabungan pintasan AutoEQ Driver/Target Profile dan Mastering DSP Rack menjadi satu baris kapsul horizontal Bento terpadu (38px height), ekspansi ukuran cover art album proporsional, cross-navigation interaktif Artist • Album, dan eliminasi redundansi spesifikasi audio.

- [x] **27.1 Ultra-Compact Studio Slim Chips Module (`StudioDspBentoCapsule` - Opsi 2)**
  - [x] Modul chip lonjong mikro horizontal berukuran super ramping (28px height): Sisi Kiri (AutoEQ Tuning Chip dengan icon headphone, nama IEM/Driver terpotong rapi, indikator aktif hijau, tap $\rightarrow$ `AutoEqModalDialog`) dan Sisi Kanan (Mastering DSP Rack Chip dengan icon slider, hitungan modul aktif real-time misal `DSP (2)`, chevron indicator, tap $\rightarrow$ `DspRackScreen`).
  - [x] Mengurangi 90% kepadatan visual di bawah cover album sehingga sangat bersih, elegan, dan lega.
- [x] **27.2 NowPlayingScreen Layout Optimization & Interactive Cross-Navigation**
  - [x] Peningkatan proporsi cover art album dari 32.5% menjadi 35.5% (`albumArtSize = (availableHeight * 0.355).clamp(210.0, availableWidth - 44.0)`).
  - [x] Tautan interaktif nama artis dan album: klik nama artis membuka `ArtistDetailScreen`, klik nama album membuka `AlbumDetailScreen`.
  - [x] Pengurangan redundansi visual pada spesifikasi audio dan branding studio.
  - [x] Pencegahan RenderFlex overflow pada mode potret sempit di `DspRackScreen`.
- [x] **27.3 Dedicated Unit & Widget Tests Validation (227/227 Tests Passing)**
  - [x] Pembuatan test suite di `test/studio_dsp_bento_capsule_test.dart` yang menguji rendering chip ramping Opsi 2, interaksi tap modal AutoEQ, navigasi ke DSP Rack, dan integrasi responsif di `NowPlayingScreen`.
  - [x] Validasi penuh 100% test suite passing dan 0 analyzer issues.

---

## Fase 28: YouTube Music Streaming Integration, Search & DSP Mastering Engine
Integrasi pencarian dan streaming jutaan lagu YouTube & YouTube Music langsung melalui C++ SoLoud audio engine, pemrosesan rantai master DSP (Pro-Q Parametric EQ, AutoEQ IEM Tuning, Tube Warmth, Compressor, Limiter), auto-caching offline disk (`AudioCacheService`), smart next-track prefetching, dan sanitasi metadata studio.

- [x] **28.1 YouTube Audio Streaming & Extraction Core (`YouTubeMusicService`)**
  - [x] Integrasi `youtube_explode_dart` untuk pencarian audio real-time dan ekstraksi Opus ~160kbps / AAC ~256kbps audio-only streams.
  - [x] Sanitasi cerdas judul video YouTube (`cleanMetadata` regex) untuk membersihkan noise `[Official Music Video]`, `(Lyrics)`, `VEVO`, `4K`, dan memisahkan *Artist - Title*.
  - [x] Ekstraksi playlist YouTube / YouTube Music (`getPlaylistTracks`) dan algoritma smart track radio (`getRelatedTracks`).
- [x] **28.2 C++ SoLoud Audio Engine & Disk Caching Pipeline**
  - [x] Integrasi pemutaran dinamis di `PlayerController` (`playTrack` & `_prefetchNextTrackInQueue`) untuk resolusi URL on-demand dan caching disk simultaneous (`${appDocDir}/audio_cache/yt_<videoId>.cache`).
  - [x] Dukungan pemutaran offline 0ms untuk trek YouTube yang telah di-cache.
  - [x] Pemrosesan 100% jalur sinyal audio melalui rantai DSP Mastering (Pro-Q 10-Band EQ, Tube Exciter, Compressor, Limiter, Auto-Headroom Protection).
- [x] **28.3 Material 3 Studio Discovery & Search Interface (`YouTubeDiscoveryScreen`)**
  - [x] Desain Material 3 Expressive Bento search interface dengan debounced search bar (400ms), clear button, dan filter chips (`All`, `Top 100 Charts`, `Audiophile Masters`, `Acoustic Live`, `Hi-Res Mixes`).
  - [x] Bento hero telemetry card menampilkan status jalur DSP SoLoud C++.
  - [x] Track tile studio lengkap dengan `StudioArtworkWidget`, format badge `OPUS`, tabular duration figures, tombol 1-tap start smart radio, dan integrasi penuh `StudioTrackActionSheet`.
  - [x] Modal import playlist YouTube & YouTube Music (`YouTubeImportPlaylistDialog`) dengan clipboard paste shortcut, "Add to Queue", dan "Play All".
- [x] **28.6 Dual-Touchpoint Synchronized Hub & Dashboard Showcase Integration (Opsi 1)**
  - [x] Floating Category Dock Library: Penambahan tab `CollectionTab.youtube` (`YouTube`) pada dock kategori bawah untuk navigasi 1-tap thumb switching.
  - [x] Quick Action Capsule Ribbon: Pita kapsul studio modern (`YOUTUBE MUSIC HIFI HUB • Explore ➔`) di bagian atas tampilan library tracks agar langsung terlihat seketika (100% immediate discovery). Mengetuk pita langsung beralih ke tab YouTube di dock.
  - [x] Embedded YouTube Music Hub di Library: Saat tab `CollectionTab.youtube` aktif di `UnifiedLibraryScreen`, tampilan pencarian & trending charts YouTube ter-embed secara seamless tanpa header ganda.
  - [x] Dashboard Hero Showcase Carousel: Penambahan showcase card interaktif `YouTube Music HiFi` (`OPUS 160K • DSP MASTER` dengan tombol aksi `[ DISCOVER ]`) pada `StudioHeroShowcaseCarousel` di Dashboard utama.
- [x] **28.7 Playback Buffering & Streaming Loading Spinner State**
  - [x] `PlaybackState`: Penambahan getter `isLoading` dan `isBuffering` berbasis `PlaybackStatus.loading`.
  - [x] `PlayerController`: Proteksi `togglePlayPause()` saat `state.isLoading` untuk mencegah duplicate request / race condition saat resolusi URL & audio buffering berlangsung.
  - [x] `NowPlayingScreen`: Tombol Play/Pause utama (potret dan lanskap) secara mulus menampilkan `CircularProgressIndicator` presisi Material 3 Expressive saat lagu sedang buffer/loading (`tooltip: 'Buffering...'`).
  - [x] `NamidaExpandableMiniPlayer`: Tombol lingkaran Play/Pause pada miniplayer bar bawah menampilkan `CircularProgressIndicator` (18px) saat lagu sedang buffer/loading.
  - [x] `StudioDeskDockingScreen`: Centerpiece Play/Pause raksasa menampilkan `CircularProgressIndicator` (32px / 30px) saat state buffering aktif.
  - [x] `TrackTile`, `_QueueTrackTile`, & `YouTubeDiscoveryScreen`: Overlay artwork dan leading indicator menampilkan spinner melingkar ketika track sedang di-buffer/di-stream.
  - [x] Detail Screens (`AlbumDetailScreen`, `ArtistDetailScreen`, `GenreDetailScreen`, `FolderDetailScreen`): Header Play All button dan track list item menampilkan spinner loading saat buffering.
- [x] **28.8 Audio Playback Output & Silent Audio Resolver**
  - [x] Resolusi audio output device: Penonaktifan audio device idle timeout (`setAudioDeviceIdleTimeout(null)`) pada `SoLoudController.init()` agar output hardware ALSA/AAudio/WASAPI tidak tertidur atau mati saat jeda antar-lagu.
  - [x] Deteksi dan pemulihan hardware audio: Penambahan listener `audioDeviceStartFailures` dan pengecekan `AudioDeviceState.stopped` pada `playFile` dan `playUrl` untuk otomatis menjalankan `startAudioDevice()`.
  - [x] Eliminasi volume fade inaudible: Penghapusan `fadeIn: 0.001` mute pada awal putar lagu baru, menjamin suara langsung terdengar penuh pada `targetVolume` (1.0).
  - [x] Bit-Perfect Flat Studio Profile: Penonaktifan limiter default pada `DspProfile.flatReference` (`limiterEnabled: false`) untuk transmisi audio murni bit-perfect zero-distortion ke DAC.
  - [x] Proteksi backend DSP: Penambahan guard `SoLoud.instance.isInitialized` di seluruh method aktivasi/deaktivasi DSP filter di `VirtualDspService`.
  - [x] Test Suite & Validation: Pembuatan test suite di `test/audio_playback_sound_output_test.dart` dan verifikasi kelulusan 100% (245/245 tests passing) dengan 0 errors & 0 warnings pada `flutter analyze`.





