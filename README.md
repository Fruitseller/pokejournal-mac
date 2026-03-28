# PokéJournal

A native macOS app for visualizing and analyzing Pokémon gaming sessions from your Obsidian vault.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.2-orange)
![License](https://img.shields.io/badge/License-Unlicense-green)

## Philosophy

- **Local-first** - Your data stays in your Obsidian vault. No cloud, no sync, no account.
- **Read-only** - Obsidian is the source of truth. The app visualizes but never modifies your files.
- **Native** - A real macOS app with SwiftUI, not an Electron wrapper.
- **Plain text** - Standard Markdown files. No proprietary formats, no lock-in.

## Features

- **Game Library** - Automatically discovers Pokémon games from your Obsidian vault
- **Session Tracking** - View all your gaming sessions with activities, plans, and thoughts
- **Team Visualization** - See your team composition with official Pokémon artwork
- **Timeline View** - Visual timeline of sessions with gap detection
- **Hall of Fame** - Statistics showing your most-used Pokémon
- **Obsidian Integration** - Open session files directly in Obsidian

## Requirements

- macOS 26 (Tahoe) or later
- Xcode 26
- Python 3 (for setup script)
- An Obsidian vault with Pokémon session notes

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Fruitseller/pokejournal-mac.git
   cd pokejournal-mac
   ```

2. **Download Pokémon data and sprites**
   ```bash
   python3 scripts/fetch_pokemon_data.py
   ```
   This fetches data from PokéAPI and downloads ~1000 Pokémon sprites. Takes a few minutes.

3. **Open in Xcode and run**
   ```bash
   open PokeJournal/PokeJournal.xcodeproj
   ```
   Press ⌘R to build and run.

4. **Select your Obsidian vault** when prompted on first launch.

## Vault Structure

The app expects your Pokémon notes in this structure:

```
your-vault/
└── hobbies/videospiele/pokemon/
    ├── purpur/
    │   ├── purpur.md              # Game metadata (YAML frontmatter)
    │   └── sessions/
    │       ├── 2024-01-15_purpur.md
    │       └── 2024-01-20_purpur.md
    ├── karmesin.md                # Legacy format (inline sessions)
    └── old_purpur.md              # Old sessions archive
```

### Game File Format

```yaml
---
aliases:
  - "Pokémon Purpur"
release: 2022-11-18
platforms:
  - Nintendo Switch
genre: RPG
developer: Game Freak
metacritic: 71
---
```

### Session File Format

```markdown
## Aktivitäten
What you did in this session...

## Pläne
Plans for next session...

## Gedanken
Thoughts and notes...

## Team
- Pikachu lvl 45
- Glurak lvl 50
- Aloha Raichu lvl 42
```

## Tech Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Data persistence
- **MVVM** - Architecture pattern
- Pokémon data from [PokéAPI](https://pokeapi.co/)

## License

Unlicense - see [LICENSE](LICENSE) for details.

Pokémon and Pokémon character names are trademarks of Nintendo. This project is not affiliated with or endorsed by Nintendo, Game Freak, or The Pokémon Company.
