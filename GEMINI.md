# Baydev HiFi — Agent Instructions & Rules

Project rules and guidelines are defined in [rules.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/rules.md).
Architecture and technical blueprint are defined in [baydev_hifi_blueprint.md](file:///home/x/.gemini/antigravity/brain/de5a70a9-7984-4d09-abda-d9ef144ce06a/baydev_hifi_blueprint.md).
Todo tasks and implementation progress are tracked in [task.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/task.md).

Always adhere strictly to the design principles, performance rules, Dart 3 code standards, and folder structure specified in `rules.md`.

Audio engine dependency mandate:
- `flutter_soloud` MUST be sourced from the local sibling directory `/mnt/01DC9A2666E1A190/Other/PROJECTS/flutter_soloud` (`path: ../flutter_soloud`), NEVER from pub.dev.
- The agent has full access to read and customize C++ filters in `flutter_soloud`.

UI/UX, Theming & Iconography Standards (Strictly Non-Negotiable):
- Material 3 Expressive Semi-Minimalist Architecture: Follow official Material 3 Expressive guidelines with clean, uncrowded, semi-minimalist Bento layouts, generous breathing room, squircle tokens (`8px`, `12px`, `16px`, `20px`, `28px`, `999px`), 1px crisp studio borders, tonal elevation containers, spring physics, and staggered entrance micro-animations (`flutter_animate`). All horizontal carousels and bento cards MUST align flush with the grid margins.
- Solid Surfaces & Minimal Restrained Gradients Mandate: UI components such as cards, containers, dialogs, banners, and settings overviews MUST use solid Material 3 surface colors (`theme.colorScheme.surface`, `surfaceContainer`, `surfaceContainerHighest`). Multi-color decorative gradients are strictly forbidden. Gradients are only permitted when ultra-minimal and strictly functional (e.g., DSP curve area fills, lyrics ShaderMask edge fades, vinyl reflection sheen).
- Strict Theme Color Palette Compliance (Zero Hardcoded Random Colors): ALL UI components, cards, graphs, badges, borders, and icons MUST strictly derive their colors from the active `Theme.of(context).colorScheme` and `AppPalette` (`primary`, `secondary`, `tertiary`, `surface`, `surfaceContainer`, `outline`, `onSurface`, `onSurfaceVariant`). NEVER use hardcoded random colors outside the active theme palette.
- Non-Neon & Restrained Studio Palette Mandate: Strictly avoid garish, eye-straining, oversaturated neon glows. Use refined, balanced, studio-grade tones (Sky Studio, Warm Tube Amber, Precision Mint, Violet, Muted Rose, Gold). Dynamic album art extraction via `palette_generator` must be harmonized and softened into elegant studio palettes.
- Modern Iconography: ALL icons MUST use `hugeicons` (`HugeIcons.strokeRounded...` / `HugeIcons.solidRounded...`) for crisp, consistent, unified studio aesthetics. NEVER mix generic legacy Material 1/2 icons.
- Zero-Emoji Policy (Strictly Enforced): NEVER use emojis in UI widgets, button labels, dialog titles, snackbars, status texts, code, or documentation. Always use the available icon library (`hugeicons`).
- UI Reference Fidelity: Every new screen, card, modal, bottom sheet, and widget MUST strictly align with the established UI design references (`collection_dark`, `collection_light`, `customization_settings`, `yt_miniplayer`, `pro_q_studio`).
- Navigation: Use a floating rounded dock / capsule navigation bar with squircle corners, subtle backdrop blur, and smooth active pill indicators.
- Anti-AI-Slop Policy: Follow `anti-ai-slop-ui` skill standards (high information clarity, tabular figures for audio data via `FontFeature.tabularFigures()`, restrained studio palettes, zero unreadable frosted glass or meaningless decorative bloat).
- Language: 100% English across all UI labels, tooltips, dialogs, snackbars, and messages.

Testing Mandate (Strictly Non-Negotiable):
- EVERY feature, bugfix, refactoring, controller, and UI layout update MUST include unit / widget test files (`test/..._test.dart`) to guarantee zero regression and deterministic state execution.
- Always run `flutter test` and `flutter analyze` after completing tasks to maintain 100% passing tests with 0 errors and 0 warnings.



