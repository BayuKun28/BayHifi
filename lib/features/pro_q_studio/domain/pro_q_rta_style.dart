/// Supported real-time analyzer (RTA) spectrum visualizer styles for Pro-Q Studio EQ.
enum ProQRtaStyle {
  bars(
    'Multi-Band Studio Bars',
    'Classic 48-band log-spaced FFT columns with ballistic peak hold caps',
  ),
  filledCurve(
    'Smooth Spectral Fill',
    'FabFilter Pro-Q signature smooth cubic spline with translucent gradient fill',
  ),
  wireframe(
    'Precision Line Contour',
    'Crisp 1.5px glowing spectral curve without fill for zero visual obstruction',
  ),
  m3Pillars(
    'M3 Expressive Pillars',
    'Material 3 Expressive squircle capsule columns with floating peak pills',
  ),
  peakDots(
    'Matrix Peak Dots',
    'Minimalist glowing constellation dots at peak frequencies with clean floor',
  ),
  laserBeam(
    'Studio Laser Trace',
    'High-intensity vibrant neon laser beam with soft ambient optical bloom',
  );

  final String label;
  final String description;
  const ProQRtaStyle(this.label, this.description);

  static const ProQRtaStyle defaultStyle = ProQRtaStyle.wireframe;

  static ProQRtaStyle fromString(String? val, {ProQRtaStyle fallback = ProQRtaStyle.wireframe}) {
    for (final s in ProQRtaStyle.values) {
      if (s.name == val) return s;
    }
    return fallback;
  }
}
