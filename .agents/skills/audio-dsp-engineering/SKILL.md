---
name: audio-dsp-engineering
description: >-
  Use this skill when developing, testing, or optimizing audio digital signal processing (DSP)
  algorithms for Baydev HiFi, including biquad IIR filter formulas (peaking, shelving, notch),
  FFT spectrum analyzer RTA data mapping, REW/Squiglink FR curve parsing, and AutoEQ target matching.
---

# Audio DSP Engineering Skill — Baydev HiFi

Panduan dan prosedur teknis untuk implementasi algoritma audio DSP kelas studio, matematika filter biquad, dan pemrosesan respon frekuensi (FR).

## 1. Matematika Filter Biquad (Audio EQ Cookbook Standar Robert Bristow-Johnson)

Semua filter biquad menghitung transfer function:
$$H(z) = \frac{b_0 + b_1 z^{-1} + b_2 z^{-2}}{a_0 + a_1 z^{-1} + a_2 z^{-2}}$$

### Parameter Dasar:
- $F_s$: Sample rate (contoh: 44100, 48000, 96000, 192000 Hz)
- $f_0$: Frekuensi tengah (*center frequency*) dalam Hz
- $\text{dBGain}$: Peningkatan atau pemotongan gain dalam dB
- $Q$: Nilai faktor kualitas (bandwidth filter)
- $\omega_0 = 2 \pi \frac{f_0}{F_s}$
- $\alpha = \frac{\sin(\omega_0)}{2 Q}$
- $A = 10^{\frac{\text{dBGain}}{40}} = \sqrt{10^{\frac{\text{dBGain}}{20}}}$

### Koefisien Peaking EQ (Filter Utama Pro-Q):
$$b_0 = 1 + \alpha \cdot A$$
$$b_1 = -2 \cos(\omega_0)$$
$$b_2 = 1 - \alpha \cdot A$$
$$a_0 = 1 + \frac{\alpha}{A}$$
$$a_1 = -2 \cos(\omega_0)$$
$$a_2 = 1 - \frac{\alpha}{A}$$

*Normalisasi koefisien*: Bagi seluruh $b_0, b_1, b_2, a_1, a_2$ dengan $a_0$.

---

## 2. Kalkulasi Evaluasi Respon Frekuensi $H(f)$ untuk Canvas Pro-Q

Untuk menggambar kurva gabungan seluruh band pada frekuensi $f$:
$$\phi = 2 \pi \frac{f}{F_s}$$
$$H(e^{j\phi}) = \frac{b_0 + b_1 e^{-j\phi} + b_2 e^{-j 2\phi}}{1 + a_1 e^{-j\phi} + a_2 e^{-j 2\phi}}$$
$$\text{Gain}_{\text{dB}}(f) = 20 \log_{10} |H(e^{j\phi})|$$

Untuk sistem multi-band biquad cascade:
$$\text{TotalGain}_{\text{dB}}(f) = \sum_{k=1}^{N} \text{Gain}_{\text{dB}, k}(f)$$

---

## 3. Logika Parser Universal Driver & Target

### Parsing File Driver (REW V5 - Format `KZ CASTOR BLACK DUDU R.txt`):
1. Abaikan baris berawalan `*` atau `#`.
2. Pisahkan kolom menggunakan whitespace/tab `\s+`.
3. Kolom 0 = Frekuensi ($f$), Kolom 1 = SPL (dB).

### Parsing File Target (Squiglink CSV - Format `HBB Target.txt`):
1. Pisahkan baris menggunakan delimiter koma `,`.
2. Kolom 0 = Frekuensi ($f$), Kolom 1 = SPL Target (dB).

### Normalisasi @ 1,000 Hz & Kalkulasi AutoEQ Delta:
$$SPL_{\text{norm}}(f) = SPL(f) - SPL(1000\text{ Hz})$$
$$\Delta SPL(f) = SPL_{\text{Target, norm}}(f) - SPL_{\text{Driver, norm}}(f)$$

---

## 4. Safe Headroom Pre-Amp Rule
Untuk mencegah digital clipping saat sinyal melewati DAC:
$$\text{Preamp Gain} = - \max(0, \max_f(\text{TotalGain}_{\text{dB}}(f))) - 0.5\text{ dB}$$
Nilai ini otomatis diterapkan pada input attenuator SoLoud engine.
