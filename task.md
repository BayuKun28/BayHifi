# 📋 Baydev HiFi — Master Task Tracker (`task.md`)

Dokumen pelacakan tugas mendalam untuk pengembangan pemutar musik audiophile **Baydev HiFi**. Setiap tugas dirancang secara modular dan dapat dieksekusi secara berurutan.

---

## 📊 Status Dashboard
- **Total Fase**: 5 Fase
- **Total Tugas**: 36 Sub-tugas
- **Status Proyek**: 🟢 *Phase 1 & 2 Completed — Ready for Phase 3 (AutoEQ & Squiglink Import Engine)*

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

- [ ] **3.1 Parser Universal File Pengukuran Driver**
  - [ ] Implementasikan parser REW V5 untuk membaca `KZ CASTOR BLACK DUDU R.txt`
  - [ ] Ekstraksi titik data frekuensi ($f$) dan tingkat tekanan suara ($SPL$)
  - [ ] Sanitasi data: Abaikan komentar header (`*` atau `#`) dan tangani delimiter whitespace/tab
- [ ] **3.2 Parser Universal File Target Respon**
  - [ ] Implementasikan parser Squiglink CSV untuk membaca `HBB Target.txt`
  - [ ] Ekstraksi titik pasangan `Freq,SPL` dari file target
- [ ] **3.3 Normalisasi 1 kHz & Kalkulator Selisih $\Delta SPL$**
  - [ ] Sejajarkan kedua kurva pada frekuensi referensi $1,000\text{ Hz}$ ($SPL_{norm} = SPL - SPL_{1kHz}$)
  - [ ] Hitung kurva deviasi: $\Delta SPL(f) = SPL_{\text{Target}}(f) - SPL_{\text{Driver}}(f)$
- [ ] **3.4 AutoEQ Biquad Optimizer Solver**
  - [ ] Algoritma deteksi titik resonansi puncak dan lembah pada $\Delta SPL(f)$
  - [ ] Generator konfigurasi filter sesuai pilihan resolusi band: `5 B`, `10 B`, `16 B`, `20 B`, `32 B`
  - [ ] Terapkan hasil optimasi langsung ke node Pro-Q Canvas dan filter engine
- [ ] **3.5 Modal Dialog "Auto EQ Studio & Target Matching" (Sesuai Screenshot 2)**
  - [ ] Dropdown seleksi Driver (misal: "KZ CASTOR BLACK DUDU R") + tombol Hapus
  - [ ] Dropdown seleksi Target (misal: "HBB%20Target") + tombol Hapus
  - [ ] Tombol aksi samping: `[🎧 IMPORT DRIVER]`, `[🎯 IMPORT TARGET]`, `[✨ SQUIGLINK EQ]`
  - [ ] Pilihan tombol Band Resolution (`5 B`, `10 B`, `16 B`, `20 B`, `32 B`)
  - [ ] Pilihan Tuning Mode (`⚡ Normal` vs `🛡️ Safe`)
  - [ ] Tombol eksekusi utama: `[📊 APPLY TO DSP]` (warna emerald menyala)
- [ ] **3.6 Parser & Exporter Teks Squiglink EQ**
  - [ ] Parsing format teks Squiglink (`Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414`)
  - [ ] Ekspor konfigurasi EQ saat ini ke format teks Squiglink / Wavelet
- [ ] **3.7 Fitur A/B Comparison Switch**
  - [ ] Tombol instan beralih antara `[A: RAW]` (audio murni) dan `[B: ACTIVE]` (audio ber-tuning)
  - [ ] Transisi crossfade halus (10ms) untuk mencegah bunyi *pop/click* saat switching

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

## ☁️ Fase 5: Local Offline Library, Navidrome & Expressive Settings
Integrasi sumber audio lengkap, sinkronisasi cloud, dan kustomisasi estetika Material 3 Expressive.

- [ ] **5.1 Local File Scanner & Hi-Res Badging Engine**
  - [ ] Scanner folder lokal asynchronous berbasis background `Isolate`
  - [ ] Pembaca tag metadata (Title, Artist, Album, Year, Genre, Track Number)
  - [ ] Ekstraktor embedded Cover Art resolusi tinggi
  - [ ] Auto-detection Hi-Res badge:
    - Gold Badge: `FLAC 24-bit / 192 kHz`
    - Silver Badge: `FLAC 24-bit / 96 kHz`
    - Blue Badge: `FLAC 16-bit / 44.1 kHz (CD Quality)`
    - Amber Badge: `DSD64 / DSD128`
    - Grey Badge: `MP3 320 kbps / AAC`
- [ ] **5.2 Unified SQLite / Drift Database**
  - [ ] Skema database untuk tracks, albums, artists, playlists, autoeq profiles, dan cache status
  - [ ] Indeks pencarian cepat (search by title, artist, album, format)
- [ ] **5.3 Navidrome Subsonic Client Integration**
  - [ ] Autentikasi aman Subsonic API (Salt + MD5 Token)
  - [ ] Endpoint integrasi: `ping`, `getArtists`, `getArtist`, `getAlbum`, `getPlaylists`, `stream`, `scrobble`
  - [ ] Streaming lossless direct FLAC tanpa transcode server
  - [ ] Sinkronisasi "Now Playing" dan scrobble status ke server Navidrome
- [ ] **5.4 Smart Offline Download & Caching Manager**
  - [ ] Tombol unduh per lagu, album, atau playlist
  - [ ] Manajer antrian download di background dengan progress bar
  - [ ] Integrasi otomatis file hasil unduhan ke dalam Local Library offline
- [ ] **5.5 Material 3 Expressive Theming & Dynamic Palette**
  - [ ] Ekstraksi warna otomatis dari Album Art lagu yang aktif menggunakan `palette_generator`
  - [ ] Animasi transisi perubahan warna tema secara fluida (500ms easing)
  - [ ] Pilihan Studio Curated Themes: *Dark Studio Obsidian*, *Amber Tube Glow*, *Cyber Neon Blue*, *Retro HiFi Champagne*, *True OLED Black*
- [ ] **5.6 Halaman Pengaturan Lengkap (Settings & Personalization)**
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
