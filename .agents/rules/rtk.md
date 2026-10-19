# RTK — Token Optimization & Code Simplification Mandate

## 1. Terminal & Command Token Optimization
- When running CLI tools and inspecting repositories, minimize token consumption:
  - Avoid unbounded logs or huge outputs. Use pagination flags (e.g. `git log -n 5`, `head -n 50`, ripgrep specific paths).
  - Use `rtk` CLI filters (`~/.local/bin/rtk`) when analyzing command outputs to filter out noise while preserving critical failure and status information.
  - Check `rtk gain` to track token and cost savings.

## 2. Code Simplification & Idiomatic Cleanliness
- Keep implementations idiomatic, direct, and lean:
  - Prefer functional chains and built-in collection methods over manual nested accumulator loops.
  - Avoid redundant string/buffer copies and unnecessary allocations.
  - Use early returns (`guard` / `if (...) return;`) to eliminate deep nesting and improve readability.
  - Avoid over-engineered abstractions, factories, or generic indirection where a straightforward, direct function or class fully solves the problem.
  - Maintain robust error handling with actionable context; never swallow errors or silently drop failures.
  - Every non-trivial logic change or refactoring must be backed by deterministic unit/widget tests.
