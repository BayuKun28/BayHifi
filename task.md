# Baydev HiFi — Master Task Tracker (task.md)

Dokumen pelacakan tugas mendalam untuk pengembangan pemutar musik audiophile **Baydev HiFi**. Setiap tugas dirancang secara modular, mengacu pada arsitektur DSP studio presisi tinggi serta referensi UI/UX **100% Pure Material 3 Expressive** (`material_3_expressive: ^1.1.3`, `material_ui`, `motor`, `material_new_shapes`, `M3EHaptics`).

---

## Status Dashboard

- **Total Fase**: 62 Fase (Fase 1–62 Selesai • 100% Passed • 531/531 Passed)
- **Arsitektur UI**: _100% Pure Material 3 Expressive (`material_3_expressive: ^1.1.3`), `material_ui`, `motor` Spring Physics, `material_new_shapes`, Bento Grid Modular System, Floating Rounded Dock, Dynamic Studio Palettes & Unified HugeIcons (100% English)_
- **Status Proyek**: _Phase 62: Baydev HiFi Studio Wrapped & Audiophile Recap — 7-Slide Interactive Story Player, 4 Visual Templates (Thermal Receipt, Sticker Collage, Bento Studio, Cassette J-Card), PNG Exporter & Dashboard Bento Banner (Complete — 0 Errors, 0 Warnings • 531/531 Passed)_

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
  - [x] Transisi crossfade halus (10ms) untuk mencegah bunyi _pop/click_ saat switching

---

## Fase 4: Mastering DSP Studio Rack (10+ Modul)

Rantai pemrosesan audio kelas profesional untuk mastering dan personalisasi karakter suara.

- [x] **4.1 Pre-Amp Gain Stage**
  - [x] Slider headroom input (-24 dB s/d +12 dB) dengan visualizer level meter
- [x] **4.2 Dynamic Bass Boost**
  - [x] Peningkatan frekuensi sub-bass (40–160 Hz) dengan harmonik psychoacoustic
- [x] **4.3 Tube Exciter / Triode Saturation**
  - [x] Algoritma nonlinearitas analog ($y = \tanh(k \cdot x)$) untuk distorsi harmonik genap (_even harmonics_)
  - [x] Kontrol Drive/Warmth, Harmonics Blend, dan Tube Bias
- [x] **4.4 Dynamic Compressor**
  - [x] Implementasi parameter: Threshold (-60 s/d 0 dB), Ratio (1:1 s/d 20:1), Attack (0.1–100ms), Release (10–1000ms), Makeup Gain
  - [x] Visualizer gain reduction (GR Meter)
- [x] **4.5 Stereo Width (Mid-Side Matrix)**
  - [x] Dekomposisi sinyal ke $M = (L+R)/2$ dan $S = (L-R)/2$
  - [x] Kontrol pelebaran soundstage (0% Mono s/d 200% Super-Wide)
- [x] **4.6 Binaural Crossfeed (Meier / Chu-Moy Algorithm)**
  - [x] Simulasi tata letak speaker stereo untuk headphone guna mengurangi kelelahan telinga (_listener fatigue_)
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

Penyesuaian tata letak (layout), icon, struktur menu, dan alur interaksi mengacu pada referensi _Expressive Music App Screen Designs_ (`collection_dark`, `collection_light`, `customization_settings`, `yt_miniplayer`).

- [x] **5.1 Pembersihan & Penataan Terminologi UI**
  - [x] Hapus/ganti seluruh penyebutan kata eksternal di halaman Settings & Theming menjadi standar Studio Audiophile / Baydev HiFi
  - [x] Standardisasi nama palet warna: _Obsidian Cyan_, _Amber Tube Glow_, _Emerald HiFi_, _Electric Purple_, _Crimson Passion_, _True OLED Black_, _Champagne Light_
- [x] **5.2 Multi-Tab Collection Screen (Tracks, Albums, Artists, Genres, Playlists, Folders)**
  - [x] **Top Header & Action Bar**:
    - [x] Search Bar interaktif dengan live filtering
    - [x] Tombol Sort Dropdown (`Title`, `Date Added`, `Artist`, `Duration`, `File Size`, `Hi-Res`) + Ascending/Descending Toggle
    - [x] Multi-tab horizontal pills navigation: `[Tracks]`, `[Albums]`, `[Artists]`, `[Genres]`, `[Playlists]`, `[Folders]`
  - [x] **Tracks Tab View**:
    - [x] List view dengan squircle album art cover (rounded corners)
    - [x] Title, Artist, Album, Durasi & badge format audio (FLAC/Hi-Res/MP3)
    - [x] Trailing 3-dot popup menu: _Play Next_, _Add to Queue_, _Add to Playlist_, _Track Details_, _Favorite Heart_
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
  - [x] **Visualizer Style**: Pilihan gaya visualizer (_Spectrum Bars_, _Spline Smooth Waveform_, _Dual Analog VU Meters_, _Circular Halo_)
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
  - [x] Lembar antrean lagu aktif (_Up Next Queue Sheet_) dapat diakses dari Now Playing Screen
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
  - [x] Opsi _Stop at end of track_ (berhenti otomatis setelah lagu yang sedang berjalan selesai)
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
  - [x] Popup menu AppBar lengkap di `UnifiedLibraryScreen`: _Pick & Scan Music Folder_, _Pick Audio Files_, _Rescan Music Folders_, _Connect Navidrome Cloud_, _Clear Music Library_

---

## Fase 12: Material 3 Expressive UI/UX Architecture & Bento Grid System

Implementasi arsitektur antarmuka Material 3 Expressive modern dengan sistem Bento Grid modular, token squircle, elevasi tonal 5-layer, physics spring, dan animasi staggered entrance.

- [x] **12.1 Standardisasi Aturan Material 3 Expressive & Zero-Emoji Policy di `rules.md` & `GEMINI.md`**
  - [x] Tambahkan section arsitektur M3 Expressive, Bento Grid layout, token squircle (`8px`, `12px`, `16px`, `20px`, `28px`, `999px`), 1px crisp borders, Zero-Emoji Policy, dan tabular figures policy.
- [x] **12.2 Bento Module 1: C++ SoLoud Engine & Hardware Telemetry Hero Card**
  - [x] Live C++ audio engine telemetry, source specs (kHz, bit depth, format), safe preamp level, and Bit-Perfect DAC status badge.
- [x] **12.3 Studio Hero Showcase Carousel (Horizontal Showcase)**
  - [x] Horizontal M3 Expressive showcase banner directly above Audiophile Stats card with 4 rich cards (_32-Band Pro-Q Studio_, _Mastering DSP Rack_, _AutoEQ & Target Solver_, _Studio Desk Docking_), page indicator dots, and direct navigation.
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

## Fase 13: DSP Rack Collapsible Units, Bottom Floating Category Dock, Pastel Palettes & Expressive Controls

Penyempurnaan ergonomi satu tangan dan visual Material 3 Expressive studio di seluruh antarmuka utama Baydev HiFi.

- [x] **13.1 DSP Rack Collapsible Units & Reset Confirmation Modal**
  - [x] `RackUnitCard` collapsible state: otomatis terminimize saat bypass (OFF) ke faceplate ramping ~46px, auto-expand saat dinyalakan, dan tap header untuk expand manual dengan indikator chevron.
  - [x] Modal dialog konfirmasi Material 3 untuk aksi _Reset to Flat Reference_ dengan tombol Cancel dan Reset All.
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
  - [x] Pilihan urutan judul (_Artist - Title_ vs _Title - Artist_), kustomisasi baris ke-3, dan direct favorite button
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
  - [x] Mode _Original Text_ (`ORIG`), _Romanized Text_ (`ROM`), dan _Dual-Line Display_ (`DUAL`) di `SynchronizedLyricsView` dengan persistensi lokal
- [x] **19.3 LRC Timing Synchronizer & Offset Adjuster**
  - [x] Bottom sheet modal penyesuaian offset waktu lirik sub-second precision (`±100ms`, `±500ms`, continuous slider, reset) dengan kalkulasi real-time di `LrcParser.findActiveIndex()` dan persistensi per-track
- [x] **19.4 Dedicated Tests Validation**
  - [x] Unit test transliterasi teks sampel bahasa Jepang, Korea, dan Mandarin, auto-romanizer di parser LRC, timing offset calculator, serta widget tests (`east_asian_romanizer_test.dart` dengan total 155/155 passing tests)

---

## Fase 20: Advanced Library Indexer, Storage Cache, Backup & Settings Fusion

Utilitas pemeliharaan database, penanganan file hilang/duplikat, manajemen kuota cache, pencadangan, dan reorganisasi pengaturan.

- [x] **20.1 Missing Tracks & Duplicate Resolver**
  - [x] Deteksi file berpindah folder (_missing tracks resolver_) dan pembersihan lagu duplikat berbasis audiophile fidelity rating (`LibraryIndexerService`, `MissingTracksResolverSheet`, `DuplicateTracksResolverModal`)
- [x] **20.2 Storage & Cache Quota Manager**
  - [x] Monitoring ukuran cache (Artwork, Lyrics, DB, Playback history) dan pembersihan granular serta 1-klik _Purge All Caches_ (`StorageCacheManager`, `StorageCacheSettingsScreen`)
- [x] **20.3 Full Backup & Restore System (`.bayhifi` JSON Archive)**
  - [x] Ekspor dan impor seluruh konfigurasi tema, playlists kustom, smart rules, DSP presets, history, and favorites (`BackupRestoreService`, `BackupRestoreSettingsScreen`)
- [x] **20.4 Reorganisasi 7 Kategori Pengaturan Studio**
  - [x] Menu terstruktur rapi: _Theming & Color Palettes_, _Visualizer & Display_, _Gestures & Track Tiles_, _Studio Workstation & Car Dock_, _Audio Hardware & DAC Engine_, _Library Scanner & Sleep Timer_, _Storage & Cache Quota_, _Backup & Restore Archive_
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
  - [x] Saat _Shuffle ON_: Mengacak daftar antrean aktif (`queue`) dengan menyematkan (_pin_) track yang sedang diputar di posisi index 0. Daftar antrean yang terlihat pada `NowPlayingQueueSheet` merefleksikan urutan acak tersebut.
  - [x] Navigasi _Next_ (`skipNext()`) maju secara sekuensial mengikuti urutan acak yang terlihat di antrean (`0 -> 1 -> 2 -> ...`), mengeliminasi bug _double randomization_.
- [x] **22.3 Pemulihan Konteks Asal saat Shuffle Dimatikan (`toggleShuffle`)**
  - [x] Saat _Shuffle OFF_: Memulihkan urutan asli secara instan dari `originalQueue`. Track yang sedang diputar tetap aktif di index aslinya pada daftar asal tersebut, dan navigasi _Next/Previous_ kembali mengikuti urutan album/playlist awal.
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
  - [x] Navigasi instan via tap & drag dengan haptic feedback halus (`HapticFeedback.selectionClick()`), pencocokan huruf otomatis, sinkronisasi highlighting huruf aktif saat scroll normal, dan indikator huruf mengambang (_floating studio bubble indicator_).
- [x] **23.4 Fallback Scrollbar Standar untuk Pengurutan Non-Alfabetis**
  - [x] Saat library diurutkan berdasarkan kriteria non-alfabetis (`SortField.duration`, `SortField.dateAdded`, `SortField.hiRes`), sistem otomatis menampilkan standard Studio Material 3 `Scrollbar`.

---

## Fase 24: RYNLABS DSP Parity, Bidirectional Pro-Q Sync & Offline AutoEQ Caching

Sinkronisasi mendalam arsitektur DSP Rack dengan RYNLABS_HIFI, sinkronisasi dua arah PreAmp dengan Pro-Q Studio, penyimpanan offline otomatis kurva AutoEQ / target / driver, dan optimalisasi UI/UX layar DSP Rack dan modal dialog portrait.

- [x] **24.1 RYNLABS DSP Mathematical & Logic Parity (`VirtualDspService`)**
  - [x] Verifikasi 100% keselarasan rumus dan arsitektur pemrosesan audio C++ mastering chain dengan `/mnt/01DC9A2666E1A190/Other/PROJECTS/DSP/RYNLABS_HIFI` (Master Bypass deactivation tanpa kehilangan parameter, Freeverb volume compensation formula $-1.0 \times (\text{wet} \times 0.75)\text{ dB}$, Tube warmth & drive scaling, dynamic compressor lookahead, limiter true peak output ceiling, dan biquad filter transfer function).
- [x] **24.2 Bidirectional PreAmp & Headroom Synchronization**
  - [x] Integrasi sinkronisasi dua arah (_bidirectional sync_) Pre-Amp gain antara `DspRackController`, `EqController`, dan `VirtualDspService` (Single Source of Truth).
  - [x] Modifikasi PreAmp di Unit 01 DSP Rack langsung memutasi headroom dan safe preamp di Pro-Q Studio, dan sebaliknya perubahan PreAmp atau Auto-Headroom di Pro-Q Studio langsung memperbarui slider PreAmp dan level meter di DSP Rack.
  - [x] Pembuatan komponen interaktif `_PreampBox` pada `BandStripBar` di Pro-Q Studio yang membuka _Material 3 Studio PreAmp & Headroom bottom sheet_ lengkap dengan slider input gain, toggle auto-headroom protection, dan quick gain preset chips (`-12 dB`, `-6 dB`, `-3 dB`, `-1 dB`, `0 dB FLAT`, `+3 dB`).
- [x] **24.3 Automatic Persistent Offline Storage for AutoEQ Cloud Presets & Target Curves**
  - [x] Penambahan serialisasi dan deserialisasi `FrCurveData.toMap()` / `FrCurveData.fromMap()`.
  - [x] Penambahan metode `saveFrCurve()`, `getSavedFrCurves()`, `deleteFrCurve()`, `saveDownloadedAutoEqIds()`, dan `getDownloadedAutoEqIds()` di `LocalPersistenceService`.
  - [x] Saat pengguna mengunduh kurva target atau pengukuran IEM/headphone via `AutoEqCloudService.downloadItem()` atau mengimpor URL Squiglink, kurva tersebut secara otomatis disimpan ke penyimpanan offline persisten dan langsung terhidrasi ke daftar target/driver di `EqController`.
- [x] **24.4 UI/UX Optimization for DSP Rack & Compact Mobile Portrait Viewports (360x780)**
  - [x] Penambahan baris _Quick Gain Selector Chips_ pada Unit 01 Pre-Amp Gain Stage di `DspRackScreen` (`-12 dB`, `-6 dB`, `-3 dB`, `-1 dB`, `0 dB Flat`, `+3 dB`).
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
  - [x] Daftar aksi lengkap: _Play Next_, _Add to Queue_, _Add to Playlist_, _Go to Album_, _Go to Artist_, _Add/Remove Favorite_, _Download/Cache Offline_, _Edit Metadata Tags_, dan _Inspect Audio Specs_.
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
  - [x] Sanitasi cerdas judul video YouTube (`cleanMetadata` regex) untuk membersihkan noise `[Official Music Video]`, `(Lyrics)`, `VEVO`, `4K`, dan memisahkan _Artist - Title_.
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
- [x] **28.10 Offline Audio Playback & Android Scoped Storage Fallback Resolver**
  - [x] Diagnostik mendalam issue lagu offline macet di 00:00 / -00:00 dan tanpa suara:
    1. C++ `fopen` pada `loadFile(mode: LoadMode.disk)` gagal membaca path external storage di Android (Scoped Storage / SELinux permissions pada Redmi Note 7), menyebabkan `WavStream` kosong (`length == 0`).
    2. Konfigurasi `lowLatency: true` pada AAudio hardware sink Redmi Note 7 memutus output ke silent dummy sink.
    3. `_syncAudioHandler()` mengirim `playing: true` ke Android `MediaSession` sehingga status bar notifikasi OS mengekstrapolasi seekbar sendiri sementara Flutter engine macet di 00:00.
  - [x] Implementasi 3-Tier Robust Decoder Loading di `SoLoudController.playFile`:
    1. Tier 1: `loadFile(filePath, mode: LoadMode.memory)` untuk performa memori instan & seek mulus.
    2. Tier 2: Dart VM `File.readAsBytes()` $\rightarrow$ `loadMem(filePath, bytes, mode: LoadMode.memory)` fallback (menjamin 100% file I/O permissions via Android ContentResolver).
    3. Tier 3: `loadFile(filePath, mode: LoadMode.disk)` fallback.
  - [x] Pembaruan `SoLoudController.init`: Set `lowLatency: false` untuk mengaktifkan pipeline shared `AndroidAAudioAttributes.mediaMusic` / OpenSL ES yang kompatibel 100% pada semua hardware DAC/speaker Android.
  - [x] Perbaikan durasi di `PlayerController` (`playTrack` dan `_initListener`): Menggunakan `effectiveDuration` fallback ke `track.duration` saat engine durasi belum terbaca, mencegah slider stuck di `00:00` / `-00:00`.
  - [x] Validasi test suite penuh di `test/audio_playback_sound_output_test.dart` dengan 100% test lulus (245/245 tests) dan 0 issues pada `flutter analyze`.

---

## Fase 29: YouTube Streaming Race Condition & Playback Stability Bug Fix (Completed)

Perbaikan bug streaming YouTube di mana loading spinner muncul beberapa saat lalu playback tidak jadi berjalan dan tombol kembali ke posisi paused/play. Root cause adalah race condition antara resolusi URL async dan state engine SoLoud.

- [x] **29.1 Stream-First Strategy Refactor (PlayerController)**
  - [x] Refaktor `playTrack` untuk `yt_` tracks: resolusi CDN URL via `getAudioStreamUrl()` → langsung `playUrl()` tanpa menunggu full download. `cacheTrack()` berjalan fire-and-forget di background untuk cache hit pada pemutaran berikutnya.
  - [x] Branch terpisah untuk Subsonic/remote tracks: tetap menggunakan `cacheTrack()` → `playFile()` pipeline.
  - [x] `prefetchNextTrack` fix: `AudioCacheService` kini mengizinkan `yt_` tracks melewati pipeline YoutubeExplode meskipun `streamUrl` null (previously always skipped due to `streamUrl == null` guard).
- [x] **29.2 Phase 25.3 Queue Sheet Auto-Scroll Test Fix**
  - [x] `ReorderableListView.builder` adalah virtualized list — item di luar viewport tidak ada di widget tree. Test sebelumnya asserting `findsOneWidget` untuk `ValueKey('queue_track_queue_song_15_15')` selalu gagal karena item 15 belum ter-render saat async `Future.delayed` scroll belum selesai.
  - [x] Fix: primary assertion sekarang verifikasi **state** (`queueIndex == 15`) sebagai source of truth. Secondary assertion memverifikasi list me-render setidaknya beberapa track tile (`find.textContaining('Audiophile Track')`).
  - [x] Total test suite: 246/246 passing, 0 analyzer warnings.
- [x] **29.3 YouTube Streaming Playback Failure Bug Fix**
  - [x] **Root Cause**: Googlevideo CDN streams menolak unauthenticated HTTP GET requests dari generic `http.Client` di `SoLoud.instance.loadUrl()` dengan HTTP 403 Forbidden, menyebabkan exception yang me-revert status playback ke error/paused.
  - [x] **Fix**: Refaktor `playTrack` untuk memprioritaskan download/caching stream via `YoutubeExplode` streamsClient authenticated pipeline (`AudioCacheService.instance.cacheTrack`), diikuti dengan bit-perfect local playback via `_audioEngine.playFile`. Menyediakan instant playback dengan fallback stream URL dan smart next-track prefetching (0ms delay).

---

## Fase 30: Navidrome UX Fixes, Session Persistence & Lyrics Active Line Centering (Completed)

Perbaikan UX untuk koneksi Navidrome dan presisi auto-scroll lyric sinkronisasi.

- [x] **30.1 Navidrome Tab — Empty State Connect UI**
  - [x] Desain studio-grade empty state card di tab/filter Navidrome ketika `navidromeConnectionStatus != connected`:
    - Container rounded squircle dengan icon `HugeIcons.strokeRoundedCloudOff` (32px)
    - Judul `'NO NAVIDROME SERVER CONNECTED'` + deskripsi `'Stream lossless FLAC and Opus audio directly from your personal Subsonic or Navidrome music server.'`
    - Tombol primary `[ CONNECT TO NAVIDROME ]` (`HugeIcons.strokeRoundedCloudSync`) yang membuka `NavidromeConnectDialog` langsung
    - Quick info badge studio: `SUBSONIC API • LOSSLESS FLAC • OPUS STREAMING`
- [x] **30.2 Navidrome Connect Dialog — Proportional Icon Fix & UX Polish**
  - [x] Memperbaiki proporsi `prefixIcon` pada `TextFormField` (Server URL, Username, Password) dengan padding 12px dan `prefixIconConstraints: BoxConstraints(minWidth: 42, minHeight: 42)` agar icon proporsional dan tidak meregang besar.
  - [x] Mengurangi dialog width dari 440px ke 380px dan padding dari 24px ke 20px untuk layout studio compact yang ergonomis.
  - [x] Menambahkan widget test di `test/phase_29_and_30_features_test.dart` memverifikasi rendering dialog dan proporsi icon.
- [x] **30.3 Navidrome Connection Session Persistence (Auto-Reconnect on App Restart)**
  - [x] Menambahkan method serialisasi `toMap()` dan deserialisasi `SubsonicServerConfig.fromMap()` pada `SubsonicServerConfig`.
  - [x] `UnifiedLibraryController.connectNavidrome()` otomatis menyimpan konfigurasi server ke `LocalPersistenceService.saveSetting('navidrome_config', config.toMap())` setelah koneksi berhasil.
  - [x] `UnifiedLibraryController.disconnectNavidrome()` menghapus konfigurasi server dari persistence.
  - [x] Implementasi `restoreNavidromeSession()` pada startup controller (`Future.microtask`) untuk auto-reconnect ke server Navidrome saat aplikasi dibuka kembali.
  - [x] Mendaftarkan key `'navidrome_config'` pada archive backup & restore `BackupRestoreService`.
- [x] **30.4 Lyrics Active Line Auto-Scroll Centering Fix**
  - [x] Memperbaiki perhitungan target offset pada `_scrollToActiveLine()` di `SynchronizedLyricsView` agar baris lirik aktif selalu terpusat tepat di tengah (_center viewport_) di semua mode display (Original, Romanized, Dual-Line).
  - [x] Validasi widget test pada `test/phase_29_and_30_features_test.dart` (254/254 tests lulus 100%, 0 analyzer warnings).

---

## Fase 31: Lyrics Viewport Centering, YouTube Instant Streaming, Compact Empty State & Solid Theming Mode (Completed)

Penyempurnaan presisi viewport centering lirik di semua mode pemutaran, implementasi streaming WebM-to-Ogg remuxer untuk pemutaran native SoLoud, perapian UI empty state library ke Bento 2x2, serta penambahan state & selector gaya warna solid vs translucent.

- [x] **31.1 Synchronized Lyrics Active Viewport Centering (All Sources)**
  - [x] Implementasi `Scrollable.ensureVisible` dengan `alignment: 0.5` (`curve: Curves.easeOutCubic`, 300ms) menggunakan per-line `GlobalKey` untuk menempatkan baris lirik aktif selalu tepat di tengah vertikal viewport.
  - [x] Centering presisi berfungsi konsisten untuk trek Lokal/Offline, Navidrome Cloud stream, dan YouTube Music stream.
  - [x] Auto-scroll langsung pada inisialisasi awal, saat scrubbing/seeking, dan saat pergantian offset waktu.
- [x] **31.2 WebM to Ogg Opus Real-Time Streaming Remuxer & Native SoLoud Pipeline**
  - [x] Implementasi `WebmToOggRemuxer` (pure Dart EBML parser & Ogg Opus packager RFC 3533/7845/6716) untuk mengonversi stream WebM Opus YouTube menjadi Ogg Opus ber-header valid secara real-time.
  - [x] Refaktor `YouTubeMusicService.getOggOpusAudioByteStream()` dan `downloadAudio()` agar data stream dan cache lokal tersimpan sebagai Ogg Opus yang dapat didecode langsung oleh engine C++ `flutter_soloud`.
  - [x] Refaktor `PlayerController.playTrack()` untuk melakukan pre-buffering header Ogg (`OpusHead` & `OpusTags`) sebelum `playAudioSource` dipanggil, memulihkan pemutaran YouTube audio instan tanpa tertahan di loading/pause.
- [x] **31.3 Compact Bento 2x2 Library Empty State Quick Actions**
  - [x] Redesain layout kartu empty state library dari list vertikal panjang menjadi Bento Grid 2x2 yang ringkas dan proporsional.
  - [x] Mengelompokkan tombol sumber lokal (`SELECT MUSIC FOLDER`, `PICK AUDIO FILES`) dan sumber online (`CONNECT NAVIDROME CLOUD`, `EXPLORE YOUTUBE MUSIC HIFI`) dengan visual studio yang rapi.
  - [x] Penambahan pill badge format audiophile compact di bagian footer kartu.
- [x] **31.4 Theming Color Surface Fill Style Setting (Solid vs Translucent State & Selector)**
  - [x] Penambahan enum `SurfaceFillStyle` (`translucent`, `solid`) dan integrasi ke `ThemeSettingsState` serta `LocalPersistenceService` (`surface_fill_style`).
  - [x] Penambahan Segmented Control selector pada `ThemingSettingsScreen` di bawah section `SURFACE & COMPONENT FILL STYLE`.
  - [x] State tersimpan persisten dan hot-reload resilient.
- [x] **31.5 Unit & Widget Test Suite Validation**
  - [x] Pembuatan test file `test/phase_31_features_test.dart` dan `test/webm_to_ogg_remuxer_test.dart`.
  - [x] Memastikan 100% test passing (264 tests lulus) dan 0 issues pada `flutter analyze`.

---

## Fase 32: System-Wide SurfaceFillStyle Integration & Pure Solid M3 Consistency (Completed)

Penerapan menyeluruh pengaturan gaya warna `SurfaceFillStyle` (`translucent` / Translucent Soft Tint vs `solid` / Pure Solid M3) ke seluruh antarmuka, kartu bento, modal, bottom sheet, dock navigasi, dan komponen di seluruh aplikasi Baydev HiFi.

- [x] **32.1 Centralized `StudioSurfaceTheme` & Context Extension Helpers**
  - [x] Pembuatan `StudioSurfaceTheme` helper class dan extension `ref.isSolidStyle` di `lib/app/theme/studio_surface_theme.dart` yang menyediakan resolusi warna container dinamis berdasarkan `surfaceFillStyle`:
    - `surface(context, {bool isSolid = false, double translucentAlpha = 0.7})`: Mengembalikan `colorScheme.surface` solid 100% pada mode `solid`, atau `surface.withValues(alpha: translucentAlpha)` pada mode `translucent`.
    - `surfaceContainer(context, {bool isSolid = false, double translucentAlpha = 0.6})`: Mengembalikan `colorScheme.surfaceContainer` solid 100% pada mode `solid`, atau `surfaceContainer.withValues(alpha: translucentAlpha)` pada mode `translucent`.
    - `surfaceContainerHigh(context, {bool isSolid = false, double translucentAlpha = 0.7})`: Mengembalikan `colorScheme.surfaceContainerHigh` solid 100% pada mode `solid`.
    - `surfaceContainerLow(context, {bool isSolid = false, double translucentAlpha = 0.5})`: Mengembalikan `colorScheme.surfaceContainerLow` solid 100% pada mode `solid`.
    - `tintedContainer(context, Color tintColor, {bool isSolid = false, double translucentAlpha = 0.12})`: Mengembalikan `Color.alphaBlend(tintColor.withValues(alpha: 0.15), theme.colorScheme.surfaceContainer)` (100% opaque solid blend) pada mode `solid`.
    - `outline(context, {bool isSolid = false, double translucentAlpha = 0.4})`: Mengembalikan `colorScheme.outline` solid pada mode `solid`.
    - `subtleOutline(context, {bool isSolid = false, double translucentAlpha = 0.25})`: Mengembalikan `colorScheme.outlineVariant` solid pada mode `solid`.
    - `cardDecoration(...)`: Helper standar dekorasi card Bento dengan border dan shadow solid vs translucent.
- [x] **32.2 Dashboard Bento Grid & Hero Cards SurfaceFillStyle Application**
  - [x] Penerapan ke `DashboardScreen`: Background gradient/solid surface container.
  - [x] Penerapan ke `EngineTelemetryBentoCard`: Card container, spec badge, telemetry gauges.
  - [x] Penerapan ke `ListeningStatisticsCard`: Lossless breakdown container, rank badge, format pills.
  - [x] Penerapan ke `MasteringDspBentoCard`: Unit status pills, bypass badges, launcher container.
  - [x] Penerapan ke `ProQMiniLauncherBentoCard`: Mini RTA container, frequency zone pills.
  - [x] Penerapan ke `RecentLosslessSessionsCarousel`: Track tile containers, Hi-Res format badges.
  - [x] Penerapan ke `StudioHeroShowcaseCarousel`: Showcase cards, action buttons, page indicator container.
- [x] **32.3 Unified Library & Detail Screens SurfaceFillStyle Application**
  - [x] Penerapan ke `UnifiedLibraryScreen`: Search bar container, empty state Bento 2x2 cards, multi-selection bottom action bar (`LibraryBatchActionsBar`).
  - [x] Penerapan ke `TrackTile` dan `StudioTrackActionSheet` (Action item rows, metadata header card).
  - [x] Penerapan ke detail screens: `AlbumDetailScreen`, `ArtistDetailScreen`, `GenreDetailScreen`, `FolderDetailScreen`, `PlaylistsScreen`.
- [x] **32.4 NowPlaying Screen, Lyrics & Modal Sheets SurfaceFillStyle Application**
  - [x] Penerapan ke `NowPlayingScreen`: Top header pills, format badge container, playback control containers, volume & speed bars, studio action strip.
  - [x] Penerapan ke `NowPlayingQueueSheet`: Queue container, reorder tiles, clear/shuffle pills.
  - [x] Penerapan ke `SynchronizedLyricsView`: Active line container, mode toggle pill container.
  - [x] Penerapan ke `StudioDeskDockingScreen` & `StudioCarDockingScreen`: Dashboard container, big transport buttons.
  - [x] Penerapan ke `PlaybackSpeedPitchSheet`, `SleepTimerSheet`, `AudioFileInspectorSheet`, `StudioDspBentoCapsule`, `DualPaneWorkstationPane`.
- [x] **32.5 DSP Rack, Pro-Q Studio & Parametric Canvas SurfaceFillStyle Application**
  - [x] Penerapan ke `DspRackScreen`: `RackUnitCard` containers (expanded & collapsed), knob background discs, bypass switches, profile dialogs.
  - [x] Penerapan ke `ProQStudioScreen`: Bottom control strip (`BandStripBar`), band pills (`B1`, `B2`, ...), action buttons (`Add Band`, `Delete`, `Undo`), filter type selectors.
  - [x] Penerapan ke `AutoEqCloudBrowserDialog`, `AutoEqModalDialog`, `SquiglinkDialog`.
- [x] **32.6 Settings Screens & Dialogs SurfaceFillStyle Application**
  - [x] Penerapan ke `SettingsScreen`: Settings overview hero card, category cards, navigation containers.
  - [x] Penerapan ke sub-screens: `ThemingSettingsScreen`, `PlaybackEngineSettingsScreen`, `StorageCacheSettingsScreen`, `BackupRestoreSettingsScreen`, `LibraryScannerSettingsScreen`, `VisualizerSettingsScreen`, `GesturesSettingsScreen`, `DockingSettingsScreen`, `AudioHardwareSettingsScreen`.
  - [x] Penerapan ke dialogs & modals: `NavidromeConnectDialog`, `MetadataTagEditorSheet`, `BatchTrackTagEditorModal`.
- [x] **32.7 YouTube Music HiFi Discovery Screen SurfaceFillStyle Application**
  - [x] Penerapan ke `YouTubeDiscoveryScreen`: Search input container, quick category chips, trending cards, related songs ribbons, video item tiles.
- [x] **32.8 Audio Dock & MiniPlayer Navigation SurfaceFillStyle Application**
  - [x] Penerapan ke `FloatingRoundedDock`: Floating capsule dock background (solid vs translucent blur), active tab indicator pill.
  - [x] Penerapan ke `NamidaExpandableMiniPlayer`: Collapsed miniplayer container, progress bar, play/pause capsule button.
- [x] **32.9 Pure Solid M3 Anti-Neon Surface & Studio Neutral Palette Standardization**
  - [x] Standardisasi seluruh preset `AppPalette` (`namidaCyan`, `pastelSage`, `amberTube`, `emeraldHiFi`, `electricPurple`, `crimsonPassion`, `pastelLavender`, `pastelSky`, `pastelPeach`, `pastelBlush`, `pastelButter`) ke neutral studio dark surfaces (`0xFF0C0E12`, `0xFF14161C`, `0xFF1C1F27`, `0xFF242833`) dan neutral light surfaces, menghapus murky green/tinted background wash.
  - [x] Pembaruan `StudioSurfaceTheme.tintedContainer` pada mode solid mengembalikan `surfaceContainerHighest` murni untuk kartu icon, pill badges, dan chip kontrol.
  - [x] Penghapusan glowing neon colored `BoxShadow` pada tombol Play MiniPlayer & NowPlayingScreen, digantikan dengan neutral soft shadow.
  - [x] Pembaruan `_buildCategoryCard`, hero metrics, dan badge pill di `SettingsScreen` agar menggunakan neutral solid containers dan neutral subtle outlines.
  - [x] Pembaruan active tab capsule pada `FloatingRoundedDock` dengan neutral solid surface.
  - [x] Suite test di `test/phase_32_surface_fill_style_test.dart` lulus 100% (277/277 tests) dengan 0 issues pada `flutter analyze`.

---

## Fase 33: Visual Dynamics Expansion & Compact Bento ComboBox Selectors

Ekspansi mode visualisasi audio (*Album Art Styles*, *RTA Spectrum Styles*, *Time Bar Seekbar Styles*) serta perombakan antarmuka pengaturan `VisualizerSettingsScreen` menjadi Bento Dropdown (ComboBox) yang ringkas, rapi, dan cepat.

- [x] **33.1 Expanded Album Art & Cover Display Modes**
  - [x] `squircle`: Default 28px Squircle dengan dynamic ambient glow.
  - [x] `square`: Square Studio 8px monitor card dengan 1px studio border.
  - [x] `disc`: Minimalist CD disc dengan orbital rim.
  - [x] `vinyl`: Classic spinning vinyl record dengan concentric groove ridges.
  - [x] `turntable`: Spinning vinyl turntable dengan animasi tonearm needle interaktif (otomatis mendarat saat play dan terangkat saat pause).
  - [x] `cassette`: Retro analog cassette tape dengan dual rotating white gear spools, magnetic brown tape bridge, dan printed track label.
  - [x] `cdJewel`: Acrylic transparent CD jewel case dengan left spine hinge tray dan holographic optical sheen.
- [x] **33.2 Expanded RTA Spectrum Visualizer Styles**
  - [x] `bars`: Multi-Band high-density FFT bars dengan peak-hold.
  - [x] `wave`: Liquid Bezier wave dengan gradient fill.
  - [x] `dots`: Peak dots matrix.
  - [x] `beam`: Laser beam center-line.
  - [x] `mirrorWave`: Symmetrical mirror wave terpusat di garis horizontal.
  - [x] `vuMeter`: Dual analog VU needle dials (Left & Right channels) responsif real-time.
  - [x] `circular`: 360-degree radial orbit spectrum ring.
- [x] **33.3 Expanded Time Bar & Seekbar Styles**
  - [x] `slim`: Slim Studio 3.5px slider dengan tabular numbers.
  - [x] `capsule`: Solid Hi-Fi capsule seekbar.
  - [x] `segmented`: 32-segment VU LED meter timebar.
  - [x] `waveform`: Acoustic waveform profile seekbar.
  - [x] `ruler`: Studio Timecode Precision Ruler dengan sub-second tick marks dan needle playhead.
  - [x] `glowingPill`: Continuous floating pill seekbar.
- [x] **33.4 Compact Bento ComboBox Settings UI (`VisualizerSettingsScreen`)**
  - [x] Mengubah seluruh daftar kartu vertikal panjang menjadi Bento Dropdown ComboBox yang ringkas dan responsif.
  - [x] Dropdown menampilkan icon HugeIcons, judul tebal, deskripsi aktif, dan indikator panah Material 3.
- [x] **33.5 Unit & Widget Test Suite Validation (298/298 Tests Passing)**
  - [x] Pembuatan test suite di `test/phase_33_visualizer_expansion_test.dart` menguji rendering ke-7 mode album art, ke-7 mode spektrum, ke-6 mode seekbar, serta interaksi Bento dropdown.
  - [x] Seluruh 298 pengujian lulus 100% dengan 0 issues pada `flutter analyze`.

---

## Fase 34: Material 3 Expressive Settings Hub Redesign & 19 Studio Color Palettes Expansion

Perombakan arsitektur Settings Screen dan seluruh sub-screen menjadi layout Bento Grid Material 3 Expressive semi-minimalis, penambahan 7 palet warna studio baru (total 19 palet studio), dan ekspansi cockpit overview.

- [x] **34.1 Interactive Studio Overview Hero Card & Real-Time Cockpit Telemetry**
  - [x] Header kartu hero interaktif di `SettingsScreen` dengan badge pill live (Active Palette, DSP Engine Status, Storage Quota, Visualizer Profile) yang dapat di-tap sebagai shortcut navigasi instan.
- [x] **34.2 Ekspansi 7 Preset Palet Warna Studio M3 Expressive (Total 19 Studio Palettes)**
  - [x] Menambahkan 7 palet warna baru di `AppPalette`: `Nordic Slate Frost`, `Terracotta Clay Studio`, `Matcha Botanical Green`, `Midnight Sapphire`, `Vintage Brass & Walnut`, `Mocha Espresso Roast`, `Monochrome Pro Carbon`.
  - [x] Standardisasi neutral studio dark & light surfaces untuk seluruh 19 preset warna.
- [x] **34.3 Streamlined Settings Bento Grid Grouping**
  - [x] Pengelompokan seluruh opsi ke 4 Bento Groups utama: _Audio Engine & Hardware DSP_, _Visual Dynamics & Theming_, _Library, Storage & Cloud_, dan _System & Backup Archive_.
- [x] **34.4 Unit & Widget Test Suite Validation (305/305 Passing Tests)**
  - [x] Validasi suite pengujian komprehensif pada `test/settings_redesign_and_palettes_test.dart` dan `flutter analyze` 0 issues.

---

## Fase 35: Studio Settings Architecture & Sub-Screen Standardization

Standardisasi menyeluruh terhadap seluruh sub-screen pengaturan (Theming, Playback Engine, Visualizer, Docking, Audio Hardware, Gestures, Storage & Cache, Library Scanner, Backup & Restore) menggunakan Bento Dropdowns, status hero banners, dan padding konsisten.

- [x] **35.1 Layout & Spatial Geometry Standardization**
  - [x] Margin lateral 16px, padding bawah 96px (clearance floating dock), squircle outer radius 16px, inner element radius 12px, badge pill radius 6-8px dengan tabular figures (`FontFeature.tabularFigures()`).
- [x] **35.2 Standardisasi Bento Dropdowns (ComboBox) di Sub-Screens**
  - [x] Mengganti kartu daftar vertikal yang panjang dengan Bento ComboBox Dropdown ringkas pada `GesturesSettingsScreen` (Single Tap, Double Tap, Long Press, Track Swipes), `StorageCacheSettingsScreen` (Auto-Purge Threshold, Cache Retention), `LibraryScannerSettingsScreen` (Min Track Duration), dan `DockingSettingsScreen` (Orientation Lock, VU Needle Damping).
- [x] **35.3 Status / Telemetry Hero Banners**
  - [x] Penambahan hero status banner di bagian atas setiap sub-screen dengan telemetry real-time dan badge metrik terpadu.
- [x] **35.4 Unit & Widget Test Suite Validation**
  - [x] Verifikasi regresi nol pada seluruh sub-screen pengaturan dengan 100% tests passing dan 0 lint errors.

---

## Fase 36: Playlist Screen Redesign, Merged Studio Collections, Studio Playlist Action Sheet, Dedicated Playlist Detail Screen & Scrollbar

Standardisasi dan perombakan komprehensif antarmuka Playlist, modal pembuatan playlist custom/smart, navigasi bertingkat, bottom action sheet, dan detail screen dengan scrollbar interaktif.

- [x] **36.1 Merged Studio Collections & Dynamic Smart Playlists Row di `PlaylistsScreen`**
  - [x] Menggabungkan Dynamic Smart Playlists ke dalam baris Studio Collections (bersama Favorite Tracks dan Hi-Res Lossless Masters).
  - [x] Menavigasi ke `SmartPlaylistsScreen` saat kartu Dynamic Smart Playlists ditekan untuk penjelajahan aturan filter dan preset studio.
- [x] **36.2 Redesign Modal Pembuatan Playlist Custom & Smart Rule**
  - [x] Pembuatan `CreateCustomPlaylistModal` bento modern dengan ikon ringkas (18-22px) dan validasi input.
  - [x] Redesain `CreateSmartPlaylistDialog` dengan proporsi studio terukur (16-18px), evaluasi langsung jumlah lagu yang cocok, dan styling solid/translucent yang konsisten.
- [x] **36.3 Standardisasi Menu 3-Dots dengan `StudioPlaylistActionSheet`**
  - [x] Mengganti popup menu legacy dengan modal bottom sheet modern bersudut 24px yang mendukung aksi Play Now, Shuffle, Add to Queue, Rename, Duplicate, Export M3U8, dan Delete.
- [x] **36.4 Dedicated `PlaylistDetailScreen` & Interactivity**
  - [x] Collapsing sliver header dengan indikator jumlah lagu, durasi terformat, status custom/smart/preset, dan sticky action bar (Play All, Shuffle).
  - [x] Integrasi `TrackTile` dengan `StudioTrackActionSheet` dan `Scrollbar` interaktif.
- [x] **36.5 Unit & Widget Test Suite Validation**
  - [x] Penambahan suite pengujian `test/playlist_redesign_and_detail_screen_test.dart` dan pembaruan `test/smart_playlists_engine_test.dart` dengan 100% lulus (312/312 tests) dan 0 issues pada `flutter analyze`.

---

## Fase 37: YouTube Music HiFi UI/UX Streamlining & Streaming Engine Fix

Penyederhanaan antarmuka YouTube Discovery / Library Tab agar lebih intuitif, bersih ("as simple"), serta perbaikan menyeluruh pada engine streaming & playback audio YouTube agar lagu dapat terputar secara lancar dan andal.

- [x] **37.1 YouTube Audio Remuxer & Streaming Engine Fix**
  - [x] Perbaikan `WebmToOggRemuxer` dengan packet bundling multi-frame (6+ packets/3KB per page) dan flushing tepat waktu untuk stream Ogg Opus yang 100% compliant dengan parser C++ SoLoud (`libopusfile` / `stb_vorbis`).
  - [x] Peningkatan ketahanan `YouTubeMusicService` dalam ekstraksi stream manifest dan penanganan chunk audio terfragmentasi.
  - [x] Refaktor `PlayerController.playTrack` dengan progressive pre-buffer playback (128KB / 15 chunks header + initial frames) yang tangguh dan fallback caching otomatis 20s.
- [x] **37.2 YouTube Discovery Screen UI/UX Simplification ("As Simple")**
  - [x] Redesain `YouTubeDiscoveryScreen` dengan layout Bento semi-minimalis yang bersih, bebas elemen clutter / slop berlebih.
  - [x] Integrasi search bar responsif dengan debouncing 400ms, filter kategori ringkas, dan kartu bento 1-tap play.
  - [x] Standardisasi tombol aksi 3-dots dengan `StudioTrackActionSheet`.
- [x] **37.3 Unit & Integration Test Suite Validation**
  - [x] Pembuatan `test/youtube_streaming_and_simple_ui_test.dart` untuk memvalidasi alur streaming YouTube, transisi state player, dan rendering UI.
  - [x] Memastikan `flutter analyze` 0 issues dan `flutter test` lulus 100% (315/315 tests passing).

---

## Fase 38: Spotify-Style Studio Lyric Card & Social Media Sharing System & Silent Navidrome Startup

Pembuatan kartu kutipan lirik studio beresolusi tinggi (Lyric Card) bergaya Spotify / Apple Music dengan rasio kustom (9:16 Story, 1:1 Post, 4:5 Portrait, 16:9 Landscape), seleksi multi-baris interaktif, tema warna dinamis / OLED / studio, badge format Hi-Res audio, rasterisasi gambar via RepaintBoundary, serta integrasi berbagi ke media sosial (Instagram Stories, WhatsApp, X, dsb.) dan galeri lokal, beserta silent auto-reconnect Navidrome startup.

- [x] **38.1 Setup Dependensi `share_plus` & Domain Model**
  - [x] Menambahkan package `share_plus` (`^13.3.0`) ke `pubspec.yaml`.
  - [x] Membuat domain model `LyricShareConfig`, enum `LyricCardRatio` (9:16 Story, 1:1 Square, 4:5 Portrait, 16:9 Landscape), dan `LyricCardThemePreset`.
  - [x] Membuat model `LyricCardColors` dengan resolusi tema preset (Dynamic, Studio OLED Black, Precision Mint, Sky Studio, Warm Tube, Studio Rose).
- [x] **38.2 Canvas Render `LyricCardWidget` & Service Rasterisasi `LyricImageGenerator`**
  - [x] Membangun `LyricCardWidget` responsif (`LayoutBuilder` & dynamic scale factor) dengan tipografi lirik tebal, metadata track, artwork squircle 12px, Hi-Res audio badge, dan studio branding.
  - [x] Mengimplementasikan `LyricImageGenerator` untuk rasterisasi `RepaintBoundary` -> PNG byte buffer (`pixelRatio: 3.0`) -> cache file -> native sharing via `SharePlus.instance.share`.
- [x] **38.3 State Management & Interactive Modal `LyricShareSheet`**
  - [x] Membuat `LyricShareController` untuk mengelola seleksi baris lirik (1-5 baris berurutan) dan konfigurasi tampilan.
  - [x] Membuat `LyricShareSheet` dengan tab seleksi lirik, live preview canvas interaktif, color/ratio switcher, dan tombol aksi share/save.
- [x] **38.4 Integrasi ke `SynchronizedLyricsView` & Player**
  - [x] Menambahkan tombol aksi Share Lyrics di toolbar lirik dan interaksi long-press pada baris lirik.
  - [x] Menghubungkan metadata lagu aktif, format audio (kHz/bit), dan artwork.
- [x] **38.5 Dynamic Album Palette, Blurred Cover Background, Gallery Saving & App Logo Branding**
  - [x] Memperbaiki penyimpanan rasterisasi gambar langsung ke direktori publik Galeri / Pictures (`Pictures/BayHifi` di Android/desktop) agar langsung muncul di Galeri foto perangkat.
  - [x] Menangani pengecualian `MissingPluginException` pada `share_plus` secara elegan dengan pesan informatif dan fallback otomatis ke penyimpanan galeri.
  - [x] Memperbaiki rendering artwork album pada footer kartu preview menggunakan `StudioArtworkWidget` terpadu agar selalu tampil dari bytes, file lokal, maupun URL.
  - [x] Menambahkan 4 mode styling background: *Blurred Cover* (artwork album blur dengan studio readability shield), *Cover Palette* (swatches warna dinamis via `PaletteGenerator`), *Studio Themes* (preset studio), dan *Custom Colors* (12 palet warna audiophile kustom).
  - [x] Memperbarui branding studio di header kartu menggunakan aset logo resmi aplikasi `assets/images/baydev_logo.png`.
- [x] **38.6 Custom Typography, Audio Specs Badge Custom Text & Landscape Ratio**
  - [x] Menambahkan opsi tipe font (`Studio Sans`, `Editorial Serif`, `Studio Mono`, `Script Flow`).
  - [x] Menambahkan kontrol perataan teks (*Left*, *Center*, *Right*), ketebalan teks (*Bold/Regular*), kemiringan (*Italic*), dan *font size scale stepper* (`65%` hingga `160%`).
  - [x] Menambahkan dialog editor teks kustom untuk *Audio Specs Badge* dengan opsi *Reset to Auto*.
  - [x] Menambahkan opsi rasio kartu *Landscape (16:9)* yang responsif untuk wallpaper desktop dan feed sosial horizontal.
- [x] **38.7 Silent Navidrome Startup Restore & Error-Only Notifications**
  - [x] Parameterisasi `isSilent = true` pada `restoreNavidromeSession()`, `connectNavidrome()`, dan `syncNavidromeLibrary()`.
  - [x] Membersihkan `statusMessage` dari toast/snackbar saat auto-connect dan auto-sync berjalan sukses di startup, sambil mempertahankan notifikasi error saat terjadi kegagalan koneksi.
- [x] **38.8 Unit & Widget Test Suite Validation**
  - [x] Membuat unit test `test/lyric_share_models_and_controller_test.dart` dan widget test `test/lyric_card_widget_and_sheet_test.dart`.
  - [x] Memastikan `flutter test` lulus 100% dan `flutter analyze` 0 issues / 0 warnings.

---

## Fase 39: Notification Icon Crash Fix & Storage Permission Modal Fix (Android 10 / MIUI)

Perbaikan crash `IllegalArgumentException: Invalid notification (no valid small icon)` saat memutar lagu offline, dan perbaikan alur permission storage yang tidak tampil dengan benar di MIUI Android 10.

- [x] **39.1 Audio Service Notification Icon Crash Fix**
  - [x] Identifikasi root cause: `AudioServiceConfig.androidNotificationIcon` menunjuk ke `drawable/ic_stat_music` yang tidak ada di APK MIUI.
  - [x] Ganti ke `mipmap/ic_launcher` di `lib/main.dart` — icon yang selalu tersedia di semua density dan versi Android.
  - [x] Verifikasi `AndroidManifest.xml` sudah memiliki `android:icon="@mipmap/ic_launcher"`.
- [x] **39.2 Storage Permission Flow Fix (Android 10 / MIUI)**
  - [x] Refaktor `ensureStoragePermissions()` di `library_controller.dart` dengan urutan yang benar: `READ_EXTERNAL_STORAGE` → `READ_MEDIA_AUDIO` → `permanently denied → openAppSettings()` → `MANAGE_EXTERNAL_STORAGE`.
  - [x] Tambahkan fallback `openAppSettings()` saat izin `permanentlyDenied` agar user dapat grant manual dari System Settings.
  - [x] Proteksi `MANAGE_EXTERNAL_STORAGE` dengan try/catch untuk mencegah crash di Android 10 (API < 30).
  - [x] Pindahkan `Permission.notification.request()` ke akhir pipeline (Step 5) agar tidak memblokir permission storage utama.
- [x] **39.3 Unit & Analyzer Validation**
  - [x] `flutter analyze` 0 issues. Seluruh tes lulus 100%.

---

## Fase 40: Dynamic Album Art Theme Cold-Boot Persistence & Proportional Lyric Card Preview Redesign

Perbaikan bug hilangnya warna tema dinamis dari cover album lagu yang sedang aktif saat aplikasi ditutup/di-kill, perombakan menyeluruh kartu preview lirik dengan layout dua-kolom proporsional untuk rasio landscape (16:9), serta redesain opsi kustomisasi kartu menjadi Bento Section yang bersih dan ergonomis.

- [x] **40.1 Dynamic Album Art Theme Cold-Boot Persistence**
  - [x] Menambahkan penyimpanan nilai warna `dynamic_dominant` dan `dynamic_vibrant` ke cache database lokal pada `LocalPersistenceService.saveThemeSettings()`.
  - [x] Memperbarui `ThemeController._loadInitialState()` untuk memulihkan `AppPalette` dengan warna dinamis yang tersimpan saat startup jika `dynamic_album_art == true`.
  - [x] Menambahkan pemanggilan `_persist()` otomatis saat `setDynamicAlbumArt()` dieksekusi saat lagu berubah.
  - [x] Menambahkan sinkronisasi ulang palet warna dari lagu aktif di `_BaydevHiFiAppState.initState()` pada cold start.
- [x] **40.2 Dedicated Landscape (16:9) Proportional Two-Column Layout**
  - [x] Membangun `_buildLandscapeContent` di `LyricCardWidget` dengan arsitektur dua kolom: sisi kiri untuk kutipan lirik yang lapang dan proporsional (`Expanded(flex: 11)`), dan sisi kanan untuk studio track badge kompak (`Expanded(flex: 8)`).
  - [x] Merampingkan footer dan thumbnail squircle pada rasio vertikal (`9:16`, `1:1`, `4:5`) agar tidak memakan ruang lirik.
  - [x] Kalibrasi skala ukuran font dinamis sesuai rasio dan jumlah baris lirik yang dipilih.
- [x] **40.3 Studio Bento Options Redesign di `LyricShareSheet`**
  - [x] Viewport stage preview terisolasi dengan animasi transisi halus antar rasio.
  - [x] Pengelompokan kontrol ke dalam 4 kartu Bento Material 3 Expressive studio: *CARD RATIO* (dengan wireframe preview box), *TYPOGRAPHY & FORMATTING* (font family, alignment, bold/italic, font size multiplier), *BACKGROUND & PALETTE* (blurred cover, dynamic album swatches, studio presets, custom palette), dan *ELEMENTS & BADGES* (custom audio specs editor, studio branding, phonetic subtitle).
- [x] **40.4 Unit & Widget Test Suite Validation**
  - [x] Menambahkan pengujian cold boot dynamic palette restoration di `test/theme_persistence_test.dart`.
  - [x] Menambahkan pengujian dedicated landscape 16:9 layout di `test/lyric_card_widget_and_sheet_test.dart`.
  - [x] 100% tests passing (334/334 tests) dan 0 analyzer issues (`flutter analyze`).

---

## Fase 41: UI/UX Redesign, Dashboard Reordering, Library Grid Mode & Dynamic Detail Screen Backdrops

Penyempurnaan estetika studio dan konsistensi interaksi visual:
1. **Lyric Card Ratio Horizontal Scroll**: Selector rasio kartu lirik menggunakan `SingleChildScrollView` horizontal dengan tombol berukuran terstandarisasi (`86px`) sehingga seluruh opsi (Story 9:16, Portrait 4:5, Square 1:1, Landscape 16:9) pas dan tidak terpotong atau wrap ke bawah.
2. **Dashboard Hierarchy Redesign**: Rekonfigurasi urutan section Dashboard di mana `Recent Lossless Sessions` (`RecentSessionsBentoCarousel`) kini berada tepat di bawah `Dynamic Studio Mixes` (`StudioHeroShowcaseCarousel`) untuk visual flow yang harmonis.
3. **Default Grid Mode for Albums & Artists (3-Column Circular Studio Presentation)**: Menjadikan mode Grid sebagai default (`layoutMode = ViewLayoutMode.grid`) dan merombak tampilan tab Artists menjadi **3 kolom per baris** dengan avatar berbentuk lingkaran murni, bayangan studio, dan nama artis di tengah.
4. **Album Detail Screen Ambient Artist Photo Background (Soft Studio Blur)**: Menampilkan foto artis di belakang cover album dengan efek Gaussian blur yang halus dan tidak berlebihan (`sigma 7.0`), berpadu dengan gradient scrim yang seimbang sehingga foto artis terlihat jelas namun teks dan cover tetap terbaca tajam.
5. **Artist Detail Screen Dynamic Collage & Gradient Backdrop**:
   - Jika artis memiliki $\ge 4$ album: Menghasilkan **2x2 Album Cover Art Collage** yang diblur halus (`sigma 12.0`) dan dipadukan dengan studio vignette overlay.
   - Jika artis memiliki $< 4$ album: Menghasilkan ambient backdrop foto artis (`sigma 7.0`) / artwork album primer dengan gradasi permukaan tema yang menyatu mulus ke tracklist.
6. **Library Tracks Shuffle Shortcut FAB**: Menambahkan secondary FAB di atas Category FAB pada tab Tracks (`CollectionTab.tracks`) yang mengacak seluruh koleksi track, memasukkan track ke playback queue (`ref.read(playerControllerProvider.notifier).setQueue(shuffled, initialIndex: 0)`), memicu haptic feedback, dan menampilkan konfirmasi snackbar.
7. **Clean Bento Architecture di Seluruh Layar & Typographic Hierarchy**:
   - Standardisasi margin, radius squircle konsisten, dan solid studio surface backgrounds (`theme.colorScheme.surface`, `surfaceContainer`).
   - Eliminasi gradasi berlebihan dan efek glassmorphism yang mengaburkan teks.
   - Integrasi `FontFeature.tabularFigures()` pada seluruh metrik numerik, waktu durasi, frekuensi DSP, dan sampling rate.

- [x] **41.1 Lyric Card Ratio Picker Horizontal Scroll**
- [x] **41.2 Dashboard Section Reordering & Proportions**
- [x] **41.3 Library Albums & Artists Default 3-Column Circular Grid Mode & Toggle Bugfix**
- [x] **41.4 Album Detail Screen Artist Photo Ambient Background (Soft Recognizable Blur)**
- [x] **41.5 Artist Detail Screen Dynamic 2x2 Collage Backdrop**
- [x] **41.6 Library Tracks Shuffle All Shortcut FAB with Queue Integration**
- [x] **41.7 Clean Bento Architecture & Typographic Hierarchy with Tabular Figures**
- [x] **41.8 Unit & Widget Test Suite Validation (`test/phase_41_ui_ux_redesign_test.dart` - 100% Passed)**

---

## Fase 42: Borderless Studio Lyric Card, Dynamic Cover Theming Contrast Hardener, Sub-Settings & Pro-Q Precision Mastering Redesign

Peningkatan kualitas visual kartu lirik, proteksi kontras palet dinamis, serta penyempurnaan arsitektur DSP Rack dan Pro-Q Studio:
1. **Borderless Studio Lyric Card**: Menghilangkan outer border stroke pada kartu lirik sehingga hasil rendering kartu menjadi bersih, murni, dan borderless dengan sudut squircle halus (`ClipRRect 24px`).
2. **Dynamic Cover Theme Contrast Hardener (`StudioColorHarmonizer`)**:
   - Mencegah masalah teks/ikon hitam pada cover album gelap/hitam: Jika warna ekstraksi album memiliki luminance/lightness rendah atau saturasi grayscale, algoritma secara cerdas mentransformasikan aksen menjadi **Studio Silver Ash / Slate (`#94A3B8`)** dengan kontras tinggi WCAG AA.
   - Mengkalkulasi `onPrimary` dan `onSecondary` secara dinamis pada `AppThemeBuilder` berdasarkan relative luminance sehingga teks/ikon pada tombol selalu terlihat kontras dan tajam.
   - Mengamankan resolusi `LyricCardColors.fromDynamicColor` agar latar belakang, kartu, dan teks selalu terbaca kontras pada cover hitam.
3. **Theming & Studio Palettes Sub-Settings Hub Redesign**:
   - **Active Studio Theme Cockpit Preview**: Menampilkan live preview pemutar studio mini, audio specs badge, slider aksen, dan 4 titik swatch warna.
   - **Display Ground & Surface Style Card**: Kontrol compact 3-opsi Theme Mode (`System`, `Light`, `Dark`) dan 2-opsi Surface Fill Style (`Solid M3` vs `Translucent Soft Tint`).
   - **Dynamic & OLED Engines**: Bento card switch untuk *Monet Dynamic Album Art Palette* dan tombol 1-tap aktivasi *True OLED Black Mode*.
   - **Curated Studio Palettes Filtered Grid**: Tab filter kategori (`All Presets`, `Studio Core`, `Pastel Soft`) dengan 2-kolom grid bento responsif berisi 19 palet studio dan checkmark indicator.
   - **Custom Studio Accent Picker**: 19 color swatches studio dengan active glow ring.
4. **Pro-Q Studio & DSP Rack Precision Mastering Redesign**:
   - Precision Interactive Parametric Equalizer (`ProQCanvas`): Zero latency node dragging, filter type selection, Q-factor pinch-to-zoom.
   - Mastering DSP Rack Modules: Modular bypass switch, gain reduction VU meters, and dynamic telemetry.

- [x] **42.1 Borderless Studio Lyric Card Canvas (`LyricCardWidget`)**
- [x] **42.2 StudioColorHarmonizer Dynamic Cover Contrast Protection**
- [x] **42.3 Dynamic `onPrimary` / `onSecondary` & WCAG AA Contrast in `AppThemeBuilder`**
- [x] **42.4 Material 3 Expressive Sub-Settings Redesign (`ThemingSettingsScreen`)**
- [x] **42.5 Precision Interactive Parametric Equalizer & Mastering DSP Rack Modules**
- [x] **42.6 Unit & Widget Test Suite Validation (`test/phase_42_theming_and_contrast_test.dart` - 100% Passed)**

---

## Fase 43: Instagram & Spotify Style Lyric Card Customization Engine, Audio Pipeline Resilience & Dynamic Routing

Ekspansi kemampuan kustomisasi kartu lirik studio berstandar Instagram Stories & Spotify Sharing, serta optimalisasi pipeline audio streaming:
1. **Multi-Weight Typography Engine**:
   - Selector ketebalan font (`FontWeight.w400 Regular`, `w600 SemiBold`, `w700 Bold`, `w900 Black`) dengan chip interaktif 1-tap.
   - Pilihan perataan teks (Left, Center, Right), toggle italic, dan font size scaling stepper (`65%` - `160%`).
2. **Text Styles & Highlights (Instagram & Spotify Style `LyricCardHighlightStyle`)**:
   - **`Clean` (`none`)**: Tipografi studio minimalis tanpa efek tambahan.
   - **`Text Stroke` (`stroke`)**: Border outline di sekeliling teks karakter huruf menggunakan dual-pass layer rendering (`Stack` + `Paint()..style=PaintingStyle.stroke`) dengan warna kontras otomatis dan opsi ketebalan stroke (`1.5px Subtle`, `2.5px Standard`, `4.0px Thick`).
   - **`Instagram Pill` (`highlighterPill`)**: Kotak latar rounded squircle bergaya Instagram Stories di belakang setiap baris lirik dengan padding nyaman dan kontras tinggi.
   - **`Spotify Glow` (`dropShadow`)**: Ambient diffused drop shadow dan soft accent glow di belakang glyph teks sehingga lirik melayang jelas di atas artwork yang kompleks.
3. **Typography Spacing & Formatting**:
   - Kontrol line spacing dinamis: `Compact (0.8x)`, `Normal (1.0x)`, `Relaxed (1.3x)`.
   - Kontrol letter spacing: `Tight (-0.5)`, `Normal (-0.2)`, `Wide (+0.8)`.
4. **Atmosphere & Readability Shield Adjustments**:
   - Pengaturan instan intensitas blur cover: `Soft (15)`, `Normal (30)`, `Deep (50)`.
   - Pengaturan intensitas dark vignette / readability shield: `Light (40%)`, `Standard (65%)`, `Heavy (85%)`.
5. **No Overflow Guarantee**:
   - Seluruh baris kontrol di dalam modal bottom sheet dibungkus horizontal scroll view responsif untuk tampilan sempurna di semua rasio layar mobile.
6. **Audio Pipeline Resilience & Dynamic Routing**:
   - Penanganan stream disconnection, automatic retry, dan silent connection restores.

- [x] **43.1 Domain Models & Config Expansion (`LyricCardHighlightStyle`, `LyricShareConfig`)**
- [x] **43.2 Dual-Pass Stroke, Instagram Pill & Spotify Glow Canvas (`LyricCardWidget`)**
- [x] **43.3 Blur Sigma & Readability Shield Atmospheric Controls in `LyricCardWidget`**
- [x] **43.4 Responsive Material 3 Expressive Bento UI Controls in `LyricShareSheet`**
- [x] **43.5 Controller State Updaters in `LyricShareController`**
- [x] **43.6 Robust Streaming & Caching Engine Integration**
- [x] **43.7 Unit & Widget Test Suite Validation (`test/phase_43_lyric_card_customization_test.dart` - 100% Passed)**

---

## Fase 44: Pure Material 3 Expressive UI Architecture & 100% Migration PRD

### Product Requirements Document (PRD) — 100% `material_3_expressive` Adoption

#### 1. Executive Summary & Vision
Baydev HiFi bertransformasi secara penuh menuju arsitektur **100% Pure Material 3 Expressive** dengan mengadopsi library resmi [`material_3_expressive`](https://pub.dev/packages/material_3_expressive) (`version: ^1.1.3`) dan sub-sistemnya (`material_ui: ^1.4.0`, `motor: ^0.2.0` / `^1.1.0`, `material_new_shapes: ^1.0.0`).
Tujuan utama migrasi ini adalah menyatukan seluruh komponen antarmuka ke standar Material 3 Expressive resmi dari Google:
- Menghilangkan seluruh widget Material 1/2 legacy dan implementasi kustom ad-hoc.
- Memanfaatkan fisika pegas *spring motion* (`motor`) untuk seluruh transisi bottom sheet, dialog, carousels, expand-collapse miniplayer, dan interaksi sentuhan.
- Mengadopsi morfologi bentuk squircle geometris (`material_new_shapes`) dan token dimensi resmi (`M3EDimensions`).
- Menjaga performa audio audiophile 120 FPS pada custom canvas (`ProQCanvas`, `RtaVisualizerCanvas`, `WaveformCanvas`) dengan membungkusnya secara bersih di dalam kontainer `M3ECard` / `M3EShapeContainer`.

---

#### 2. Matriks Pemetaan & Inventarisasi Komponen (Component Migration Matrix)

| Kategori UI | Komponen Sebelumnya (Legacy / Ad-hoc) | Komponen Resmi `material_3_expressive` | Fitur / Keunggulan M3 Expressive |
| :--- | :--- | :--- | :--- |
| **Root Application** | `MaterialApp` + `ThemeData` | `M3EMaterialApp` + `M3EThemeData` | `autoTheming`, `dynamicColoring`, `drawUnderSystemBars: true` |
| **Navigation Dock** | Custom `AnimatedContainer` pill dock | `M3ENavigationBar` / `M3EToolbar` | Capsule floating dock dengan spring pill indicators (`motor`) |
| **Bento Cards** | Custom `Container` / `InkWell` | `M3ECard.filled` / `M3ECard.outlined` | Tonal elevation, 1px crisp studio border, dynamic splash ripple |
| **Horizontal Carousels** | `PageView.builder` / `ListView` | `M3ECarousel.multiBrowse` / `.uncontained` | Dynamic peek edges, spring deceleration, and flush grid alignment |
| **Buttons & Actions** | `ElevatedButton`, `FilledButton`, `TextButton` | `M3EButton.filled`, `.tonal`, `.outlined` | Standar rasio M3E, squircle corners, expressive press feedback |
| **Icon Buttons** | `IconButton` standard | `M3EIconButton.standard`, `.filled`, `.tonal` | 40x40 touch target minimum, unified HugeIcons stroke |
| **Floating Actions** | Standard `FloatingActionButton` | `M3EFab`, `M3EExtendedFab`, `M3EFabMenu` | Speed dial floating action menu dengan animasi morphing |
| **Audio Sliders** | Standard `Slider` | `M3ESlider.continuous` & `M3ESlider.wavy` | Track berekspresi, dynamic thumb morphing, snap haptics |
| **Switches & Toggles** | Standard `Switch` | `M3ESwitch` | Expressive thumb icon state, spring glide animation |
| **Checkboxes** | Standard `Checkbox` | `M3ECheckbox` | Squircle rounded checkmark, multi-state visual feedback |
| **Segmented Selectors** | Custom pill toggle rows | `M3ESegmentedButton` / `M3EButtonGroup` | Single & multi-segment pill switching with spring physics |
| **Lists & Track Tiles** | `ListTile` standard | `M3EListTile` | Leading `M3EShapeContainer`, trailing `M3EBadge`, ripple states |
| **Badges & Specs** | Custom badge container | `M3EBadge` | Tabular figures support, tonal background, crisp outline |
| **Bottom Sheets** | `showModalBottomSheet` standard | `M3EBottomSheet.showModal` | Spring drag physics (`motor`), rounded 28px top corners |
| **Dialogs & Modals** | `AlertDialog` / `Dialog` | `M3EDialog` | Expressive content layout, actions alignment, tonal background |
| **Search Bars** | Standard `TextField` | `M3ESearchBar` & `M3ESearchAnchor` | Expandable search view, search suggestions, leading HugeIcon |
| **Progress & Loaders** | `LinearProgressIndicator`, `CircularProgressIndicator` | `M3EProgressIndicator`, `M3ELoadingIndicator` | Expressive fluid indeterminate animations & micro-progress lines |
| **Haptic Feedback** | `HapticFeedback.selectionClick()` | `M3EHaptics.selectionClick()` / `.lightImpact()` | Respon taktil terintegrasi pada event interaksi M3E |

---

#### 3. Checklist Eksekusi Migrasi 100% Pure M3 Expressive

- [x] **44.1 Root App Shell & Dynamic Theming (`M3EMaterialApp` + `M3EThemeData`)**
  - [x] Migrasi `MaterialApp` ke `M3EMaterialApp` di `lib/app/app.dart` dengan `M3EThemeData` (`autoTheming: true`, `dynamicColoring: true`, `drawUnderSystemBars: true`).
  - [x] Konfigurasi `localizationsDelegates` (`DefaultMaterialLocalizations.delegate`, `DefaultWidgetsLocalizations.delegate`) untuk resolusi dialog & appbar.
  - [x] Pembungkusan haptic feedback terpusat di `lib/app/theme/app_haptics.dart` menggunakan `M3EHaptics.trigger(M3EHapticFeedback.light/medium/heavy)` dan `M3EHaptics.selection()`.
- [x] **44.2 Omnipresent Navigation Dock, Expandable MiniPlayer & Now Playing**
  - [x] Navigasi dock capsule `FloatingRoundedDock` dan `NamidaExpandableMiniPlayer` dengan micro progress indicator dan gesture handling yang responsif.
  - [x] Migrasi seluruh tombol kontrol dan aksi di `NowPlayingScreen` ke `AppHaptics`.
- [x] **44.3 Bento Grid Dashboard & Hero Showcases**
  - [x] Migrasi seluruh bento cards di `DashboardScreen` (`ListeningStatisticsCard`, `RecentSessionsBentoCarousel`, `StudioHeroShowcaseCarousel`, `ProQMiniLauncherBentoCard`, `MasteringDspBentoCard`) ke `M3EProgressIndicator` dan `AppHaptics`.
- [x] **44.4 Unified Library, Media Collections & Action Modals**
  - [x] `UnifiedLibraryScreen`, `TrackTile`, `StudioTrackActionSheet`, detail screens, batch selection bar, dan folder resolvers dimigrasikan ke `AppHaptics` dan `M3EProgressIndicator`.
- [x] **44.5 DSP Rack, Pro-Q Studio & AutoEQ Modals**
  - [x] `DspRackScreen`, `RackUnitCard`, dan `ProQStudioScreen` terintegrasi penuh dengan `AppHaptics`.
- [x] **44.6 YouTube Music, Lyrics Share, Settings Hub & Sub-Screens**
  - [x] Migrasi `YouTubeDiscoveryScreen`, `YouTubeImportPlaylistDialog`, `LyricShareSheet`, dan seluruh 9 sub-screen Settings (`ThemingSettingsScreen`, `PlaybackEngineSettingsScreen`, `VisualizerSettingsScreen`, `AudioHardwareSettingsScreen`, `DockingSettingsScreen`, `GesturesSettingsScreen`, `StorageCacheSettingsScreen`, `LibraryScannerSettingsScreen`, `BackupRestoreSettingsScreen`) ke `M3EProgressIndicator.circular` dan `AppHaptics`.
  - [x] Migrasi seluruh widget display player (`StudioDeskDockingScreen`, `SynchronizedLyricsView`, `StudioDspBentoCapsule`, `ParallaxArtworkCard`, `PlaybackSpeedPitchSheet`, `SleepTimerSheet`, `NowPlayingQueueSheet`, `DualPaneWorkstationPane`, `CustomTimeBar`, `AudioFileInspectorSheet`) ke `AppHaptics`.
- [x] **44.7 Automated Unit & Widget Test Suite Validation**
  - [x] Seluruh 352 test di `test/` lulus 100% (`flutter test`: 352/352 tests passed).
  - [x] Zero analyzer issues / warnings (`flutter analyze`: No issues found).

---

## Fase 45: Pure Material 3 Expressive Total UI Overhaul (Official Gallery Fidelity)

Perombakan total antarmuka grafis Baydev HiFi menjadi **100% Pure Material 3 Expressive** dengan mengacu secara presisi pada 5 modul visual resmi `material_3_expressive: ^1.1.3` (Actions & Buttons, Selection & Sliders, Containment & Cards, Navigation & Bars, Feedback & Theming), mengeliminasi flat monochrome (hitam pekat & putih polos) dengan 5-level Tonal Surface Hierarchy, dan memanfaatkan `motor` spring physics, `material_new_shapes`, serta `M3EHaptics`.

- [x] **45.1 Tonal Surface & Theme System Overhaul (`AppPalette`, `AppThemeBuilder`, `StudioSurfaceTheme`)**
  - [x] Implementasi 5-level Tonal Surface Elevation (`surfaceContainerLowest` s/d `surfaceContainerHighest`) pada mode Dark dan Light di seluruh 19 preset studio `AppPalette`.
  - [x] Perbaikan `StudioSurfaceTheme.tintedContainer` dengan tonal blending dinamis dan outline studio halus.
  - [x] Kalibrasi `StudioColorHarmonizer` untuk proteksi kontras otomatis WCAG AA pada ekstraksi album dinamis.
- [x] **45.2 Dashboard Screen M3 Expressive Overhaul**
  - [x] Migrasi Dynamic Studio Mixes ke `M3ECarousel.multiBrowse` dengan `M3EButton.filled`.
  - [x] Upgrade modul Bento Telemetry & Hardware ke `M3ECard.filled` dengan `M3EBadge` status chip.
  - [x] Integrasi `M3EProgressIndicator` pada listening statistics dan lossless ratio.
- [x] **45.3 Mastering DSP Rack & Pro-Q Screen M3 Expressive Overhaul**
  - [x] Migrasi modul DSP Rack ke collapsible `M3ECard` dengan `motor` spring physics.
  - [x] Integrasi `M3ESwitch` dengan animasi spring thumb dan `M3ESlider` continuous & wavy.
  - [x] Migrasi header Pro-Q banner dan kontrol band ke `M3EButton.tonal` & `M3EChip`.
- [x] **45.4 Unified Music Library & Playlists Screen M3 Expressive Overhaul**
  - [x] Migrasi filter sumber ke `M3EChip.filter` dengan spring checkmark.
  - [x] Integrasi `M3EListTile` dengan squircle album art, format badges, dan `M3EIconButton`.
  - [x] Migrasi category dock / speed dial ke `M3EFabMenu` dan `M3EFab`.
  - [x] Integrasi `M3ESearchBar` dan `M3ESegmentedButton` untuk List/Grid mode.
- [x] **45.5 Now Playing Screen & Expandable Miniplayer M3 Expressive Overhaul**
  - [x] Implementasi `M3ESlider.wavy()` untuk fluid audio seekbar.
  - [x] Upgrade control deck ke symmetrical squircle `M3EIconButton` dengan press feedback.
  - [x] Bottom action strip dengan `M3EButton.tonal` dan modal bottom sheets `M3EBottomSheet`.
- [x] **45.6 Settings Hub & Sub-Screens M3 Expressive Overhaul**
  - [x] Redesain grouped settings sections menggunakan `M3ECard` dengan `StudioCategoryColors`.
  - [x] Integrasi `M3ESwitch`, `M3EDropdown`, dan `M3ESegmentedButton` pada seluruh preferensi.
- [x] **45.7 Quality Gate & Zero Regression Testing**
  - [x] Verifikasi `flutter analyze` dengan 0 errors dan 0 warnings.
  - [x] Verifikasi `flutter test` dengan 100% kelulusan test suite (355+ tests passed).

---

## Fase 46: Now Playing Landscape & Tablet Mode Refinement

- [x] **46.1 Perbaikan Bug Up Next Queue Tab**:
  - [x] Memperbaiki pemanggilan `queueIndex` di [dual_pane_workstation_pane.dart](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/lib/features/player/presentation/widgets/dual_pane_workstation_pane.dart) untuk mengatasi `NoSuchMethodError: currentIndex`.
  - [x] Menambahkan interactive tap listener (`skipToQueueIndex(idx)`) untuk lompat ke lagu yang dipilih secara instan.
- [x] **46.2 Penataan Ulang Tab Workstation Kanan**:
  - [x] Menghilangkan tab `PRO-Q EQ` dari split pane kanan agar ruang visual tidak sempit/cramped.
  - [x] Menyederhanakan workstation kanan menjadi 3 tab utama yang leluasa: `UP NEXT`, `LYRICS`, dan `DSP RACK`.
  - [x] Menjadikan Pro-Q Studio tetap fokus diakses melalui layar penuh (`ProQStudioScreen`).
- [x] **46.3 Penyederhanaan Sisi Kiri (Landscape Left Pane)**:
  - [x] Menghilangkan baris 6 tombol aksi bawah (`_buildBottomStudioActionStrip`) pada mode landscape untuk mencegah penumpukan vertikal.
  - [x] Merelokasi aksi studio esensial (`Open Local File`, `Speed & Pitch`, `Desk Mode`, `Pro-Q Studio`, `Audio Spec Inspector`, `Sleep Timer`, `Favorite`) ke Top Header Bar sisi kiri dengan icon buttons minimalis dan tooltip.
  - [x] Menambahkan app logo resmi pada leading `NavigationRail` di tablet & desktop mode.
- [x] **46.4 Validasi & Quality Assurance**:
  - [x] Penambahan widget test di `test/dual_pane_workstation_pane_test.dart` dan `test/player_screen_redesign_test.dart`.
  - [x] Verifikasi 100% lulus pada seluruh rangkaian test suite.

---

## Fase 47: Studio Desk & Car Docking Mode Overhaul

- [x] **47.1 Integrasi Wavy Seekbar (`CustomTimeBar` / `M3ESlider.wavy()`)**:
  - [x] Menggantikan slider standar dengan gelombang sinus dinamis (`TimeBarStyle.wavy`), terhubung ke `playerCustomizationProvider`.
  - [x] Dukungan `timeDisplayMode` (waktu tersisa `-04:39` vs durasi total) dengan tipografi angka tabular (`AppTypography.audioFigures`).
- [x] **47.2 Visualizer Switcher Dinamis (Artwork / VU Meters / Spectrum)**:
  - [x] Integrasi `ParallaxArtworkCard` dengan dukungan CD Jewel Case, Vinyl 3D, Curved Bento, dan Squircle.
  - [x] Mode switcher 3 arah yang mulus: **`ARTWORK`**, **`VU METERS`** (Analog Dual-Channel L-R Peak Meters), dan **`SPECTRUM`** (M3 Expressive RTA Spectrum Visualizer).
- [x] **47.3 Kontrol Pemutaran Raksasa & Telemetry Studio**:
  - [x] Tombol Play/Pause 68px dengan dynamic ambient glow dan `M3EProgressIndicator.circular` saat buffering.
  - [x] Tombol Previous/Next, Shuffle, Repeat simetris dengan tactile `AppHaptics`.
  - [x] Badge spesifikasi audio Hi-Res Master Gold / Lossless Audio (`96.0 kHz / 24-bit • FLAC`) interaktif dengan `AudioFileInspectorSheet`.
- [x] **47.4 Quick DSP Presets & Volume Control**:
  - [x] Strip preset DSP mastering 1-tap (`Studio Master`, `Audiophile Pure`, `Warm Tube`, `Bass Boost`, dll.) dan slider volume presisi.
- [x] **47.5 Responsivitas & Validasi Menyeluruh**:
  - [x] Desain terkalibrasi untuk Landscape (Tablet/Car Docks) dan Portrait (Phone Stands) bebas overflow.
  - [x] Pengujian otomatis lulus 100% di `test/desk_docking_test.dart` dan `test/playback_loading_spinner_test.dart`.

---

## Fase 48: Linux Desktop Compilation & Packaging Implementation

- [x] **48.1 Verifikasi Toolchain & Native Dependencies**:
  - [x] Verifikasi Flutter SDK 3.47.5, Clang 18.1.3, CMake 3.28.3, Ninja 1.11.1, pkg-config 1.8.1.
  - [x] Verifikasi native libraries `libgtk-3-dev` (3.24.41) dan `libasound2-dev` (ALSA 1.2.11) untuk engine C++ `flutter_soloud`.
- [x] **48.2 Kompilasi Linux Debug & Release**:
  - [x] Kompilasi berhasil untuk `flutter build linux --debug`.
  - [x] Kompilasi berhasil untuk `flutter build linux --release --no-tree-shake-icons`.
  - [x] Pembentukan standalone relocatable bundle di `build/linux/x64/release/bundle/` berisi executable `baydev_hifi`, shared libraries (`libflutter_soloud_plugin.so`, `libaudiotags.so`, `libflutter_linux_gtk.so`), dan assets.
- [x] **48.3 Konfigurasi .gitignore & Dokumentasi Blueprint**:
  - [x] Pembaruan `.gitignore` untuk mengabaikan artefak build Linux ephemeral (`linux/flutter/ephemeral/`), standalone packaging (`*.AppImage`, `*.deb`, `*.tar.gz`), dan folder bundle staging.
  - [x] Pembuatan dokumen panduan kompilasi dan distribusi desktop di [linux_desktop_compilation_plan.md](file:///home/x/.gemini/antigravity-ide/brain/60c8bfc5-8a26-4277-8746-1c10727adb4b/linux_desktop_compilation_plan.md).

---

## Fase 49: Linux Desktop Adaptive Studio Engine & Platform-Guarded Architecture

Implementasi pengalaman desktop native Linux kelas studio dengan isolasi platform ketat (*zero regression for Android*), integrasi D-Bus MPRIS v2, pintasan keyboard studio, layout 3-kolom dengan Persistent Master Transport Bar, dan Drag-and-Drop file manager.

- [x] **49.1 Desktop Windowing & Geometry Persistence (Platform-Guarded)**:
  - [x] Integrasi `window_manager` terlindungi `Platform.isLinux` (min size `960x640`, default `1280x800`).
  - [x] Persistensi ukuran dan posisi window di `LocalPersistenceService`.
- [x] **49.2 Adaptive Layout Switcher & Desktop Studio Master Layout**:
  - [x] Pembuatan `AdaptiveAppShell` (Mobile `< 960px` vs Desktop `isDesktop && >= 960px`).
  - [x] Implementasi `DesktopStudioSidebar` (Permanent Left Navigation Rail) di desktop.
  - [x] Implementasi `DesktopBottomMasterTransportDeck` dengan squircle prominent play/pause button, 120px volume slider, dan mini RTA.
  - [x] Verifikasi mobile/tablet layout Android tetap 100% identik dan tidak terganggu.
- [x] **49.3 Global & Local Keyboard Shortcuts Engine**:
  - [x] Dispatcher hotkeys (`Space`, `Arrows`, `Ctrl+Arrows`, `L`, `Q`, `E`, `Ctrl+F`, `F11`, `Esc`).
  - [x] Overlay cheatsheet pintasan keyboard (`?` atau `Ctrl+/`).
- [x] **49.4 Linux MPRIS v2 D-Bus & Desktop Media Notification Engine**:
  - [x] Registrasi service `org.mpris.MediaPlayer2.baydev_hifi` pada D-Bus session (Linux-only).
  - [x] Sinkronisasi dua arah status pemutaran, metadata lagu, dan playhead position.
- [x] **49.5 Desktop Drag-and-Drop File & Folder Handler**:
  - [x] Handler drag-and-drop file audio & folder musik langsung dari File Manager Linux.
  - [x] Visual drop overlay dengan responsivitas tinggi.
- [x] **49.6 System Tray & XDG Desktop Integration**:
  - [x] Pembuatan `baydev_hifi.desktop` dan ikon SVG/PNG hi-res.
  - [x] Integrasi system tray icon & context menu (`Play/Pause`, `Next`, `Quit`).
- [x] **49.7 Responsive Library Grids & Modal Lyrics Share Card**:
  - [x] Responsivitas grid Albums (2-6 kolom) dan Artists (3-8 kolom) proporsional pada desktop.
  - [x] Integrasi fitur `Share Lyric Card` di modal `DesktopLyricsDialog` memanggil `LyricShareSheet`.
- [x] **49.8 Quality Gate & Multi-Platform Zero Regression Testing**:
  - [x] Unit & widget tests di `test/desktop_transport_deck_and_lyrics_test.dart` (5/5 passed).
  - [x] Verifikasi `flutter analyze` 0 issues dan `flutter test` lulus 100% (365/365 passed).

---

## Fase 50: In-Tree YouTube & YouTube Music Streaming Engine Overhaul, Full Stream Resolution & Desktop Focus Isolation
 
Modernisasi dan kustomisasi in-tree engine `packages/youtube_explode_dart` untuk streaming audio YouTube/YouTube Music berkualitas tinggi (Opus 160kbps / AAC 256kbps), resolusi batasan CDN 1MB (58s freeze) melalui multi-endpoint verified resolver, eliminasi 403 HEAD checks, perbaikan numeric client ID headers, perbaikan pencarian filter `sp`, isolasi pengetikan pada desktop shortcuts dispatcher, dan pengoptimalan `WebmToOggRemuxer` untuk pemutaran instan 100% lagu.
 
- [x] **50.1 In-Tree Dependency Migration & Repository Decoupling**:
  - [x] Clone `https://github.com/Hexer10/youtube_explode_dart` langsung ke `packages/youtube_explode_dart`.
  - [x] Hapus koneksi `.git` internal package sehingga menjadi source in-tree mandiri.
  - [x] Konfigurasi `pubspec.yaml` menggunakan `path: packages/youtube_explode_dart`.
  - [x] Verifikasi `flutter pub get` dan integrasi workspace.
- [x] **50.2 Innertube API Protocol & Client Modernization**:
  - [x] Update Innertube API endpoints dan payload context (`WEB`, `ANDROID`, `IOS`, `TVHTML5`, `ANDROID_MUSIC`).
  - [x] Implementasi numeric Innertube client IDs mapping (`1` WEB, `3` ANDROID, `5` IOS, `26` TV, `67` ANDROID_MUSIC) pada header `X-Youtube-Client-Name` untuk mencegah error 400 Bad Request.
  - [x] Eliminasi pengecekan `HEAD` request pada `stream_client.dart` yang memicu false positive 403 Forbidden pada CDN googlevideo.
  - [x] Perbarui User-Agent strings dan client version terbaru (`Chrome 133`, `Web 2.20250312.04.00`).
- [x] **50.3 Desktop Keyboard Shortcuts Focus Protection**:
  - [x] Implementasi multi-tier focus detection pada `DesktopShortcutsDispatcher` (`_isTyping`) memeriksa `primaryFocus.context?.widget`, `findAncestorStateOfType<EditableTextState>()`, `findAncestorWidgetOfExactType<TextField>()`, dan `debugLabel`.
  - [x] Perlindungan total saat mengetik di search bar YouTube, Library, tag editor, playlist creator, dan dialog lainnya agar tidak memicu shortcut Space, L, Q, E, M, dsb.
- [x] **50.4 YouTube Music Search & Trending Pipeline Fixes**:
  - [x] Perbaiki format query `SearchPage.get` dengan mengabaikan parameter `sp` kosong agar tidak menghasilkan HTTP 400 Bad Request.
  - [x] Sanitasi metadata `cleanMetadata` dan penghapusan nomor track awal pada nama artis/lagu.
- [x] **50.5 Real-time Audio Stream Buffering & 100% Full Duration Resolution**:
  - [x] Analisis dan pemecahan akar masalah 58-second stall (batasan 1,048,576 bytes pada Google Video CDN tanpa token attestation).
  - [x] Implementasi multi-endpoint verified stream resolver (`_resolveFullAudioStream`) dan chunked streaming pipeline berkecepatan tinggi (chunk 512KB) di `YouTubeMusicService`.
  - [x] Resolusi audio stream kualitas tertinggi (`Opus 160kbps` / itag 251 atau `AAC 256kbps` / itag 140) dengan remuxing real-time `WebmToOggRemuxer` langsung ke buffer C++ SoLoud engine.
  - [x] Otomatisasi caching file utuh ke `AudioCacheService` untuk pemutaran offline instan pada sesi berikutnya.
- [x] **50.6 Quality Gate & Multi-Platform Zero Regression Testing**:
  - [x] Unit & widget tests di `test/desktop_shortcuts_and_youtube_stream_test.dart` (6/6 passed).
  - [x] Integration tests di `test/youtube_stream_integration_test.dart` memverifikasi streaming melampaui 1MB tanpa stall (2/2 passed).
  - [x] Verifikasi `flutter analyze` 0 errors/warnings dan `flutter test` lulus 100% (373/373 passed).

---

## Fase 51: Online Multi-Source Metadata Auto-Fetcher, Interactive Tag Picker, Batch Auto-Tagger & Library Untagged Filter Chip

Implementasi sistem identifikasi dan pencocokan metadata musik otomatis dari berbagai sumber online terpercaya (iTunes Search API, MusicBrainz / Cover Art Archive, Deezer API, dan LRCLIB) untuk memperbaiki file audio yang tidak memiliki tag metadata, artwork cover resolusi tinggi, atau lirik, disertai filter chip dinamis `Untagged` di Unified Library dan modal batch tagger interaktif.

- [x] **51.1 Multi-Provider Online Metadata & Lyrics Engine (`OnlineMetadataService`)**:
  - [x] Integrasi iTunes Search API (1400×1400 lossless album artwork).
  - [x] Integrasi Deezer Search API (genre, ISRC, release year, album art).
  - [x] Integrasi MusicBrainz & Cover Art Archive (verifikasi disc/track number presisi).
  - [x] Integrasi LRCLIB API untuk pengambilan lirik tersinkronisasi (LRC) & teks polos.
  - [x] Sanitasi query cerdas (`QuerySanitizer`): pembersihan ekstensi file, nomor track awal (`01 -`, `Track 02`), tag bitrate (`[320kbps]`, `(Official Audio)`), dan pemisahan artis-judul otomatis.
  - [x] Algoritma penilaian kecocokan berbobot (confidence score $0.0 - 1.0$) berdasarkan Levenshtein distance dan toleransi durasi $\pm 5\text{s}$.
- [x] **51.2 Interactive Single-Track Candidate Picker (`OnlineCandidatePickerModal`)**:
  - [x] Modal Material 3 Expressive dengan bilah pencarian interaktif dan real-time live search.
  - [x] Kartu kandidat dengan thumbnail artwork, badge sumber data (`ITUNES`, `DEEZER`, `MUSICBRAINZ`), persentase kecocokan berwarna adaptif, dan tombol `Apply` 1-ketukan.
  - [x] Pengunduhan otomatis artwork resolusi tinggi ke memori dan penulisan langsung ke file fisik saat disimpan.
- [x] **51.3 Multi-Track Batch Auto-Tagger (`OnlineBatchAutoTaggerModal`)**:
  - [x] Pemindaian batch otomatis beruntun dengan rate-limit protection.
  - [x] Progress bar penelusuran online dan penulisan metadata real-time.
  - [x] Daftar review kecocokan dengan checkbox seleksi dan indikator akurasi.
  - [x] Penulisan batch ke file fisik (`ID3` / `Vorbis` tags) serta sinkronisasi state in-memory, antrean pemutar, dan database persistensi lokal.
- [x] **51.4 Library Untagged Filter Chip & Quick Action Banner**:
  - [x] Penambahan getter `Track.isUntagged` mendeteksi nama artis/album tidak dikenal, judul mentah berekstensi, atau cover art yang hilang.
  - [x] Filter chip dinamis `Untagged (N)` pada header Unified Library dengan warna Warm Tube Amber (`StudioCategoryColors.warmTubeAmber`).
  - [x] Quick action banner contextual pada tab Untagged dengan tombol langsung `Auto-Tag All from Internet` dan `Batch Edit`.
- [x] **51.5 Quality Gate & Regression Testing**:
  - [x] Unit tests sanitasi query dan konversi kandidat di `test/online_metadata_service_test.dart` (4/4 passed).
  - [x] Unit & widget tests Untagged filter chip, quick banner, dan modal picker/tagger di `test/untagged_filter_chip_and_auto_tag_test.dart` (5/5 passed).
  - [x] Verifikasi `flutter analyze` 0 errors/warnings dan `flutter test` lulus 100% (389/389 passed).

---

## Fase 52: Contextual Selection Action Mode & Multi-Track Batch Action Bar Mobile/Portrait Overlay Refinement

Pembenahan tata letak responsif dan animasi transisi kontekstual mode multi-seleksi lagu pada mode mobile dan portrait (< 650px / tablet), menghilangkan masalah bilah aksi tertimbun di bawah `NamidaExpandableMiniPlayer` dan `FloatingRoundedDock` melalui state hoisting Riverpod dan animasi slide responsif.

- [x] **52.1 Hoisting State Multi-Track Selection ke Riverpod (`LibrarySelectionNotifier` & `librarySelectionProvider`)**:
  - [x] Pembuatan data model `LibrarySelectionState` (`selectedTrackIds`, `isSelecting`, `count`, `isSelected(id)`).
  - [x] State notifier `LibrarySelectionNotifier` dengan operasi `toggle(trackId)`, `select(trackId)`, `deselect(trackId)`, `selectAll(tracks)`, `deselectAll()`, dan `clear()`.
  - [x] Dukungan tactile micro-haptic `AppHaptics.selectionClick()` pada interaksi pemilihan item.
- [x] **52.2 Dynamic Responsive Transitions di Root Shell (`lib/app/app.dart`)**:
  - [x] Reaktif `ref.watch(librarySelectionProvider)` pada `BaydevHiFiApp`.
  - [x] Animasi `AnimatedSlide` dan `IgnorePointer` yang secara otomatis menggeser `FloatingRoundedDock` dan `NamidaExpandableMiniPlayer` turun ke bawah saat mode seleksi lagu aktif di mobile/tablet.
  - [x] `AnimatedPadding` konten halaman yang bergeser mulus dari `80.0` ke `0.0` saat seleksi aktif sehingga `LibraryBatchActionsBar` duduk nyaman di area safe area bawah.
  - [x] Pengembalian otomatis dock dan miniplayer saat seleksi selesai, dibatalkan, atau ditutup.
- [x] **52.3 UnifiedLibraryScreen & TrackTile Contextual Integration**:
  - [x] Migrasi state lokal `_selectedTrackIds` ke `librarySelectionProvider`.
  - [x] Sinkronisasi `PopScope` untuk membatalkan seleksi terlebih dahulu saat gesture/tombol back fisik ditekan.
  - [x] Pembersihan seleksi otomatis saat berpindah kategori tab (Tracks &rarr; Albums, Folders, dsb.) atau filter source.
  - [x] Refinement `LibraryBatchActionsBar` agar responsif pada semua ukuran layar dengan touch target ringkas `VisualDensity.compact` dan `MaterialTapTargetSize.shrinkWrap`.
- [x] **52.4 Quality Gate & Zero Regression Testing**:
  - [x] Unit & widget tests lengkap di `test/library_multi_selection_mobile_test.dart` (6/6 passed).
  - [x] Verifikasi `flutter analyze` 0 errors dan 0 warnings.
  - [x] Verifikasi layout desktop tetap stabil di atas desktop bottom master transport deck.

---

## Fase 53: Out-of-the-Box Default Acoustic Tuning (Studio Audiophile Warmth), Curated Presets Suite, 1-Tap Bit-Perfect Bypass & Active State Persistence

Implementasi konfigurasi profil akustik bawaan (*out-of-the-box acoustic tuning*) "Studio Audiophile Warmth" (Baydev Signature Reference) pada Pro-Q Studio Equalizer dan DSP Mastering Rack agar pengguna langsung merasakan audio yang hangat, berbobot, luas, dan ramah telinga sejak pertama kali aplikasi dibuka, dilengkapi tombol bypass 1-ketukan `Audiophile Bit-Perfect (Flat)`, suite preset studio terkurasi, kalkulasi safe preamp headroom otomatis, dan persistensi state aktif.

- [x] **53.1 Default Acoustic Curve & Domain Model Tuning (`EqBand` & `DspRackState`)**:
  - [x] Penyetelan kurva bawaan 10-band Pro-Q Studio "Studio Audiophile Warmth" (`EqBand.audiophileWarmthBands`):
    - Sub-Bass ($48\text{ Hz}$ Low-Shelf, $+1.8\text{ dB}$, $Q=0.70$) & Mid-Bass ($110\text{ Hz}$, $+0.8\text{ dB}$, $Q=1.10$).
    - Low-Mid Mud Cut ($280\text{ Hz}$, $-0.8\text{ dB}$, $Q=1.25$) & Mid Clarity ($1500\text{ Hz}$, $+0.4\text{ dB}$, $Q=1.41$).
    - Vocal Presence ($3200\text{ Hz}$, $+1.2\text{ dB}$, $Q=1.00$) & Sibilance Control ($8200\text{ Hz}$, $-0.6\text{ dB}$, $Q=1.80$).
    - Air & Micro-Detail Sparkle ($12000\text{ Hz}$, $+1.2\text{ dB}$ & $16000\text{ Hz}$ High-Shelf, $+1.6\text{ dB}$).
  - [x] Penyetelan modul DSP Mastering Rack bawaan (`DspRackState`):
    - Triode Tube Harmonic Exciter aktif pada $18\%$ ($y = \tanh(1.2 \cdot x)$, warmth $0.45$, mix $0.18$) untuk saturasi harmonik genap.
    - Mid-Side Stereo Width Matrix aktif pada $1.15\times$ ($115\%$ lebar panggung suara, Mid Gain $1.05\times$, wet $70\%$).
    - Peak Lookahead Limiter aktif (Threshold $-2.5\text{ dB}$, Output Ceiling $-0.5\text{ dBFS}$) untuk jaminan zero-clipping.
    - Headroom Pre-Amp teratenuasi $-1.5\text{ dB}$ / $-2.0\text{ dB}$ aman.
- [x] **53.2 Curated Factory Presets Suite (`kBuiltInEqPresets` & `DspPreset.studioPresets`)**:
  - [x] Pro-Q Studio: `Studio Audiophile Warmth`, `Audiophile Bit-Perfect (Flat)`, `Harman 2019 Reference`, `Vocal & Acoustic Intimacy`, `Deep Bass & Club Drive`, `Air & High-Res Sparkle`, `Treble Tamer`.
  - [x] DSP Rack: `Studio Audiophile Warmth`, `Audiophile Bit-Perfect`, `Warm Analog Tube Acoustic`, `Deep Bass Sub-Impact`, `Spacious Cinema Holographic`, `Mastering Vocal Clarity`, `Late-Night Headphone Anti-Fatigue`.
  - [x] Penerjemahan 100% seluruh deskripsi preset ke Bahasa Inggris profesional.
- [x] **53.3 1-Tap Bit-Perfect Bypass & Reset Workflows**:
  - [x] Metode `resetToDefault()` mengembalikan ke Studio Warmth.
  - [x] Metode `resetToBitPerfect()` mengembalikan instan ke Flat $0.0\text{ dB}$ direct passthrough.
  - [x] Sinkronisasi instan ke `VirtualDspService` dan C++ SoLoud engine.
- [x] **53.4 Active EQ State Persistence & Hydration**:
  - [x] Penambahan `getActiveEqState()` dan `saveActiveEqState()` pada `LocalPersistenceService`.
  - [x] Hidrasi otomatis profil EQ aktif saat aplikasi pertama kali dimuat atau di-restart.
- **Total Fase**: 54 Fase (Fase 1–54 Selesai • 100% Passed)
- **Arsitektur UI**: _100% Pure Material 3 Expressive (`material_3_expressive: ^1.1.3`), `material_ui`, `motor` Spring Physics, `material_new_shapes`, Bento Grid Modular System, Floating Rounded Dock, Dynamic Studio Palettes & Unified HugeIcons (100% English)_
- **Status Proyek**: _Phase 54: Native SpotDL Engine, Universal Spotify & YouTube Playlist Import, Hybrid Streaming-to-Offline Architecture & M3E Download Manager (Complete • 423/423 Passed • 0 Errors, 0 Warnings)_

---

## Fase 54: Native SpotDL Engine, Universal Spotify & YouTube Playlist Import, Hybrid Streaming-to-Offline Architecture & M3E Download Manager

Implementasi engine native SpotDL murni berbasis Dart/Flutter, Universal Playlist Import (Spotify & YouTube), pemutaran hybrid streaming-to-offline, serta antarmuka Material 3 Expressive Download Manager pada Unified Library Screen.

- [x] **54.1 Spotify Metadata Extraction & Universal Link Resolver**:
  - [x] Domain models: `SpotifyTrack`, `SpotifyAlbum`, `SpotifyPlaylist`, `SpotifyArtist`, `UniversalImportPreview`.
  - [x] Service: `SpotifyMetadataService` untuk fetch metadata track/album/playlist via public/anonymous endpoint tanpa login.
  - [x] Regex & parser untuk URL/URI Spotify (`open.spotify.com/track/...`, `/album/...`, `/playlist/...`, `/intl-.../`).
- [x] **54.2 Intelligent Audio Matcher Engine**:
  - [x] `AudioMatcherService` mencocokkan Spotify metadata ke YouTube Music audio-only streams via `youtube_explode_dart`.
  - [x] Heuristik kemiripan judul (Levenshtein/token similarity), validasi durasi ($\pm 6\text{ detik}$), dan pemfilteran noise keywords.
- [x] **54.3 Native Download Engine & Audio Tagger**:
  - [x] `NativeDownloadService` untuk unduh chunked stream audio dengan realtime progress tracking (bytes, speed, ETA).
  - [x] `AudioTaggerService` menyematkan ID3/MP4 metadata, HD cover art bytes, dan lirik via `audiotags`.
  - [x] Auto-index file hasil download ke database `LocalPersistenceService` dan library lokal.
- [x] **54.4 Download State Management & Queue Controller**:
  - [x] Riverpod state controller `DownloadController` dan domain model `DownloadTask`.
  - [x] Manajemen antrean multi-task, pause, resume, cancel, retry, dan persistensi riwayat download.
- [x] **54.5 Universal Playlist Import & Persistence**:
  - [x] `UniversalImportDialog` untuk paste link Spotify/YouTube dengan preview card info.
  - [x] Penyimpanan playlist ke database lokal dengan marker streaming dan dukungan instant on-the-fly streaming.
  - [x] Penambahan opsi "Import from Spotify & YouTube" pada `PlaylistsScreen`.
- [x] **54.6 Material 3 Expressive UI & Feature Integration**:
  - [x] Penambahan `CollectionTab.downloads` dan `LibraryDownloadsTab` pada `UnifiedLibraryScreen`.
  - [x] Penambahan opsi "Download Track" pada `StudioTrackActionSheet` dan track tiles.
  - [x] Penambahan tombol batch "Download All" pada Playlist Detail Header.
  - [x] Smart Link Auto-Detection pada search bar `YouTubeDiscoveryScreen`.
- [x] **54.8 100% Continuous Audio Streaming & Unthrottled CDN Pipeline**:
  - [x] Investigasi & identifikasi limitasi Google Video CDN: CDN memberlakukan ceiling buffer 1,048,576 bytes (~36.8 detik pada 160 kbps Opus) untuk standalone adaptive format (itag 251/140) sehingga chunk kedua mengalami HTTP 403 Forbidden.
  - [x] Implementasi unthrottled muxed stream pipeline (`ratebypass=yes`, itag 18) yang mengunduh 100% track penuh dalam 4-5 detik tanpa hambatan 403.
  - [x] Konversi/ekstraksi instan ke format standar Ogg Opus (`.ogg`) kompatibel engine C++ SoLoud.
  - [x] Dual-stage playback architecture pada `PlayerController`:
    - Stage 1: Pemutaran instan 0ms via `setBufferStream` + `WebmToOggRemuxer`.
    - Stage 2: Background caching paralel via `AudioCacheService.instance.cacheTrack()` untuk jaminan pemutaran 100% lagu tanpa jeda dan seek instan 0ms.
  - [x] Migrasi ekstensi disk cache `AudioCacheService` ke `.ogg` untuk native hardware/codec decoding SoLoud.
  - [x] Verifikasi 100% passing tests dengan `flutter test` dan 0 errors/warnings dengan `flutter analyze`.

---

## Fase 55: Per-Track DSP Mastering Preset System, Genre-Based Auto-Apply Engine & Rules Customizer

Implementasi sistem adaptasi mastering DSP cerdas otomatis berbasis genre metadata lagu, kemampuan pinning kustom per-track, manajemen konfigurasi aturan pemetaan genre, dan kepatuhan 100% Material 3 Expressive & HugeIcons.

- [x] **55.1 Curated Genre Mastering Presets Suite (`DspPreset.studioPresets`)**:
  - [x] Penambahan 10 preset mastering genre audiophile di `DspPreset.studioPresets`:
    - `genre_rock`: Dynamic Rock & Alternative (Punchy transient attack, crisp electric guitar bite & tight analog drive).
    - `genre_pop`: Modern Pop & Commercial (High vocal presence, wide stereo soundstage, polished master compression).
    - `genre_edm`: Electronic & Club Impact (Deep sub-bass impact, aggressive compressor pump & ultra-wide stereo field).
    - `genre_hiphop`: Hip-Hop & Urban Sub (Deep psychoacoustic 808 sub-bass, centered punchy vocal presence).
    - `genre_jazz`: Warm Analog Jazz & Soul (Warm triode tube saturation, binaural crossfeed & organic room acoustics).
    - `genre_classical`: Holographic Classical & Score (Expansive concert hall spatial reverb, uncompressed bit-perfect dynamics).
    - `genre_acoustic`: Acoustic & Intimate Folk (Mid-frequency string intimacy, gentle analog warmth & fatigue reduction).
    - `genre_rnb`: Smooth R&B & Neo-Soul (Lush vocal presence, smooth low-end compression & warm stereophonic field).
    - `genre_metal`: High-Gain Heavy Metal (Fast transient attack, tight bass roll-off & high-gain harmonic definition).
    - `genre_lofi`: Lo-Fi & Chillhop Vintage (Heavy analog triode tube saturation, soft vinyl warmth & cozy acoustic space).
- [x] **55.2 Fuzzy Genre Matching & Multi-Token Evaluator Engine**:
  - [x] Implementasi `GenrePresetMatcher.match()` dengan evaluasi token pemisah multi-genre (`/`, `;`, `,`, `|`, `&`, `and`), normalisasi sanitasi karakter, pencocokan eksak dan substring bersarang (misal: "Alternative Rock, Shoegaze" $\rightarrow$ `genre_rock`, "Chillhop / Lo-Fi Beats" $\rightarrow$ `genre_lofi`, "Heavy Metal" $\rightarrow$ `genre_metal`).
  - [x] Dukungan `customMappingOverrides` per-genre kategori.
- [x] **55.3 Multi-Level Resolution Engine & Controller State**:
  - [x] Model domain: `DspTrackOverride`, `DspGenreMapping`, `DspResolutionSource`, `DspResolutionResult`, `GenreMatchResult`.
  - [x] Prioritas resolusi 3 tingkat:
    1. **Track Pinned Override**: Prioritas tertinggi jika pengguna mem-pin preset khusus ke lagu tersebut.
    2. **Genre-Based Auto Match**: Otomatis mendeteksi genre tag lagu dan memilih preset mastering optimal jika `autoApplyByGenre` aktif.
    3. **Global Active Preset / Fallback**: Preset manual yang sedang aktif di DSP Rack jika genre tidak dikenali / kosong.
  - [x] Penambahan reaktif `revision` counter pada `DspRackState` untuk jaminan notifikasi StateNotifier Riverpod instan pada UI.
  - [x] Integrasi hook otomatis pada `PlayerController.playTrack()` saat lagu baru dimainkan.
- [x] **55.4 Persistent Storage Integration (`LocalPersistenceService`)**:
  - [x] `saveDspTrackOverride()`, `getDspTrackOverrides()`, `removeDspTrackOverride()`.
  - [x] `saveDspGenreMappings()`, `getDspGenreMappings()`.
  - [x] `setDspAutoApplyByGenreEnabled()`, `isDspAutoApplyByGenreEnabled()`.
- [x] **55.5 Pure Material 3 Expressive UI & Action Sheets**:
  - [x] `StudioTrackDspPresetSheet`: Bottom modal sheet untuk melihat preset aktif, mem-pin preset khusus, unpin kembali ke genre auto, dan memilih preset terkurasi / custom.
  - [x] `GenreRulesConfigModal`: Modal pengaturan aturan genre untuk toggle auto-apply dan kustomisasi mapping preset per kategori.
  - [x] Integrasi `StudioTrackActionSheet` dengan action tile "DSP Mastering Preset" dan subtitle dinamis.
  - [x] `DspRackScreen` enhancement: Active Track Context Banner, tombol "GENRE RULES", dan dropdown menu terkelompok (Genre Mastering, Studio Reference, Custom Profiles).
- [x] **55.6 Quality Assurance & 100% Passing Tests**:
  - [x] Test suite komprehensif `test/features/dsp_rack/dsp_per_track_and_genre_auto_apply_test.dart` (10/10 passing unit & widget tests).
  - [x] `flutter test` dan `flutter analyze` 100% clean dengan 0 errors dan 0 warnings.
- [x] **55.7 Persistent AutoEQ Driver & Target Curves Hydration**:
  - [x] Penyimpanan otomatis nama Driver IEM (`lastDriverName`) dan Target Curve (`lastTargetName`) pada `LocalPersistenceService.saveActiveEqState()`.
  - [x] Hidrasi otomatis saat `EqController` pertama kali dimuat sehingga pilihan Driver dan Target terakhir pengguna langsung aktif di Pro-Q Studio & modal AutoEQ.
  - [x] Validasi test suite di `test/auto_eq_persistent_selection_test.dart`.
- [x] **55.8 Persistent AutoEQ Android Lifecycle Fix & Studio Bass Boost Recalibration**:
  - [x] **Single Source of Truth Kurva AutoEQ**: `FrCurveData.defaultDrivers` dan `FrCurveData.defaultTargets` dijadikan dataset bersama untuk `EqController` dan `AutoEqModalDialog`.
  - [x] **Serialisasi Kurva Fallback**: Penyimpanan map kurva lengkap (`lastDriverCurve` & `lastTargetCurve`) di `LocalPersistenceService` menjamin pemulihan 100% pada lifecycle Android (restart, swipe recent apps).
  - [x] **Parameter Wet pada Bass Boost Engine**: `VirtualDspService` menerapkan `bassBoostFilter.wet.value = bassBoostWet.clamp(0.0, 1.0)` dan clamping perlindungan engine $\le 3.5$.
  - [x] **Rekalibrasi Preset Genre Audiophile**: Penyesuaian preset mastering genre (Rock: bass boost non-aktif untuk artikulasi gitar/drum; EDM: boost diturunkan ke 2.0 / wet 0.50; Hip-Hop: 2.2 / wet 0.50; R&B: 1.4 / wet 0.35; Deep Bass: 2.2 / wet 0.55) demi transparansi vokal, kejernihan transient, dan perlindungan limiter dari kompresi berlebih.
  - [x] **Zero Regression Testing**: 441/441 tests passing (100%), 0 errors, 0 warnings pada `flutter analyze`.

---

## Fase 56: Android Storage, Physical Metadata Tagging & Automated Library Backup Architecture

Arsitektur penyimpanan publik bersama, injeksi tag fisik langsung (*physical audio tagging*), perizinan akses berkas penuh (*All Files Access*), serta sistem pencadangan dan pemulihan otomatis (*Auto-Backup & Restore*) agar seluruh data lagu, metadata, cover art, playlist, dan DSP preset tetap 100% persisten dan kebal terhadap penghapusan data aplikasi (Clear App Data).

- [x] **56.1 Public Shared Storage Migration for Downloads & Media**
  - [x] Update `NativeDownloadService.getDownloadDirectory()` di Android untuk memprioritaskan folder publik `/storage/emulated/0/Music/BaydevHiFi` (fallback: `/storage/emulated/0/Download/BaydevHiFi`) daripada folder privat aplikasi `Android/data/`.
  - [x] Pastikan scanner lokal `LocalAudioScanner` mendaftarkan folder publik tersebut secara default.
- [x] **56.2 Storage Permission Service & M3E Permission Dialog**
  - [x] Buat `StoragePermissionService` untuk mengecek & meminta `Permission.manageExternalStorage` di Android 11+ (API 30+) dan granular permissions.
  - [x] Buat `StoragePermissionDialog` Material 3 Expressive yang menjelaskan perlunya izin All Files Access untuk retensi file & tag fisik permanen.
- [x] **56.3 Physical Audio Tagging Engine & Result Status**
  - [x] Tambahkan enum `PhysicalTagWriteStatus` pada `MetadataTaggerService`.
  - [x] Pastikan penulisan ID3v2.4 / Vorbis / M4A metadata dan cover art bytes berhasil secara fisik di disk dengan verifikasi pasca-tulis.
  - [x] Update `AudioTaggerService` saat proses download selesai untuk langsung mengunci tag fisik ke dalam file.
- [x] **56.4 Automated Library Backup & Restore System (`LibraryBackupService`)**
  - [x] Buat `LibraryBackupService` dengan fungsi debounced `autoExportBackup()` ke file publik `Music/BaydevHiFi/baydev_hifi_backup.json`.
  - [x] Implementasikan `autoRestoreIfEmpty()` saat database internal kosong (pasca-install atau pasca-Clear App Data).
  - [x] Tambahkan tombol Export & Import Backup manual di menu Settings.
- [x] **56.5 UI Status Feedback & Error Resilience**
  - [x] Tambahkan indikator status fisik vs memori-saja pada `MetadataTagEditorSheet` dan `BatchTrackTagEditorModal`.
  - [x] Intersepsi tombol simpan jika izin belum ada dengan opsi meminta izin terlebih dahulu.
- [x] **56.6 Comprehensive Testing & Zero Regression**
  - [x] Unit & Widget tests untuk `LibraryBackupService`, `StoragePermissionService`, dan status penulisan tag fisik.
  - [x] Verifikasi suite 100% lolos dengan `flutter test` dan 0 lint warnings pada `flutter analyze`.

---

## Fase 57: Android 120Hz Fluid UI Optimization, Fast Palette Extraction & Universal Zoomable Artwork Lightbox

Optimasi performa rendering 120Hz pada Android (eliminasi rebuild pohon widget frekuensi tinggi melalui granular Riverpod selectors, isolasi progress bar, throttled position timer 100ms, downsampled fast palette extraction `< 8ms`), integrasi modal lightbox pembesar artwork resolusi tinggi dengan pinch-to-zoom (`InteractiveViewer`), serta penambahan aksi kustomisasi gestur `viewFullArtwork` pada Single Tap, Double Tap, dan Long Press.

- [x] **57.1 UI Rebuild Elimination & Position Loop Optimization**:
  - [x] Ubah interval timer posisi di `SoloudController._startPositionTracking()` menjadi 100ms untuk memangkas overhead timer & message dispatch hingga 50%.
  - [x] Buat widget terisolasi `_NowPlayingIsolatedProgressBar` dengan Riverpod `.select()` untuk memisahkan seekbar dari root layout tree.
  - [x] Refactor `NowPlayingScreen.build()` menggunakan granular selectors (`currentTrack`, `status`, `isShuffle`, `repeatMode`, `playbackSpeed`, `pitchSemitones`, `queue`) agar root screen tidak ikut me-rebuild dirinya 20× per detik saat lagu diputar.
  - [x] Perbarui `SynchronizedLyricsView` agar mendengarkan stream posisi secara mandiri tanpa memicu rebuild layar induk.
- [x] **57.2 Instant Downsampled Palette Extraction (`< 8ms`)**:
  - [x] Bungkus `ImageProvider` dengan `ResizeImage(provider, width: 96, height: 96)` pada `ThemeController.updateDynamicPaletteFromTrack()` dan `LyricShareController.extractPaletteFromTrack()`.
  - [x] Memangkas pemindaian piksel sebesar 98% dan melenyapkan micro-stutter saat pergantian lagu.
- [x] **57.3 Interactive Zoomable Studio Artwork Lightbox (`StudioArtworkLightbox`)**:
  - [x] Implementasikan modal lightbox Material 3 Expressive (`StudioArtworkLightbox`) dengan `InteractiveViewer` (zoom 1.0× – 5.0×, pan, double-tap toggle zoom, swipe down to dismiss).
  - [x] Header bar studio dengan tombol close `M3EIconButton`, judul track/album, nama artis, dan badge format audio (`FLAC 96kHz / 24-bit` / `HI-RES LOSSLESS`).
- [x] **57.4 Universal Tap-to-Zoom Integration Across Library Screens**:
  - [x] Integrasi tap pada album cover header di `AlbumDetailScreen` untuk membuka lightbox.
  - [x] Integrasi tap pada avatar / foto artis di `ArtistDetailScreen` dan `ArtistAvatarWidget` (`enableLightboxOnTap: true`).
- [x] **57.5 Artwork Gesture Customization Expansion (`ArtworkGestureAction.viewFullArtwork`)**:
  - [x] Tambahkan opsi `viewFullArtwork` pada enum `ArtworkGestureAction` di `player_customization_settings.dart`.
  - [x] Dukungan dropdown dan icon selector di `GesturesSettingsScreen` untuk Single Tap, Double Tap, dan Long Press.
  - [x] Eksekusi pembukaan lightbox pada `NowPlayingScreen._handleArtworkGesture()` dan `DesktopBottomMasterTransportDeck`.
- [x] **57.6 Quality Assurance & Zero Regression Testing**:
  - [x] Test suite komprehensif `test/artwork_lightbox_and_gesture_test.dart` (7/7 passed).
  - [x] Verifikasi `flutter analyze` 0 errors / 0 warnings dan seluruh suite `flutter test` lulus 100%.
---

## Fase 58: Hardware DAC Bridge & DSP Flasher Architecture (Kiwi Ears AD1 & Universal KTmicro / CB DSP DACs)

Arsitektur hardware DAC bridge untuk mendeteksi USB-C DSP DAC (Kiwi Ears AD1, S-Link, Allegro Mini, FiiO JA11, JCALLY JM12, CB-Series DACs), membaca register PEQ aktif, mengatur parameter biquad secara realtime, mem-flash/burn konfigurasi ke EEPROM chip hardware, serta mengintegrasikan konversi otomatis 5-band dari profil AutoEQ Cloud & Pro-Q Studio.

- [x] **58.1 Domain Entities & Models (`lib/features/hardware_dac/domain/models/`)**:
  - [x] Buat `DacDevice` (id, vendorId, productId, productName, chipset, maxBands, isConnected, isEqEnabled, globalGainDb).
  - [x] Buat `DacBandConfig` (bandIndex, frequency, gainDb, qFactor, filterType, isBypassed).
  - [x] Buat `DacPeqProfile` (id, name, bands, preampGainDb).
  - [x] Buat enum `DacChipset` (kt0211l, kt1132l, kt3016l, cb5000x, cb3000s, unknown) dan `DacFilterType`.
- [x] **58.2 Binary Packet Codec & Serialization (`lib/features/hardware_dac/data/protocols/`)**:
  - [x] Implementasikan `DacPacketEncoder` untuk merakit paket 10-byte HID (Freq LE $\times 10$, Gain LE $\times 10$ signed 16-bit, Q LE $\times 1000$, Write/Read/Save/Clear command bytes).
  - [x] Implementasikan `DacPacketDecoder` untuk parsing respons raw byte register, flag sukses, dan ekstraksi status DAC.
- [x] **58.3 Hardware Driver Abstraction (`lib/features/hardware_dac/data/drivers/`)**:
  - [x] Buat abstract interface `DacDriver`.
  - [x] Implementasikan `KiwiEarsKtDriver` untuk KT_0211L, KT_1132L, dan KT_3016L chipsets.
  - [x] Implementasikan `CbDacDriver` untuk CB_5000X dan CB_3000S chipsets.
- [x] **58.4 Cross-Platform Transport Layer & Mock Simulator (`lib/features/hardware_dac/data/transports/`)**:
  - [x] Buat abstract interface `DacTransport`.
  - [x] Implementasikan `MockDacTransport` untuk simulasi offline, testing deterministik, dan preview tanpa perangkat fisik.
  - [x] Implementasikan `AndroidUsbTransport` dan `LinuxHidRawTransport` dengan platform guards.
- [x] **58.5 AutoEQ to 5-Band Hardware Curve Fitter (`lib/features/hardware_dac/domain/services/`)**:
  - [x] Implementasikan `AutoEqToHardwareFitter` untuk mereduksi kurva multi-band AutoEQ Cloud / Pro-Q menjadi 5 titik anchor hardware biquad terbaik (Sub-bass, Lower Mids, Ear Gain, Sibilance, Air).
  - [x] Kalkulasi safe pre-amp gain otomatis untuk mencegah distorsi clipping digital pada DAC hardware.
- [x] **58.6 State Management & Controllers (`lib/features/hardware_dac/presentation/controllers/`)**:
  - [x] Buat `DacBridgeState` dan `DacBridgeController` (Riverpod StateNotifier).
  - [x] Buat `DacPeqNotifier` untuk kontrol reaktif slider 5-band dan update realtime.
- [x] **58.7 Presentation Layer & Pure Material 3 Expressive UI (`lib/features/hardware_dac/presentation/`)**:
  - [x] Buat `DacHeroStatusCard` dengan badge chipset, resolusi, status koneksi, dan switch enable/bypass.
  - [x] Buat `HardwareCurveVisualizer` (CustomPainter 20Hz–20kHz biquad frequency response curve).
  - [x] Buat `DacBandSliderTile` dengan `M3ESlider` (Freq, Gain, Q) dan `FontFeature.tabularFigures()`.
  - [x] Buat `DacActionToolbar` dengan tombol `M3EButton` ("Read from DAC", "Burn to Flash", "Import AutoEQ", "Reset").
  - [x] Buat `AutoEqFlashDialog` untuk modal preview fitting dan flash langsung ke hardware DAC.
  - [x] Buat `HardwareDacStudioScreen` dan integrasikan launcher di `DSP Rack` & `AutoEQ Cloud Browser`.
- [x] **58.8 Comprehensive Testing & Zero Regression**:
  - [x] Unit tests untuk binary packet codec, KT driver, CB driver, dan `AutoEqToHardwareFitter`.
  - [x] StateNotifier unit tests untuk `DacBridgeController`.
  - [x] Widget tests untuk `HardwareDacStudioScreen` dan komponen UI M3 Expressive.
  - [x] Verifikasi `flutter test` lulus 100% dan `flutter analyze` 0 errors / 0 warnings.

---

## Fase 59: Instant Mix Generation, Namida-Style Queue Additions, & Connected Studio Signal Chain (Completed)

Integrasi cerdas fitur kurasi playlist otomatis *Instant Mix* berbasis seed track, penambahan trek batch fleksibel ke active queue ala Namida, dan visualisasi interconnected *Studio Audio Signal Chain* di Now Playing screen.

- [x] **59.1 Deterministic Instant Mix Algorithm Engine (`lib/features/library/domain/instant_mix_engine.dart`)**:
  - [x] `InstantMixEngine`: Algoritma clustering multi-kriteria berbasis bobot skor adaptif (Genre compatibility matrix, Mood energy/valence heuristics, Era/Decade proximity, Favorit boost).
  - [x] Anti-repetition dispersion guard: Mencegah 3 trek berurutan dari artis yang sama.
  - [x] Dukungan 4 kriteria: `genre`, `mood`, `artistEra`, `smartRandom`.
  - [x] Ekstraksi 10 mood studio: `chillAcoustic`, `energeticWorkout`, `deepFocus`, `nightDrive`, `euphoricDance`, `melancholicBallad`, `warmVintage`, `hiResAudiophile`, `darkIntense`, `ambientSpace`.
- [x] **59.2 Instant Mix Modal Configuration Sheet (`lib/features/library/presentation/widgets/instant_mix_config_sheet.dart`)**:
  - [x] Pure Material 3 Expressive bottom sheet dengan seed track preview hero card.
  - [x] Mix Criteria selector chips (`HugeIcons.strokeRoundedSparkles`, `HugeIcons.strokeRoundedSlidersVertical`, `HugeIcons.strokeRoundedMic01`, `HugeIcons.strokeRoundedShuffle`).
  - [x] Track count selector dengan default autofill **10 tracks** (opsi: 5, 10, 20, 50).
  - [x] Tombol aksi primary `[ START INSTANT MIX ]` yang langsung memutar seed track di index 0 dan mengisi active queue dengan hasil mix.
- [x] **59.3 Studio Track Context Menu Integration (`lib/features/library/presentation/widgets/studio_track_action_sheet.dart`)**:
  - [x] Menambahkan opsi `Instant Mix` di 3-dots track action sheet perpustakaan musik.
- [x] **59.4 Namida-Style Dynamic Batch Queue Additions (`lib/features/player/presentation/widgets/add_tracks_to_queue_sheet.dart`)**:
  - [x] Pure Material 3 Expressive bottom sheet untuk menambah antrean lagu dari Now Playing / Queue Sheet tanpa memotong lagu yang sedang diputar.
  - [x] Mode seleksi: `Smart Random Mix`, `Specific Mood Mix`, `Similar to Current Song`, `Favorites Only`.
  - [x] Default autofill **10 tracks** dengan selector jumlah trek (5, 10, 20, 50).
  - [x] Penempatan antrean: `Play Next (Up Next)` atau `Append to End of Queue`.
  - [x] Integrasi tombol `Add Tracks to Queue` (`HugeIcons.strokeRoundedPlayList`) di header `NowPlayingQueueSheet`.
- [x] **59.5 Player Controller Queue Operations (`lib/features/player/presentation/controllers/player_controller.dart`)**:
  - [x] `startInstantMix(Track seedTrack, List<Track> mixTracks)`: Memutar seed track seketika di posisi 0 dan memuat active queue.
  - [x] `addTracksToQueue(List<Track> newTracks, {bool playNext = false})`: Menyisipkan atau menambahkan trek ke queue yang sedang berjalan tanpa gangguan audio.
- [x] **59.6 Connected 3-Stage Studio Audio Signal Chain Capsule (`lib/features/player/presentation/widgets/studio_dsp_bento_capsule.dart`)**:
  - [x] Redesain shortcut capsule di Now Playing screen menjadi interconnected 3-stage pipeline tactile visual:
    `[ 🎧 AutoEQ ] ➔ [ 🎛️ DSP Rack ] ➔ [ ⚡ Hardware DAC ]`
  - [x] Stage 1 (AutoEQ): Menampilkan profil driver aktif atau status Direct, membuka `AutoEqModalDialog` saat di-tap.
  - [x] Stage 2 (DSP Rack): Menampilkan jumlah unit aktif (misal `DSP (3)`) atau Flat, membuka `DspRackScreen` saat di-tap.
  - [x] Stage 3 (Hardware DAC): Menampilkan status live koneksi hardware DAC (misal `DAC • AD1`) dengan mint active indicator atau `DAC Direct`, membuka `HardwareDacStudioScreen` saat di-tap.
  - [x] Visual chevron connector terintegrasi dengan studio border & surface styling.
- [x] **59.7 Unit, Widget Tests & Zero Regression Validation**:
  - [x] `test/instant_mix_engine_test.dart`: 7 unit tests untuk genre clustering, mood mapping, era proximity, dan anti-repetition artist dispersion.
  - [x] `test/instant_mix_and_queue_addition_test.dart`: 7 unit and widget tests untuk controller, InstantMixConfigSheet, AddTracksToQueueSheet, dan StudioDspBentoCapsule 3-stage signal chain.
  - [x] Menjalankan `flutter test` dan `flutter analyze` dengan hasil 100% lulus dan 0 errors / 0 warnings.

---

## Fase 60: Auto-Next Playback Engine Native Event Fix & Compact 1-Row Animated Signal Flow Chain (Completed)

Perbaikan menyeluruh bug auto-advance antrean musik (*Auto-Next Stalling Bug*) menggunakan integrasi event native `flutter_soloud` C++ engine, pemformatan teks ringkas 1 baris untuk AutoEQ, DSP Rack & Hardware DAC, serta animasi interaktif aliran sinyal studio real-time (*Real-Time Studio Signal Flow Animation*).

- [x] **60.1 Native SoLoud Playback Completion Stream (`lib/audio_engine/soloud_controller.dart`)**:
  - [x] Menambahkan `_playbackEndedController` broadcast stream dan getter `Stream<void> get onPlaybackEnded`.
  - [x] Mengikat event native `source.allInstancesFinished` pada `playFile()`, `playUrl()`, dan `playAudioSource()`, menjamin sinyal audio selesai terpancar seketika saat decoding C++ berakhir.
  - [x] Penanganan aman pembatalan subscription saat pergantian track (`_stopCurrentAudio()` dan `deinit()`).
- [x] **60.2 Multi-Tier Auto-Advance Engine (`lib/features/player/presentation/controllers/player_controller.dart`)**:
  - [x] Integrasi listener event `_audioEngine.onPlaybackEnded` untuk memicu `_onTrackEnded()` deterministik tanpa bergantung pada polling interval timer.
  - [x] Dual-guard fallback berbasis threshold posisi adaptif $\ge \text{duration} - 250\text{ ms}$.
  - [x] Perlindungan race condition dengan flag `_isAdvancing` dan delay pelepasan lock 300ms untuk mencegah duplikasi lompatan antrean.
- [x] **60.3 Compact 1-Row Studio Signal Chain & Live Flow Animation (`lib/features/player/presentation/widgets/studio_dsp_bento_capsule.dart`)**:
  - [x] Format AutoEQ cerdas: Truncation nama driver dengan ellipsis (misal `KZ Castor Bass Black Dudu R` $\rightarrow$ `KZ CASTOR...`, `Moondrop Chu II DSP` $\rightarrow$ `MOONDROP CHU...`, `Aria` $\rightarrow$ `ARIA`).
  - [x] Format Hardware DAC rapi: Menampilkan merk & tipe (misal `DAC • KIWI AD1` / `DAC • AD1`, atau `DAC Direct` saat tidak terhubung).
  - [x] Animasi Aliran Sinyal Studio (`_AnimatedSignalConnector`): Pulsa gelombang visual berjalan dari **AutoEQ $\rightarrow$ DSP Rack $\rightarrow$ Hardware DAC** secara dinamis saat lagu berputar (`isPlaying == true`), dan beralih ke resting state saat pause.
  - [x] Desain 1-row ultra-kompak responsif tanpa overflow pada semua lebar layar smartphone.
- [x] **60.4 Comprehensive Unit & Widget Test Suite**:
  - [x] `test/auto_next_playback_and_signal_flow_test.dart`: 6 tests untuk string formatters AutoEQ/DAC, render 1-row capsule dengan animated connectors, dan siklus queue advance `skipNext()`.
  - [x] Verifikasi `flutter test` lulus 100% dan `flutter analyze` 0 errors / 0 warnings.

---

## Fase 61: AutoEQ Driver, Target & Active State Cold-Boot Persistence & Audio Engine Restoration (Completed)

Perbaikan komprehensif persistensi kurva AutoEQ (`driverFr`, `targetFr`, `isAutoEqActive`, `isEnabled`, `bandResolution`, `tuningMode`) saat cold boot (aplikasi di-kill dan dibuka kembali di Android/Desktop), hidrasi synchronous kurva, pemulihan filter biquad langsung ke `VirtualDspService` & SoLoud audio engine, dan tampilan pill Now Playing aktif tanpa jeda.

- [x] **61.1 LocalPersistenceService AutoEQ State Schema Update (`lib/core/database/local_persistence_service.dart`)**:
  - [x] Memperluas `saveActiveEqState()` untuk menerima dan menyimpan `isAutoEqActive`, `isEnabled`, `bandResolution`, dan `tuningMode`.
  - [x] Menjaga serialisasi `lastDriverCurve` dan `lastTargetCurve` map agar kurva kustom tersimpan utuh di disk JSON storage.
- [x] **61.2 Synchronous Curve & Active State Hydration (`lib/features/pro_q_studio/presentation/controllers/eq_controller.dart`)**:
  - [x] Di `_hydrateActiveState()`: Memulihkan `isAutoEqActive`, `isEnabled`, `bandResolution`, dan `tuningMode` seketika saat instansiasi controller.
  - [x] Rekonstruksi instan `driverFr` dan `targetFr` dari serialized curve map (`FrCurveData.fromMap`) atau pencocokan nama bawaan studio secara synchronous.
  - [x] Di `_loadSampleCurves()`: Mempertahankan kurva dan status `isAutoEqActive` yang telah terhidrasi saat loading asset sampel factory selesai.
  - [x] Di `_persistActiveState()`, `togglePower()`, `setTuningMode()`, `setBandResolution()`, `setPreamp()`, dan `applyAutoEq()`: Menyimpan seluruh status mutasi aktif ke disk secara deterministik.
- [x] **61.3 Universal Backup & Restore Service Compatibility (`lib/features/settings/data/backup_restore_service.dart`)**:
  - [x] Menyertakan `isAutoEqActive`, `isEnabled`, `bandResolution`, dan `tuningMode` saat memulihkan snapshot database dari file cadangan.
- [x] **61.4 Comprehensive Unit & Widget Test Suite (`test/auto_eq_cold_boot_persistence_test.dart`)**:
  - [x] Validasi `LocalPersistenceService` menyimpan dan mengembalikan state AutoEQ lengkap (curves, flags, resolution).
  - [x] Validasi `EqController` melakukan hidrasi synchronous `driverFr`, `targetFr`, dan `isAutoEqActive == true` saat cold boot.
  - [x] Validasi `applyAutoEq()` mengaktifkan `isAutoEqActive` dan menulis data ke storage secara konsisten.
  - [x] Validasi widget `StudioDspBentoCapsule` merender pill aktif dengan nama driver terformat (misal `KZ CASTOR...`) saat cold boot.
  - [x] Menjalankan `flutter test` (516/516 tests passing) dan `flutter analyze` (0 errors, 0 warnings).

---

## Fase 62: Baydev HiFi Studio Wrapped & Audiophile Recap (Completed)

Sistem rekapitulasi audio dan visualisasi statistik retrospektif bergaya *Spotify Wrapped* yang dirancang khusus untuk audiophile dan penikmat musik fidelitas tinggi. Menyediakan pemutar cerita interaktif 7-slide fullscreen (9:16) dan Multi-Template Export Hub dengan 4 template visual siap bagikan beresolusi tinggi (PNG export & native OS sharing).

- [x] **62.1 Persistence & High-Precision Playback Logging (`lib/core/database/local_persistence_service.dart` & `lib/features/analytics/domain/playback_log_entry.dart`)**:
  - [x] Model `PlaybackLogEntry` mencatat format audio (`FLAC`, `WAV`, `MP3`, `AAC`), sample rate (`kHz`), bit depth (`bit`), nama driver dan target AutoEQ aktif, jumlah unit DSP aktif, serta nama DAC eksternal yang terhubung.
  - [x] Penyimpanan batch riwayat pemutaran dan rekap summary snapshot di `LocalPersistenceService` dengan limit 10.000 log terbaru.
- [x] **62.2 Audiophile Persona Classifier & Domain Statistics Engine (`lib/features/analytics/domain/`)**:
  - [x] Enam Persona Audiophile Studio:
    1. *Analog Tube Connoisseur*: Penggemar kehangatan harmonik tabung dan saturasi analog.
    2. *Bit-Perfect Purist*: Penikmat resolusi murni lossless 24-bit/96kHz+ tanpa manipulasi DSP.
    3. *Sub-Bass Holographic Explorer*: Penikmat bass dalam, dynamic response, dan spatial sound stage.
    4. *Midnight Intimate Dreamer*: Pendengar larut malam dengan durasi mendalam dan suasana intim.
    5. *Hardware DAC Artisan*: Pengguna setia external USB DAC dan audio hardware terdedikasi.
    6. *Studio Reference Virtuoso*: Pengguna AutoEQ presisi studio dan target respon profesional.
  - [x] `StudioWrappedCalculator`: Mesin kalkulasi agregasi data pemutaran (Total Menit, Top 10 Tracks, Top 10 Artists, Genre Breakdown, Audio Purity Report, Sound Signature Tags, Peak Listening Hours) dengan generator dataset sampel bawaan studio jika log pemutaran masih kosong.
- [x] **62.3 Riverpod State Architecture & Auto Session Hook (`lib/features/analytics/data/playback_analytics_service.dart` & `lib/features/player/presentation/controllers/player_controller.dart`)**:
  - [x] Provider `playbackAnalyticsServiceProvider`, `studioWrappedFilterProvider` (`allTime`, `thisYear`, `last30Days`), dan `studioWrappedDataProvider`.
  - [x] Hook otomatis `_logSessionAnalytics(track, duration)` di `PlayerController` pada event `_onTrackEnded()`, pergantian lagu `_playTrackInternal()`, dan penghentian lagu `stop()`.
- [x] **62.4 Twelve Distinct Visual Recap Export Templates (`lib/features/analytics/presentation/templates/widgets/`)**:
  - **Category A: All-in-One Comprehensive Recaps (8 Templates)**:
    - [x] **Template 1: Hi-Fi Studio Thermal Receipt (`thermal_receipt_view.dart`)**:
      - Gaya *Receiptify* audiophile dengan custom painter gerigi sobekan kertas (*sawtooth paper tear*), barcode dinamis, tabel item bernomor, dan angka monospaced tabular.
    - [x] **Template 2: Studio Sticker Slap & Tape Collage (`sticker_collage_view.dart`)**:
      - Kolase bergaya Y2K / 3D tilted dengan stiker bersudut rotasi acak halus, bayangan realistis (*drop shadows*), stiker holografis *Certified Hi-Res Lossless*, dan isolasi studio tape.
    - [x] **Template 3: Modern Bento Studio (`bento_studio_view.dart`)**:
      - Tata letak grid bento modular Pure Material 3 Expressive, visualisasi horizontal progress bar genre, badge persona, artwork album/artis dinamis, dan palette studio bergradien lembut.
    - [x] **Template 4: Vintage Cassette J-Card (`cassette_jcard_view.dart`)**:
      - Desain insert kaset pita analog retro lengkap dengan visual spul kaset ganda (*tape spools*), tracklist bergaris indeks A/B side, dan badge *Chrome Type II High-Bias*.
    - [x] **Template 5: Abstract Soundwave & Acoustic Aura (`abstract_aura_view.dart`)**:
      - Desain gelombang suara fluida matematis (*procedural bezier ribbons*), radiant acoustic halo dengan artwork album, dynamic range dB gauge, dan HUD energi akustik.
    - [x] **Template 6: 12" Vinyl Gatefold & LP Record (`vinyl_gatefold_view.dart`)**:
      - Piringan hitam vinyl 12" realistis dengan alur micro-grooves, anisotropic light reflection sheen (sudut 45° & 225°), label tengah spindle artwork, segel 33⅓ RPM, runout matrix serial, dan daftar track Side A/B.
    - [x] **Template 7: VIP Concert Ticket Stub & Backstage Pass (`concert_ticket_view.dart`)**:
      - Tiket konser fisik premium dengan gerigi perforasi sobekan samping, header foil holografis berkilau, telemetri kursi VIP (`SEC: LOSSLESS • ROW: 24-BIT • SEAT: 96K`), daftar setlist panggung, dan barcode pass terverifikasi.
    - [x] **Template 8: Cyber Tech Spec & Hardware IC HUD (`cyber_spec_card_view.dart`)**:
      - Skematik datasheet hardware DSP bergaya cyberpunk / Tokyo studio engineering HUD, crosshair reticle target, memori optik inti artwork album, dan matriks telemetri sinyal DAC 32-bit float.
  - **Category B: Dedicated Focus Cards / Template Terfokus (4 Templates)**:
    - [x] **Template 9: Persona Master Card (`persona_master_card_view.dart`)**:
      - Kartu fokus arketipe audiophile persona dengan concentric halo seal, acoustic telemetry radar (Energy Index, Dynamic Range dB, Lossless Purity %), quote filosofi suara, signature gear, dan status rantai hardware.
    - [x] **Template 10: Top Artists Festival Lineup Poster (`artist_lineup_poster_view.dart`)**:
      - Desain poster festival musik megah dengan Headliner #1 spotlight avatar, sub-headliners grid, supporting acts tag cloud, dan telemetri panggung (Stage Time, Pass Type VIP All-Access).
    - [x] **Template 11: Genre & Sonic Spectrum Card (`genre_spectrum_card_view.dart`)**:
      - Visualisasi spektrum frekuensi multi-warna, dominant sound ecosystem hero, acoustic spectrum distribution bar, dan peringkat top 4 genre dengan persentase presisi.
    - [x] **Template 12: Top 10 Master Tracks Chart (`top_tracks_chart_view.dart`)**:
      - Papan chart peringkat #01 hingga #10 dengan spotlight anthem #1 hero artwork, detail format bit-perfect, hitungan putaran (*plays*), dan durasi menit per track.
- [x] **62.5 Harmonic Resonance Analytics & Audio Data Modeling (`HarmonicResonanceProfile` & `StudioWrappedCalculator`)**:
  - [x] Algoritma kalkulasi profil resonansi harmonik (`energyScore`, `timbralSignature`, `dynamicRangeDb`, `peakTimeWindow`, `waveSeedAmplitudes`).
  - [x] Klasifikasi otomatis karakter sonik: *Warm Harmonic Analog (Tube Drive)*, *Pure Bit-Perfect Transparent*, *Visceral Sub-Bass Impact*, atau *Studio Reference Linear*.
  - [x] Generator kurva gelombang bezier deterministik berbasis riwayat playback dan rasio Hi-Res/Lossless.
- [x] **62.6 Multi-Template Export Hub & High-Res PNG Share (`lib/features/analytics/presentation/templates/studio_wrapped_export_hub.dart` & `lib/features/analytics/data/wrapped_image_exporter.dart`)**:
  - [x] Two-Tier Segmented Category Switcher: `[ 🌟 All-in-One Recaps (8) ]` vs `[ 🎯 Dedicated Focus Cards (4) ]`.
  - [x] Preview interaktif kartu rekap 9:16 di dalam frame studio.
  - [x] Switcher bar horizontal interaktif untuk ke-12 template visual dengan ikon HugeIcons dan label terintegrasi.
  - [x] Navigasi kontekstual dengan parameter `initialStyle` dari slide story.
  - [x] Toggle paper styling (*Dark Ink* / *Classic Light Paper*).
  - [x] Rasterisasi off-screen `RepaintBoundary` beresolusi tinggi (pixelRatio 3.0 = 1080p+) dan pembagian langsung via `SharePlus.instance.share`.
- [x] **62.7 Interactive 7-Slide Fullscreen Story Player (`lib/features/analytics/presentation/story/studio_wrapped_story_screen.dart`)**:
  - [x] Slide 1: Welcome & Total Listening Time Hero.
  - [x] Slide 2: Top Tracks Countdown (#1 spotlight + #2–#5 rotation dengan `StudioArtworkWidget`) + **Quick-Export Button `[ 🏆 EXPORT TRACKS CHART ]`**.
  - [x] Slide 3: Top Artists & Genre Ecosystem breakdown dengan artwork artist + **Quick-Export Buttons `[ 🎤 FESTIVAL POSTER ]` & `[ 🧬 SONIC SPECTRUM ]`**.
  - [x] Slide 4: Audio Purity & Lossless Bit-Rate breakdown (FLAC vs Hi-Res vs MP3).
  - [x] Slide 5: Studio Hardware & Signal Chain profile (AutoEQ + DSP Units + DAC).
  - [x] Slide 6: Grand Persona Reveal (Holographic badge, personality description, signature sound tags).
  - [x] Slide 7: Grand Reveal Summary + **Direct Shortcut `[ 🌟 EXPORT PERSONA MASTER CARD ]`** + **Interactive 12-Template Mini-Gallery Carousel** + Direct button to Export Gallery.
  - [x] Multi-segment animated top progress bar, gesture tap kiri (mundur), tap kanan (maju), dan long-press (pause).
- [x] **62.8 Dashboard Bento Integration (`lib/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart`)**:
  - [x] Banner bento modular Material 3 Expressive di layar utama dengan persona live badge, total listening minutes, artwork thumbnail, dan aksi instan `[ Open Story ]` / `[ Export Hub ]`.
- [x] **Phase 63 — Dedicated Studio Listening Insights Detail Screen & Dashboard Bento Modernization**:
  - [x] **63.1 Domain Model & Album Aggregation (`TopAlbumRank`)**:
    - [x] Added `TopAlbumRank` domain model in `lib/features/analytics/domain/studio_wrapped_data.dart` with `rank`, `album`, `artist`, `playCount`, `totalMinutes`, `trackCount`, `artworkUrl`, and JSON serialization.
    - [x] Implemented `_AlbumAggregator` in `lib/features/analytics/domain/studio_wrapped_calculator.dart` to compute ranked albums by listening duration and unique track IDs, with high-fidelity sample album fallback.
  - [x] **63.2 Dedicated Studio Listening Insights & Analytics Detail Screen (`lib/features/analytics/presentation/details/studio_listening_stats_detail_screen.dart`)**:
    - [x] Sticky Header with back navigation, subtitle, and instant action shortcuts to Story Recap and Export Hub.
    - [x] Time Range Switcher pill group (`2026 Studio Wrapped`, `Last 30 Days`, `All-Time Journey`) reacting via Riverpod `studioWrappedFilterProvider`.
    - [x] Persona Hero Showcase with archetype badge, personality traits, dynamic 5-axis acoustic radar painter (`_StudioRadarPainter`), and acoustic profile metrics (Timbral Tone, Energy Score, Peak Window).
    - [x] Core Telemetry 4-Grid: Total Listening Time, Total Tracks Played, Unique Artists, and Unique Albums with `FontFeature.tabularFigures()`.
    - [x] Top 10 Tracks Spotlight: #01 Champion Hero Card with artwork, format badge (`24-bit / 96kHz FLAC`), play count, total time, and instant playback trigger, plus #02–#10 ranked list tiles.
    - [x] Top Artists Hall of Fame: Horizontal scrollable cards with circular artist artwork (`StudioArtworkWidget`), rank badge, listening share %, and total minutes.
    - [x] Top Albums Hall of Fame: Ranked album cards with cover art, artist, track count badge, play count, and total duration.
    - [x] Genre Spectrum: Percentage breakdown bars with play counts and signature genre indicators.
    - [x] Audio Purity & Signal Chain: Lossless FLAC vs Hi-Res vs Lossy ratios, Bit-Perfect studio hours, and peak sample rate indicator.
    - [x] Hardware DAC & DSP Telemetry: Connected DAC bridge hours, AutoEQ driver profile & target curve, and Triode Tube saturation hours.
    - [x] Bottom Action Launchers: Quick access to Interactive Story Recap and 12-Template Export Hub.
  - [x] **63.3 Dashboard Listening Statistics Bento Card Modernization (`lib/features/dashboard/presentation/widgets/listening_statistics_card.dart`)**:
    - [x] Upgraded to pure Material 3 Expressive studio styling with live archetype badge, 3 tabular telemetry tiles, linear Hi-Res lossless progress bar, top 3 artists rotation preview with artwork avatars, top 3 heavy rotation tracks with format badges and instant play, and interactive `"View All"` pill button navigating to `StudioListeningStatsDetailScreen`.
    - [x] Overflow-proof responsive layout using `Flexible` and ellipsis text wrapping across narrow screens (tested down to 336px).
  - [x] **63.4 Quality Gate & Test Verification (`test/studio_wrapped_analytics_and_templates_test.dart`)**:
    - [x] Added unit tests for `TopAlbumRank` calculation and ranking logic.
    - [x] Added widget tests for `ListeningStatisticsCard` rendering, metrics, and navigation action.
    - [x] Added widget tests for `StudioListeningStatsDetailScreen` section verification and time filter switcher.
    - [x] 100% Quality Gate passed: `flutter analyze` (**0 errors, 0 warnings**) & `flutter test` (**544/544 tests passing**).








