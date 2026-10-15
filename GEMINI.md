# Baydev HiFi — Agent Instructions & Rules

Project rules and guidelines are defined in [rules.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/rules.md).
Architecture and technical blueprint are defined in [baydev_hifi_blueprint.md](file:///home/x/.gemini/antigravity/brain/de5a70a9-7984-4d09-abda-d9ef144ce06a/baydev_hifi_blueprint.md).
Todo tasks, PRD, and implementation progress are tracked in [task.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/task.md).

Always adhere strictly to the design principles, performance rules, Dart 3 code standards, and folder structure specified in `rules.md`.

Audio engine & streaming dependency mandates:
- `flutter_soloud` MUST be sourced from the local sibling directory `/mnt/01DC9A2666E1A190/Other/PROJECTS/flutter_soloud` (`path: ../flutter_soloud`), NEVER from pub.dev.
- `youtube_explode_dart` MUST be sourced from the local in-tree directory `packages/youtube_explode_dart` (`path: packages/youtube_explode_dart`), NEVER from pub.dev.
- The agent has full access to read and customize C++ filters in `flutter_soloud` and streaming extraction/cipher algorithms in `packages/youtube_explode_dart`.

UI/UX & Theming Standards — Simple-As-F Minimalist Design Mandate (Dribbble 27089924 Reference):
- Design Vision & Philosophy: "Simple as F***" — Extreme minimalism, uncluttered surfaces, high breathability, two-tone colored typography, and bespoke audiophile elegance.
- M3E Usage Policy: `material_3_expressive` is NO LONGER mandatory across all components. Widgets are built with bespoke Flutter architecture tailored precisely to the Dribbble 27089924 reference. M3E components (`M3ESwitch`, `M3ESlider`, `M3EButton`, `motor` spring physics) may only be used selectively where they naturally fit without adding generic M3 boilerplate or visual bloat.
- Color Palette & Atmosphere:
  - Background: Obsidian Forest Deep Dark (`#0B110E` / `#0E1713`) with subtle, soft ambient radial glows (`#12231A`).
  - Accent: Organic Emerald Mint (`#2EE672` / `#4ADE80`).
  - Subtitle & Metadata: Sage Slate Gray (`#8A9A90` / `#A1B2A7`).
  - Typography: Pure White (`#FFFFFF`) with two-tone colored keywords (e.g., "Liked *Songs*", "Recently *Played*", "Equalizer *Studio*").
  - Small Meta Headers: Small uppercase tracking (`WELCOME, MATT`, `RECENTLY PLAYED`, `DOWNLOAD`).
- Core Layout & Screen Paradigms:
  - Track List: Uncarded, floating row layout for music tracks. Active track is highlighted in a soft dark capsule container with an animated audio wave / speaker icon.
  - Now Playing: Prominent squircle album artwork (border radius 28–32px), centered bold track info, favorite heart button on left, interactive **waveform seekbar** (amplitude bars with played/unplayed contrast and tabular time figures), and minimalist playback controls row (shuffle, prev, play/pause pill/circle, next, repeat).
  - Home / Discovery: Clean header with user avatar & greeting, two-tone section titles, and a 2-column squircle card grid for albums/playlists with clean metadata below.
  - Floating MiniPlayer: Sleek floating pill/capsule dock pinned above the bottom navigation bar.
- Modern Iconography: ALL icons MUST use `hugeicons` (`HugeIcons.strokeRounded...` / `HugeIcons.solidRounded...`) for crisp, consistent, unified aesthetics. NEVER mix generic legacy Material 1/2 icons.
- Zero-Emoji Policy (Strictly Enforced): NEVER use emojis in UI widgets, button labels, dialog titles, snackbars, status texts, code, or documentation. Always use the available icon library (`hugeicons`).
- Anti-AI-Slop Policy: Follow `anti-ai-slop-ui` standards (high information clarity, tabular figures for audio data via `FontFeature.tabularFigures()`, restrained palettes, zero unreadable frosted glass or decorative bloat).
- Language: 100% English across all UI labels, tooltips, dialogs, snackbars, and messages.

Cross-Platform Architecture & Strict Platform Guards Mandate:
- Zero Regression Policy for Mobile/Android: Desktop features (Linux MPRIS D-Bus, Window Manager, System Tray, Desktop Drag-and-Drop) MUST strictly be protected with platform guards (`if (Platform.isLinux)`, `if (Platform.isAndroid)`, etc.) and responsive layout breakpoints (`>= 960px`).
- Desktop logic and plugins must NEVER break, overwrite, or cause regressions/crashes on the existing Android mobile/tablet experience (`NamidaExpandableMiniPlayer`, `FloatingRoundedDock`, mobile touch gestures, Scoped Storage).
- Mobile layout (< 960px or Android) and tablet dual-pane layout must remain 100% intact.

Testing Mandate (Strictly Non-Negotiable):
- EVERY feature, bugfix, refactoring, controller, and UI layout update MUST include unit / widget test files (`test/..._test.dart`) to guarantee zero regression and deterministic state execution.
- Always run `flutter test` and `flutter analyze` after completing tasks to maintain 100% passing tests with 0 errors and 0 warnings.





