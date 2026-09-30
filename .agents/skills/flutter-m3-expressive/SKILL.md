---
name: flutter-m3-expressive
description: >-
  Use this skill when designing or implementing Flutter Material 3 Expressive UI components
  using the official material_3_expressive package (^1.1.3), motor spring physics, material_new_shapes,
  custom DSP canvas graphics (Pro-Q curves, RTA spectrum), and dynamic palette extraction in Baydev HiFi.
---

# Flutter Material 3 Expressive Skill — Baydev HiFi

Panduan dan prosedur teknis untuk membangun antarmuka pengguna kelas studio audiophile dengan **100% Pure Material 3 Expressive** (`material_3_expressive: ^1.1.3`).

---

## 1. Arsitektur Inti & Setup Framework `material_3_expressive`

Paket `material_3_expressive` dibangun di atas fondasi:
- **`material_ui`** (`^1.4.0`): Komponen Material murni berstandar M3 Expressive.
- **`motor`** (`^0.2.0` / `^1.1.0`): Physics engine simulasi pegas (*spring physics*).
- **`material_new_shapes`** (`^1.0.0`): Morfologi bentuk squircle, pill, dan poligon geometris.

### Inisialisasi Root Aplikasi:
```dart
import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

class BaydevHiFiApp extends StatelessWidget {
  const BaydevHiFiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return M3EMaterialApp(
      title: 'Baydev HiFi',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: M3EThemeData(
        colorScheme: AppThemeBuilder.buildLightColorScheme(),
        autoTheming: true,
        dynamicColoring: true,
        drawUnderSystemBars: true,
      ),
      darkTheme: M3EThemeData(
        colorScheme: AppThemeBuilder.buildDarkColorScheme(),
        autoTheming: true,
        dynamicColoring: true,
        drawUnderSystemBars: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}
```

---

## 2. Katalog Komponen Wajib & Pola Implementasi (`M3E*`)

### 2.1 Tombol & Aksi (Actions)
- **`M3EButton`**: Tombol utama dengan varian Filled, Tonal, Outlined, Elevated, Text, dan Icon:
  ```dart
  M3EButton.filled(
    label: const Text('PLAY ALL'),
    icon: const Icon(HugeIcons.strokeRoundedPlay),
    onPressed: () => handlePlayAll(),
  )
  ```
- **`M3EIconButton`**: Tombol ikon interaktif dengan touch target minimum 40x40 dan M3 state ripple:
  ```dart
  M3EIconButton.tonal(
    icon: const Icon(HugeIcons.strokeRoundedShuffle),
    onPressed: () => handleShuffle(),
  )
  ```
- **`M3EFab` & `M3EFabMenu`**: Floating action button dan speed-dial menu terapung:
  ```dart
  M3EFabMenu(
    icon: const Icon(HugeIcons.strokeRoundedPlusSign),
    children: [
      M3EFabMenuItem(
        label: const Text('Add Track'),
        icon: const Icon(HugeIcons.strokeRoundedMusicNote01),
        onPressed: () => handleAddTrack(),
      ),
    ],
  )
  ```
- **`M3ESegmentedButton`**: Switch mode multi-opsi berbasis pill:
  ```dart
  M3ESegmentedButton<ViewLayoutMode>(
    segments: const [
      M3ESegment(value: ViewLayoutMode.grid, icon: Icon(HugeIcons.strokeRoundedGrid01), label: Text('Grid')),
      M3ESegment(value: ViewLayoutMode.list, icon: Icon(HugeIcons.strokeRoundedMenu01), label: Text('List')),
    ],
    selected: {currentLayoutMode},
    onSelectionChanged: (set) => onModeChanged(set.first),
  )
  ```

### 2.2 Kontainer & Permukaan (Containment & Surfaces)
- **`M3ECard`**: Bento Grid surface containers dengan 1px crisp outline border:
  ```dart
  M3ECard.filled(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: childContent,
    ),
  )
  ```
- **`M3ECarousel`**: Horizontal uncontained and hero showcases:
  ```dart
  M3ECarousel.multiBrowse(
    itemExtent: 260,
    children: showcaseItems,
  )
  ```
- **`M3EListTile`**: Item list lagu, album, dan pengaturan:
  ```dart
  M3EListTile(
    leading: M3EShapeContainer.squircle(child: AlbumArtThumbnail(track: track)),
    title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: M3EBadge(label: Text(track.isHiRes ? 'Hi-Res' : 'FLAC')),
    onTap: () => onTrackTap(track),
  )
  ```
- **`M3EBottomSheet` & `M3EDialog`**: Lembar modal dan dialog konfirmasi ekspresif:
  ```dart
  M3EBottomSheet.showModal(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const LyricShareSheet(),
  );
  ```

### 2.3 Kontrol Input & Slider (Inputs & Sliders)
- **`M3ESlider`**: Slider kontinu, diskrit, dan **Wavy Slider** ekspresif untuk seekbar audio & parameter DSP:
  ```dart
  M3ESlider.continuous(
    value: currentGain,
    min: -24.0,
    max: 24.0,
    onChanged: (val) => onGainChanged(val),
  )
  ```
- **`M3ESwitch`**: Toggle switch ekspresif untuk DSP bypass & feature toggles:
  ```dart
  M3ESwitch(
    value: isDspEnabled,
    onChanged: (val) => onToggleDsp(val),
  )
  ```

### 2.4 Navigasi (Navigation)
- **`M3ENavigationBar`**: Capsule floating dock navigasi dengan indikator pill beranimasi pegas:
  ```dart
  M3ENavigationBar(
    selectedIndex: currentTabIndex,
    onDestinationSelected: (idx) => onTabSelected(idx),
    destinations: const [
      M3ENavigationDestination(icon: Icon(HugeIcons.strokeRoundedHome01), label: 'Dashboard'),
      M3ENavigationDestination(icon: Icon(HugeIcons.strokeRoundedEqualizer), label: 'DSP Rack'),
      M3ENavigationDestination(icon: Icon(HugeIcons.strokeRoundedMusicNote03), label: 'Library'),
      M3ENavigationDestination(icon: Icon(HugeIcons.strokeRoundedSettings02), label: 'Settings'),
    ],
  )
  ```
- **`M3ESearchBar`**: Search input ekspresif dengan expand view:
  ```dart
  M3ESearchBar(
    hintText: 'Search tracks, albums, artists...',
    leading: const Icon(HugeIcons.strokeRoundedSearch01),
    onChanged: (query) => onSearchChanged(query),
  )
  ```

---

## 3. Fisika Pegas (Motor Spring Physics) & Haptik

- Seluruh transisi lembar modal, gesture dragging, expand-collapse miniplayer, dan interaksi visual WAJIB digerakkan oleh **`motor`** spring physics:
  ```dart
  final springSpec = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 20.0,
  );
  ```
- Gunakan **`M3EHaptics`** untuk respons mikro-taktil:
  - `M3EHaptics.selectionClick()` saat memilih opsi / tab.
  - `M3EHaptics.lightImpact()` saat toggle switch atau dragging slider snap.
  - `M3EHaptics.mediumImpact()` saat konfirmasi aksi penting.

---

## 4. Pemetaan Koordinat Logaritmik Canvas DSP (20 Hz - 20,000 Hz)

Dalam rendering kurva audio pada CustomPainter:
- Frekuensi minimum $F_{\min} = 20\text{ Hz}$
- Frekuensi maksimum $F_{\max} = 20,000\text{ Hz}$

### Konversi Frekuensi ke Koordinat X Piksel:
$$x(f) = \frac{\log_{10}(f) - \log_{10}(F_{\min})}{\log_{10}(F_{\max}) - \log_{10}(F_{\min})} \times \text{CanvasWidth}$$

### Konversi Koordinat X Piksel ke Frekuensi:
$$\text{normX} = \frac{x}{\text{CanvasWidth}}$$
$$f(x) = F_{\min} \times \left(\frac{F_{\max}}{F_{\min}}\right)^{\text{normX}} = 20 \times (1000)^{\text{normX}}$$

### Konversi Gain (dB) ke Koordinat Y Piksel:
Rentang default: $+24\text{ dB}$ s/d $-24\text{ dB}$:
$$y(\text{gain}) = \frac{\text{Gain}_{\max} - \text{gain}}{\text{Gain}_{\max} - \text{Gain}_{\min}} \times \text{CanvasHeight}$$

---

## 5. 7 Zona Frekuensi Standar Studio

Gambarkan garis vertikal dan pill header penanda zona:
1. **SUB BASS**: 20 Hz – 60 Hz (Merah/Magenta lembut `#FF453A`)
2. **MID BASS**: 60 Hz – 250 Hz (Oranye lembut `#FF9F0A`)
3. **LOWER MIDRANGE**: 250 Hz – 500 Hz (Hijau Sage `#30D158`)
4. **UPPER MIDRANGE**: 500 Hz – 2,000 Hz (Teal `#64D2FF`)
5. **PRESENCE REGION**: 2,000 Hz – 4,000 Hz (Biru Indigo `#0A84FF`)
6. **MID TREBLE**: 4,000 Hz – 10,000 Hz (Ungu `#BF5AF2`)
7. **AIR**: 10,000 Hz – 20,000 Hz (Pink/Cyan `#FF375F`)

---

## 6. Ekstraksi Warna Dinamis & Harmonizer Studio

1. Saat lagu berubah, ekstrak palet menggunakan `palette_generator` lalu lewatkan ke `StudioColorHarmonizer`:
   - Cegah masalah teks/ikon hitam pada album cover gelap/hitam dengan mengangkat luminansi minimum ke Studio Slate (`#94A3B8`).
   - Kalkulasi `onPrimary` dan `onSecondary` dinamis untuk menjamin kontras WCAG AA.
2. Terapkan warna hasil harmonisasi ke dalam `M3EThemeData` secara mulus.

---

## 7. Performa Rendering 60/120 FPS
1. Bungkus selalu CustomPainter dalam widget `RepaintBoundary`.
2. Jangan pernah melakukan `new Paint()` atau alokasi list titik di dalam `paint(Canvas canvas, Size size)`.
3. Gunakan `shouldRepaint(covariant CustomPainter oldDelegate)` yang memeriksa equality state dengan presisi untuk menghindari repaint yang tidak perlu.
4. Gunakan `FontFeature.tabularFigures()` pada seluruh teks angka numerik dinamis (frekuensi, gain, time elapsed, sample rate) agar visual layout tidak jittering.

