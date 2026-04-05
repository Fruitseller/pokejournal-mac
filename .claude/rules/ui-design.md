# UI Design Rules

Visual quality standards for this project. The UI design reviewer reads
this file and uses it to evaluate screenshots and code changes.

## Design System

- **Platform:** macOS 26+, Liquid Glass design language
- **Component library:** SwiftUI native — no third-party UI dependencies
- **Color palette:**
  - System accent color (default blue) — no custom AccentColor override
  - Semantic SwiftUI colors for backgrounds: `.fill`, `.secondary`, `.tertiary`, `.quaternary`
  - Pokémon type colors via `PokemonTypeColor` (18 types, hardcoded RGB)
  - Status indicators: green (new), purple (evolved), orange (legacy/metacritic), red (removed)
- **Typography:** SF Pro (system default)
  - `.largeTitle` — page headers
  - `.headline` — section headers
  - `.subheadline` with `.secondary` — secondary text
  - `.body` — content text
  - `.caption` / `.caption2` — labels, badges, metadata
- **Spacing:** 8pt baseline grid
  - Fine: 2pt, 4pt
  - Component: 8pt, 12pt
  - Section: 16pt, 24pt
  - Hero: 48pt
- **Corner radius:** 8pt (buttons, rows), 12pt (cards), 16pt (content sections)
- **Cards:** `.fill.quaternary` background with `RoundedRectangle(cornerRadius: 12)`
- **Badges:** `.opacity(0.2)` color background in `Capsule()`

## Screenshot Capture

This is a native macOS app. No simulator or browser capture applies.
The reviewer should evaluate code changes and SwiftUI previews directly.

## Navigation

- `ContentView` → `NavigationSplitView` (sidebar + detail)
- `Views/GameListView` → Sidebar game list
- `Views/GameDetailView` → Detail pane with 5 tabs: Sessions, Timeline, Heatmap, Team Analysis, Team Evolution
- `Views/SessionDetailView` → Session detail (navigated from session list)
- `Views/SettingsView` → Modal sheet from toolbar
- `Views/VaultSetupView` → First-run vault selection

## Visual Standards

- Use semantic SwiftUI colors (`.fill`, `.secondary`, etc.) — never hardcode light/dark color values
- Consistent alignment and visual rhythm across related screens
- Use design tokens for spacing and typography — minimize magic numbers
- Respect macOS conventions: toolbar buttons, sidebar styling, keyboard navigation
- Glass effects (`.glassEffect`) for overlay/loading states per Liquid Glass guidelines

## Accessibility Requirements

- All images and icons must have accessibility labels
- Interactive elements must have accessibility identifiers for UI testing
- Support Dynamic Type / font scaling
- Color must not be the sole means of conveying information
- Pokémon sprites should have accessibility labels with the Pokémon name

## Exceptions / Intentional Violations

- UI language is German (matches Obsidian vault content) — not a localization bug
- Heatmap cells use 12pt fixed size by design (information density requires small cells)
- Pokémon type colors are hardcoded RGB to match franchise standard colors, not design tokens
