# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PokéJournal is a native macOS app that visualizes and analyzes Pokémon gaming sessions by reading from a local Obsidian Vault. It tracks game progress, team composition, and session history.

**Tech Stack:** macOS 26+, Swift 6.2+, SwiftUI, SwiftData, MVVM architecture, Liquid Glass Design Language

## Setup After Clone

**Required:** Download Pokémon data and sprites before building:

```bash
python3 scripts/fetch_pokemon_data.py
```

This fetches ~1000 Pokémon from PokéAPI CSV dumps, generates `pokemon.json`, and downloads sprites into the Asset Catalog. Takes a few minutes. Both `pokemon.json` and sprites are in `.gitignore` - re-run the script to update when new Pokémon are released.

Options:
- `--limit N` - Only fetch first N Pokémon (for testing)
- `--workers N` - Parallel downloads (default: 5)

## Build Commands

```bash
# Using the test script (recommended)
./scripts/test.sh build  # Build only
./scripts/test.sh unit   # Run unit tests only (fast, no UI)
./scripts/test.sh test   # Run all tests (including UI tests)

# Or using xcodebuild directly
xcodebuild -project "PokeJournal/PokeJournal.xcodeproj" -scheme "PokeJournal" build
xcodebuild -project "PokeJournal/PokeJournal.xcodeproj" -scheme "PokeJournal" test

# Build and run (typically done via Xcode ⌘R)
open "PokeJournal/PokeJournal.xcodeproj"
```

## Build & Test Loops

**Critical:** After EVERY code change, complete these loops autonomously BEFORE moving to the next task.

### 1. Build Loop
```bash
./scripts/test.sh build
```
On errors: Read logs → fix code → rebuild. Iterate until clean build.

### 2. Test Loop
```bash
./scripts/test.sh unit   # Fast unit tests only
./scripts/test.sh test   # All tests including UI (slower)
```
On failures: Analyze output → fix tests/code → re-run.


### Success Criteria for "Done"
- ✅ Clean build (0 errors, 0 warnings)
- ✅ All tests passing
- ✅ App launches without crashes
- ✅ Affected features functionally tested

**Anti-Pattern:** Write code → "should work" → move to next task
**Correct:** Code → Build → Test → Fix → Verify → Then continue

## Architecture

### Data Flow
1. **VaultManager** handles Obsidian vault folder selection using security-scoped bookmarks (sandboxing)
2. **DataLoader** orchestrates scanning and loading markdown files
3. **MarkdownParser** extracts YAML frontmatter and session content
4. **SwiftData** persists entities (Game, Session, OldSession, TeamMember)
5. Views use `@Query` for automatic data fetching

### Key Services (`Services/`)
- **VaultManager.swift** - Vault access with NSOpenPanel and security-scoped bookmarks
- **DataLoader.swift** - Async data pipeline, scans configured Pokemon folder in vault
- **MarkdownParser.swift** - YAML and markdown parsing, bilingual (German/English)
- **FileWatcher.swift** - GCD-based file system monitoring for auto-reload

### Data Models (`Models/`)
- **Game** → Sessions (1:n) + OldSessions (1:n), with cascade delete
- **Session/OldSession** → TeamMembers (1:n)
- **Pokemon** - Struct (not persisted), loaded from `pokemon.json`, includes fuzzy name matching and evolution chain grouping (`evolutionChainID`)

### Views (`Views/`)
- **ContentView** - NavigationSplitView root with sidebar/detail
- **GameDetailView** - Tabbed interface (Sessions, Timeline, Team Analysis)
- **TimelineView** - Horizontal timeline with gap detection (color-coded)
- **TeamAnalysisView** - Usage stats and Hall of Fame

## Markdown File Formats

**Game file (`[gamename].md`):**
```yaml
---
aliases: [Pokémon Purpur]
release: 2022-11-18
platforms: [Nintendo Switch]
genre: RPG
developer: Game Freak
metacritic: 72
---
```

**Session file (`[gamename]/sessions/YYYY-MM-DD_gamename.md`):**
```markdown
## Aktivitäten
[activities]

## Team
- Glurak lvl 65
- Aloha Raichu lvl 60
```

**Legacy format (`old_[gamename].md`):** Sessions split by `## YYYY-MM-DD` headers

## Key Implementation Notes

- **Test focus:** Don't test framework behavior (e.g. SwiftData cascade deletes) — focus tests on our own logic.
- Pokémon name matching uses Levenshtein distance (0.8 threshold) for German/English/variant support
- Pokémon sprites are bundled in Asset Catalog (no network required at runtime)
- Obsidian integration uses URL scheme: `obsidian://open?vault=[vaultName]&file=[path]`
- App uses `@Observable` for services, `@Query` for SwiftData, `@AppStorage` for preferences
- No external dependencies - pure Apple frameworks, sandboxed

## Liquid Glass Rules
- .glassEffect() only on floating navigation controls, NEVER on content
- Use GlassEffectContainer for grouping nearby glass elements
- System NavigationSplitView/toolbar get glass automatically — don't double-apply
- .glassEffect() as last modifier in chain
- .regular.interactive() for primary actions, .clear with dimming for busy backgrounds

## Git Conventions

- Short subject line (~50 chars), e.g. "Redesign timeline view"
- Body optional — use it when the "why" isn't obvious, skip it for trivial changes
- Don't pad every commit with a body just because you can
