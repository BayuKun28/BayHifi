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
  - Background: Neutral Matte Obsidian Carbon (`#0D0E12` / `#08090B`) with pure solid opacity (no radial blur glows).
  - Surfaces & Elevated Cards: Solid Studio Charcoal (`#16181F`), Active Playing Capsule (`#1E212B`), Unplayed Bars (`#252834`).
  - Accent: Clean Studio Emerald Mint (`#10B981` / `#34D399`).
  - Subtitle & Metadata: Neutral Slate Gray (`#94A3B8` / `#64748B`).
  - Typography: Pure White (`#FFFFFF`) with two-tone colored keywords (e.g., "Liked *Songs*", "Recently *Played*", "Equalizer *Studio*").
  - Small Meta Headers: Small uppercase tracking (`WELCOME, MATT`, `RECENTLY PLAYED`, `DOWNLOAD`).
- Core Layout & Screen Paradigms:
  - Track List: Uncarded, floating row layout for music tracks. Active track is highlighted in a soft dark capsule container with proportional vertical padding (10–12px) so borders never collide with audio format badges.
  - Now Playing: Prominent squircle album artwork (border radius 28–32px), centered bold track info, favorite heart button on left, interactive **waveform seekbar** (amplitude bars with played/unplayed contrast and tabular time figures), minimalist playback controls row, and a **compact auxiliary action bar** (34x30px solid studio icon buttons with tooltips for EQ, AutoEQ [unified Driver & Target matching dialog], Lyrics, and Queue, with concise format badge).
  - Dashboard: Personal greeting header, Studio Wrapped recap banner, Discovery Smart Mix suggestion banner (`StudioInstantMixBanner`), Quick YouTube HiFi streaming launcher, Recently Played grid (powered by real persistent playback history, strictly **2x2 grid** on mobile <650px), and Liked/Top songs list (with download toggle removed).
  - Floating MiniPlayer: Sleek floating pill/capsule dock pinned above the bottom navigation bar.
- Modern Iconography: ALL icons MUST use `lucide_icons_flutter` (`LucideIcons.*`) for crisp, consistent, unified aesthetics. NEVER mix generic legacy Material 1/2 icons or HugeIcons.
- Zero-Emoji Policy (Strictly Enforced): NEVER use emojis in UI widgets, button labels, dialog titles, snackbars, status texts, code, or documentation. Always use the available icon library (`LucideIcons.*`).
- Pure Solid & Anti-Neon Policy: Strictly NO glowing neon blur effects, garish colored drop-shadow halos, or blurry saturated card containers. Surfaces and dialog buttons (AutoEQ, Cloud Browser) must be crisp, solid studio containers (`#1E212B` / `#16181F`) with clean structural outlines (`Border.all`) and high-contrast text/icons.
- Anti-AI-Slop Policy: Follow `anti-ai-slop-ui` standards (high information clarity, tabular figures for audio data via `FontFeature.tabularFigures()`, restrained palettes, zero unreadable frosted glass or decorative bloat).
- Language: 100% English across all UI labels, tooltips, dialogs, snackbars, and messages.

Cross-Platform Architecture & Strict Platform Guards Mandate:
- Zero Regression Policy for Mobile/Android: Desktop features (Linux MPRIS D-Bus, Window Manager, System Tray, Desktop Drag-and-Drop) MUST strictly be protected with platform guards (`if (Platform.isLinux)`, `if (Platform.isAndroid)`, etc.) and responsive layout breakpoints (`>= 960px`).
- Desktop Mobile Window Mode CSD Safety: In mobile window layout (<650px) on desktop (`Platform.isLinux` / `isDesktopPlatform`), top action bars (e.g. `NowPlayingScreen` header) MUST incorporate an offset for `StudioDesktopTitleBar.barHeight` so window controls never obscure UI action buttons, while strictly preserving zero top padding offset on Android mobile/tablet devices.
- Desktop logic and plugins must NEVER break, overwrite, or cause regressions/crashes on the existing Android mobile/tablet experience (`NamidaExpandableMiniPlayer`, `FloatingRoundedDock`, mobile touch gestures, Scoped Storage).
- Mobile layout (< 960px or Android) and tablet dual-pane layout must remain 100% intact.

Testing Mandate & Sequential Execution Rules (Strictly Non-Negotiable):
- EVERY feature, bugfix, refactoring, controller, and UI layout update MUST include unit / widget test files (`test/..._test.dart`) to guarantee zero regression and deterministic state execution.
- Targeted Testing Preference: During development and verification, prefer running targeted test files (`flutter test test/specific_test.dart`) rather than global suite runs.
- Strict Anti-Parallel Execution for Global Tests:
  - If executing a global `flutter test` (without a specific file path), NEVER run another `flutter test` or `flutter analyze` in parallel/concurrently. Running them simultaneously causes extreme CPU, memory, and disk I/O thrashing.
  - ALWAYS wait for any running full test suite or analysis command to finish completely before launching another test or analysis command.
  - All heavy quality-gate commands (`flutter test`, `flutter analyze`) MUST be executed strictly sequentially, one by one.

Always-On Engineering Mandates — Ponytail & RTK Integration:
- Ponytail (Lazy Senior Dev Mode):
  - Solve every task with the smallest complete change. The best code is the code never written.
  - Avoid speculative features, unnecessary wrappers, duplicate abstractions, or over-engineering.
  - Be lazy about the solution, never about the change itself: finish every part the task needs (callers, tests, fixtures).
  - Shortest working diff wins. Bug fixes: grep callers first, fix root cause once in shared code.
  - End replies with 1-2 lines on what was skipped/deferred and any risks the user must know.
- RTK (Token Optimization & Idiomatic Simplification):
  - Minimize terminal and token waste: avoid dumping massive logs; use pagination (`-n <N>`) and specific paths.
  - Write lean, idiomatic code with functional chains, early returns, and zero redundant memory allocations.
  - Preserve strict error handling with context and verify with deterministic unit/widget tests.






