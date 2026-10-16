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

## UI Framework: Pure `material_3_expressive`

Baydev HiFi mandates 100% adoption of `material_3_expressive`:
- **App Shell**: `M3EMaterialApp` + `M3EThemeData` with dynamic coloring and under-system-bars layout.
- **Actions**: `M3EButton`, `M3EIconButton`, `M3EFab`, `M3EFabMenu`, `M3ESegmentedButton`, `M3EButtonGroup`.
- **Containment**: `M3ECard` (Bento Grid cards), `M3ECarousel`, `M3EListTile`, `M3EBottomSheet`, `M3EDialog`.
- **Inputs**: `M3ESlider` (continuous, discrete, wavy), `M3ESwitch`, `M3ECheckbox`, `M3EChip`, `M3ETextField`.
- **Navigation**: `M3ENavigationBar`, `M3EAppBar`, `M3ESearchBar`, `M3EToolbar`, `M3ETabBar`.
- **Feedback**: `M3EBadge`, `M3EProgressIndicator`, `M3ELoadingIndicator`, `M3ESnackbar`, `M3ETooltip`.
- **Iconography**: Unified vector stroke iconography via `lucide_icons_flutter` (`LucideIcons.*`) with strict zero-emoji policy.

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

