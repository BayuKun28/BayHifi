# Baydev HiFi — Studio Audiophile Music Player

**Baydev HiFi** is a state-of-the-art audiophile music player built with Flutter, powered by the high-performance **`flutter_soloud` C++ audio engine** and styled with a bespoke **Simple-As-F Minimalist Architecture** (Dribbble 27089924 reference) featuring pure solid audiophile dark surfaces and Lucide iconography.

---

## Key Highlights & Features

- **Bit-Perfect C++ Audio Engine**: Low-latency SoLoud FFI integration with automated safe headroom pre-amp and brickwall peak limiting (`-1.3 dBFS`).
- **32-Band Pro-Q Parametric Studio**: Interactive logarithmic canvas ($20\text{ Hz} \leftrightarrow 20\text{ kHz}$) with draggable biquad filter nodes, real-time RTA FFT spectrum analyzer, and 7 studio frequency zones.
- **AutoEQ & Squiglink Target Matcher**: Instant frequency response solver supporting REW V5 and Squiglink CSV targets with non-blocking isolate solver.
- **10-Module Mastering DSP Rack**: Triode Tube Exciter, Dynamic Compressor, Mid-Side Stereo Widener, Meier Binaural Crossfeed, Freeverb Spatial Reverb, and Granular Pitch Shifter.
- **100% Pure Material 3 Expressive UI**: Built using `material_3_expressive` (`^1.1.3`), `material_ui`, `motor` spring physics, `material_new_shapes`, and `M3EHaptics`.
- **Dynamic Theming & OLED Black**: Real-time palette extraction from album art with `StudioColorHarmonizer` contrast protection (WCAG AA compliant) and 19 curated studio palettes.
- **Studio Lyric Card Customization Engine**: Social sharing for synchronized lyrics (Instagram Stories 9:16, Square 1:1, Portrait 4:5, Landscape 16:9) with dual-pass text stroke, Instagram highlighter pill, Spotify glow, and cover atmosphere blur controls.
- **Omnipresent Expandable MiniPlayer**: Smooth gestural bottom sheet transitions and floating capsule dock navigation.
- **Unified Library & YouTube Streaming**: Local directory crawler, ID3/Vorbis/MP4 tagger, and YouTube Music streaming integration with Ogg Opus remuxing.

---

## UI Framework & Design: Simple-As-F Minimalist Architecture

Baydev HiFi adopts the **Simple-As-F Minimalist Architecture** (Dribbble 27089924 reference):
- **Design Philosophy**: Extreme minimalism, uncluttered surfaces, high breathability, two-tone colored typography, and pure solid audiophile dark surfaces.
- **Color Atmosphere**: Neutral Matte Obsidian Carbon (`#0D0E12` / `#08090B`), Solid Studio Charcoal (`#16181F`), Active Playing Capsule (`#1E212B`), and Clean Studio Emerald Mint (`#10B981` / `#34D399`).
- **Core Screens**:
  - **Now Playing**: Squircle artwork (`borderRadius: 28–32px`), interactive waveform seekbar with tabular audio figures, minimalist playback controls, and a compact auxiliary action bar (34x34px solid icon buttons).
  - **Dashboard**: Studio Wrapped recap banner, Discovery Smart Mix suggestion banner, quick YouTube HiFi launcher, persistent Recently Played 2x2 mobile grid, and clean floating liked tracks.
  - **Library**: High-visibility YouTube HiFi streaming tab (position 2), quick streaming AppBar launcher, and uncarded floating track list with proportional active capsule padding.
- **Iconography**: Unified vector stroke iconography via `lucide_icons_flutter` (`LucideIcons.*`) with strict zero-emoji and pure-solid (anti-neon) policies.
- **M3 Expressive Integration**: Selectively integrated for smooth physics (`motor` spring curves) and specialized controls (`M3ESwitch`, `M3ESlider`).

---

## Getting Started

### Prerequisites
- Flutter SDK `^3.13.4`
- Local sibling directory for `flutter_soloud`: `../flutter_soloud`

### Run App
```bash
flutter pub get
flutter run -d linux # or windows / macos / android
```

### Run Automated Test Suite
```bash
flutter test
flutter analyze
```

