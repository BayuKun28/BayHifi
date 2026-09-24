# 📋 Baydev HiFi — Master Task Tracker (`task.md`)

Dokumen pelacakan tugas mendalam untuk pengembangan pemutar musik audiophile **Baydev HiFi**. Setiap tugas dirancang secara modular dan dapat dieksekusi secara berurutan.

---

## 📊 Status Dashboard
- **Total Fase**: 5 Fase
- **Total Tugas**: 36 Sub-tugas
- **Status Proyek**: 🟢 *Phase 1, 2, & 3 Completed — Ready for Phase 4 (Mastering DSP Studio Rack)*

---

## 🚀 Fase 1: Setup Foundation & Audio Engine Core
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

## 🎨 Fase 2: Pro-Q Studio & Canvas Interaktif
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

## 🎯 Fase 3: AutoEQ & Squiglink Import Engine
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
- [x] **3.5 Modal Dialog "Auto EQ Studio & Target Matching" (Sesuai Screenshot 2)**
  - [x] Dropdown seleksi Driver (misal: "KZ CASTOR BLACK DUDU R") + tombol Hapus
  - [x] Dropdown seleksi Target (misal: "HBB%20Target") + tombol Hapus
  - [x] Tombol aksi samping: `[🎧 IMPORT DRIVER]`, `[🎯 IMPORT TARGET]`, `[✨ SQUIGLINK EQ]`
  - [x] Pilihan tombol Band Resolution (`5 B`, `10 B`, `16 B`, `20 B`, `32 B`)
  - [x] Pilihan Tuning Mode (`⚡ Normal` vs `🛡️ Safe`)
  - [x] Tombol eksekusi utama: `[📊 APPLY TO DSP]` (warna emerald menyala)
- [x] **3.6 Parser & Exporter Teks Squiglink EQ**
  - [x] Parsing format teks Squiglink (`Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414`)
  - [x] Ekspor konfigurasi EQ saat ini ke format teks Squiglink / Wavelet
- [x] **3.7 Fitur A/B Comparison Switch**
  - [x] Tombol instan beralih antara `[A: RAW]` (audio murni) dan `[B: ACTIVE]` (audio ber-tuning)
  - [x] Transisi crossfade halus (10ms) untuk mencegah bunyi *pop/click* saat switching

---

## 🎛️ Fase 4: Mastering DSP Studio Rack (10+ Modul)
Rantai pemrosesan audio kelas profesional untuk mastering dan personalisasi karakter suara.

- [ ] **4.1 Pre-Amp Gain Stage**
  - [ ] Slider headroom input (-24 dB s/d +12 dB) dengan visualizer level meter
- [ ] **4.2 Dynamic Bass Boost**
  - [ ] Peningkatan frekuensi sub-bass (40–160 Hz) dengan harmonik psychoacoustic
- [ ] **4.3 Tube Exciter / Triode Saturation**
  - [ ] Algoritma nonlinearitas analog ($y = \tanh(k \cdot x)$) untuk distorsi harmonik genap (*even harmonics*)
  - [ ] Kontrol Drive/Warmth, Harmonics Blend, dan Tube Bias
- [ ] **4.4 Dynamic Compressor**
  - [ ] Implementasi parameter: Threshold (-60 s/d 0 dB), Ratio (1:1 s/d 20:1), Attack (0.1–100ms), Release (10–1000ms), Makeup Gain
  - [ ] Visualizer gain reduction (GR Meter)
- [ ] **4.5 Stereo Width (Mid-Side Matrix)**
  - [ ] Dekomposisi sinyal ke $M = (L+R)/2$ dan $S = (L-R)/2$
  - [ ] Kontrol pelebaran soundstage (0% Mono s/d 200% Super-Wide)
- [ ] **4.6 Binaural Crossfeed (Meier / Chu-Moy Algorithm)**
  - [ ] Simulasi tata letak speaker stereo untuk headphone guna mengurangi kelelahan telinga (*listener fatigue*)
  - [ ] Kontrol Cutoff Frequency (650 Hz) dan Crossfeed Level (-3 dB s/d -9 dB)
- [ ] **4.7 Spatial Studio Reverb**
  - [ ] Algoritma Freeverb stereo: Room Size, Damping, Width, Predelay, dan Decay Time
- [ ] **4.8 Pitch Shifter Engine**
  - [ ] Pengubah nada granular tanpa mengubah tempo: Semitones (-12 s/d +12) dan Fine Cents (-50 s/d +50)
- [ ] **4.9 Peak Brickwall Limiter**
  - [ ] Zero-overshoot lookahead limiter untuk memastikan sinyal tidak pernah melampaui 0 dBFS
- [ ] **4.10 Master Wet/Dry Matrix & DSP Presets**
  - [ ] Kontrol perbandingan sinyal terproses vs sinyal asli (0% – 100%)
  - [ ] Manajemen preset DSP: Audiophile Pure, Warm Tube Acoustic, Deep Bass Impact, Spacious Cinema, Vocal Clarity

---

## ☁️ Fase 5: Unified Library (Offline + Navidrome Cloud), Studio Dashboard & Settings
Integrasi sumber audio lengkap ke dalam satu Library terpadu dengan filter, landing Dashboard saat aplikasi dibuka, dan kustomisasi estetika Material 3 Expressive.

- [ ] **5.0 Studio Hub & Audiophile Dashboard (Screen Pembuka Aplikasi)**
  - [ ] Dashboard otomatis menjadi menu pertama saat aplikasi dibuka (Default Tab Index 0)
  - [ ] Kartu Status Audio Engine: Sample rate (48kHz/96kHz/192kHz), bit-depth, buffer latency, dan DAC status
  - [ ] Quick Card Pro-Q Studio: Tombol pembuka instan ke fullscreen landscape Pro-Q
  - [ ] Now Playing Mini Preview Card dengan progress & kontrol playback
  - [ ] Ringkasan statistik pustaka: Total lagu, album, jumlah file Hi-Res FLAC, dan status koneksi server Navidrome
- [ ] **5.1 Unified Library: Offline Local & Navidrome Cloud (Disatukan dalam 1 Menu)**
  - [ ] Antarmuka satu menu Library terpadu menggabungkan audio lokal dan cloud
  - [ ] Filter Chips interaktif di bagian atas:
    - `[All Sources]`: Gabungan seluruh lagu lokal dan server
    - `[Offline Local]`: Hanya file yang tersimpan di perangkat (FLAC, WAV, MP3)
    - `[Navidrome Cloud]`: Hanya koleksi remote streaming dari server Navidrome Subsonic
    - `[Hi-Res Lossless]`: Filter lagu berkualitas 24-bit/96kHz atau 192kHz
  - [ ] Scanner folder lokal asynchronous berbasis background `Isolate`
  - [ ] Tag metadata & embedded cover art extractor
  - [ ] Auto-detection Hi-Res badges (Gold 24/192, Silver 24/96, Blue 16/44.1 CD, Amber DSD)
- [ ] **5.2 Navidrome Subsonic API Integration**
  - [ ] Autentikasi aman Subsonic API (Salt + MD5 Token)
  - [ ] Endpoint integrasi: `ping`, `getArtists`, `getArtist`, `getAlbum`, `getPlaylists`, `stream`, `scrobble`
  - [ ] Streaming lossless direct FLAC tanpa transcode server
  - [ ] Fitur smart offline download & caching manager
- [ ] **5.3 Unified Database (Local SQLite / Drift)**
  - [ ] Skema database untuk tracks, albums, artists, playlists, autoeq profiles, dan cache status
  - [ ] Indeks pencarian cepat (search by title, artist, album, format)
- [ ] **5.4 Material 3 Expressive Theming & Dynamic Palette**
  - [ ] Ekstraksi warna otomatis dari Album Art lagu yang aktif menggunakan `palette_generator`
  - [ ] Animasi transisi perubahan warna tema secara fluida (500ms easing)
  - [ ] Pilihan Studio Curated Themes: *Dark Studio Obsidian*, *Amber Tube Glow*, *Cyber Neon Blue*, *Retro HiFi Champagne*, *True OLED Black*
- [ ] **5.5 Halaman Pengaturan Lengkap (Settings & Personalization)**
  - [ ] **Theme Colors**: Palette source selector & dark/light/true black toggle
  - [ ] **Accents Color**: Color picker aksen slider/knop & pengaturan intensitas neon glow
  - [ ] **Waveform & Visualizer**: Pilihan gaya (*Spectrum Bars*, *Spline Waveform*, *Dual VU Meters*, *Circular Halo*), FFT bins (256–2048), dan decay speed
  - [ ] **Album Arts Styling**: Corner radius squircle (`0px`, `12px`, `28px`), ambient shadow glow toggle, animasi vinyl spinning
  - [ ] **Audio Hardware & DAC**: Pilihan output device (ALSA direct, USB DAC exclusive), buffer size tuning, dan bit-perfect resampling policy
- [ ] **5.7 Halaman Now Playing Lengkap**
  - [ ] Tampilan cover art besar dengan squircle border dan ambient glow
  - [ ] Lirik tersinkronisasi (LRC reader)
  - [ ] Indikator bitrate, bit depth, dan sample rate
  - [ ] Quick DSP Toggles (Bypass, Bass Boost, Tube Warmth, Crossfeed)
  - [ ] Visualizer spectrum / VU meter bar responsive
