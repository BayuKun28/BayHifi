---
name: flutter-m3-expressive
description: >-
  Use this skill when designing or implementing Flutter Material 3 Expressive UI components,
  custom canvas graphics (Pro-Q interactive curves, RTA spectrum bars), dynamic palette extraction
  from Album Art, and spring physics micro-interactions in Baydev HiFi.
---

# Flutter Material 3 Expressive Skill — Baydev HiFi

Panduan dan prosedur teknis untuk membangun antarmuka pengguna kelas studio audiophile dengan Flutter Material 3 Expressive.

## 1. Pemetaan Koordinat Logaritmik Canvas (20 Hz - 20,000 Hz)

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

## 2. 7 Zona Frekuensi Standar Studio

Gambarkan garis vertikal dan pill header penanda zona:
1. **SUB BASS**: 20 Hz – 60 Hz (Merah/Magenta lembut `#FF453A`)
2. **MID BASS**: 60 Hz – 250 Hz (Oranye lembut `#FF9F0A`)
3. **LOWER MIDRANGE**: 250 Hz – 500 Hz (Hijau Sage `#30D158`)
4. **UPPER MIDRANGE**: 500 Hz – 2,000 Hz (Teal `#64D2FF`)
5. **PRESENCE REGION**: 2,000 Hz – 4,000 Hz (Biru Indigo `#0A84FF`)
6. **MID TREBLE**: 4,000 Hz – 10,000 Hz (Ungu `#BF5AF2`)
7. **AIR**: 10,000 Hz – 20,000 Hz (Pink/Cyan `#FF375F`)

---

## 3. Ekstraksi Warna Dinamis dari Album Art

1. Saat lagu berubah, ekstrak palet menggunakan `palette_generator`:
   - `dominantColor`: Digunakan untuk latar belakang ambient glow.
   - `lightVibrant` / `vibrant`: Digunakan untuk aksen utama slider & glow line kurva EQ.
   - `darkMuted`: Digunakan untuk surface container cards.
2. Animasikan transisi perubahan warna tema menggunakan `TweenAnimationBuilder` atau `AnimatedTheme` selama 500ms dengan kurva `Curves.easeInOutCubic`.

---

## 4. Performa Rendering 60/120 FPS
1. Bungkus selalu CustomPainter dalam widget `RepaintBoundary`.
2. Jangan pernah melakukan `new Paint()` atau alokasi list titik di dalam `paint(Canvas canvas, Size size)`.
3. Gunakan `shouldRepaint(covariant CustomPainter oldDelegate)` yang memeriksa equality state dengan presisi untuk menghindari repaint yang tidak perlu.
