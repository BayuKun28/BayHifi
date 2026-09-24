# Baydev HiFi — Agent Instructions & Rules

Project rules and guidelines are defined in [rules.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/rules.md).
Architecture and technical blueprint are defined in [baydev_hifi_blueprint.md](file:///home/x/.gemini/antigravity/brain/de5a70a9-7984-4d09-abda-d9ef144ce06a/baydev_hifi_blueprint.md).
Todo tasks and implementation progress are tracked in [task.md](file:///mnt/01DC9A2666E1A190/Other/PROJECTS/BayHifi/task.md).

Always adhere strictly to the design principles, performance rules, Dart 3 code standards, and folder structure specified in `rules.md`.

Audio engine dependency mandate:
- `flutter_soloud` MUST be sourced from the local sibling directory `/mnt/01DC9A2666E1A190/Other/PROJECTS/flutter_soloud` (`path: ../flutter_soloud`), NEVER from pub.dev.
- The agent has full access to read and customize C++ filters in `flutter_soloud`.

