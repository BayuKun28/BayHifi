---
name: anti-ai-slop-ui
description: Teaches how to design and build high-fidelity, non-slop, production-grade audiophile and studio UI interfaces in Flutter using 100% pure material_3_expressive widgets, avoiding generic AI-generated clutter, unreadable frosted glass, garish neon overuse, and bloated card layouts.
---

# Anti-AI Slop UI & High-Fidelity Studio Design Guide

## 1. What is "AI Slop" in UI/UX?

AI-generated interfaces often suffer from recognizable "tells" that look flashy in a static low-res mockup but feel cheap, unreadable, and frustrating in real software:
- **Neon Overload**: Slapping high-saturation cyan/magenta/amber gradients across every single button, card, and background without functional meaning.
- **Unreadable Frosted Glass**: Excessive `BackdropFilter` blur with low-contrast semi-transparent text that disappears over colorful album art or dark backgrounds.
- **Bloated Low-Density Cards**: Massive 30px padding around 2 lines of centered text with 40px empty margins, wasting screen real estate.
- **Meaningless Decorative Fluff**: Floating 3D spheres, wavy mesh gradient blobs, or non-reactive canvas particles that distract from playback and audio controls.
- **Disconnected Iconography**: Mixing 4 different icon styles (filled, sharp, outlined, two-tone) from generic icon packs with inconsistent stroke widths.
- **Generic Centered Everything**: Lack of clear visual hierarchy, strong typographic grid, or tabular data alignment.

---

## 2. The High-Fidelity Studio Audiophile Philosophy (Pure `material_3_expressive`)

Real professional audio equipment (Universal Audio, FabFilter Pro-Q, SSL, RME TotalMix) and premier music players (Namida, Neutron, UAPP, Tidal) follow strict ergonomics with **`material_3_expressive`**:

### 2.1 Information Hierarchy & Density
- **High Information Density with Generous Breathing Room**: Compact, high-utility headers and sub-headers (e.g. `18 ALBUMS • 124 TRACKS`, `FLAC 24-bit / 96 kHz • 48 kHz Engine`).
- **Tabular Figures for Dynamic Data**: Always use `FontFeature.tabularFigures()` for timestamps (`03:42`), frequencies (`1,000 Hz`), gain levels (`-1.2 dB`), and Q values so numbers do not jump or jitter during playback.
- **`M3EBadge` Precision**: Use subtle, high-contrast `M3EBadge` with crisp 1px borders (`border: Border.all(color: divider, width: 0.8)`) and solid surface container backgrounds.

### 2.2 Restrained, Purpose-Driven Color Palette
- **Deep Obsidian / OLED Grounds**: Deep neutral backgrounds (`#0D0F14`, `#12151C`, `#000000`) that make album art and DSP curves pop without eye fatigue.
- **Functional Studio Accents**:
  - Accent colors indicate **state** (Active EQ band, Hi-Res stream, Connected DAC, Active Tab).
  - Normal text and controls stay in clean, crisp neutrals (White, 80% White, 60% Muted Gray).
  - Amber Warmth (`#F59E0B`) for analog tube/warm DSP.
  - Mint Emerald (`#10B981`) for Bit-Perfect / Target match.
  - Studio Sky Blue (`#38BDF8`) for studio measurement curves and primary selection.

### 2.3 Unified, Modern Iconography (`hugeicons`)
- **Stroke Uniformity**: Use `HugeIcons.strokeRounded...` consistently across all screens for a sleek, contemporary, studio look.
- **No Icon Clashing**: Do not mix legacy Material 1 icons (`Icons.dashboard`) with modern stroke icons.
- **Interactive Touch Targets**: `M3EIconButton` and `M3EButton` must have clear 40x40 minimum touch targets with subtle haptic feedback (`M3EHaptics.selectionClick()`).

### 2.4 Ergonomic Floating Rounded Dock & MiniPlayer
- **Floating Rounded Dock (`M3ENavigationBar` / `M3EToolbar`)**: Elevated capsule navigation (`BorderRadius.circular(26)`) with subtle glassmorphic backdrop, crisp border, and spring pill indicator.
- **Dock Integration**: Positioned cleanly above bottom system safe areas, seamlessly sitting below the collapsed `NamidaExpandableMiniPlayer`.

---

## 3. Checklist for Non-Slop Component Design

1. [ ] **Is the component built with `material_3_expressive` (`M3ECard`, `M3EButton`, `M3ESlider`, `M3EBottomSheet`)?**
2. [ ] **Is the contrast ratio WCAG AA compliant?** (No gray-on-dark-gray text).
3. [ ] **Does dynamic text/number use `FontFeature.tabularFigures()`?**
4. [ ] **Are borders subtle and 1px or 0.8px instead of fuzzy 12px blur shadows?**
5. [ ] **Are all icons sourced from `hugeicons` with consistent stroke weight?**
6. [ ] **Is every action reachable within standard thumb zones on mobile?**
7. [ ] **Are list items responsive with clean truncation (`maxLines: 1`, `TextOverflow.ellipsis`)?**
8. [ ] **Does the layout respect screen edges with standardized 16px/20px horizontal padding?**

