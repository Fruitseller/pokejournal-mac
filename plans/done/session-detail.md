# Session-Detailansicht

Klick auf eine Session in der Sessions-Liste zeigt eine vollwertige Detailansicht. Derzeit sind die Rows nicht interaktiv, obwohl ein Chevron-Icon Navigation suggeriert. Eine `SessionDetailView` existiert bereits, ist aber nicht erreichbar und unterstützt nur das neue Session-Format.

## Ansatz: AnySession-Enum + NavigationStack-Push

### 1. AnySession-Enum

Vereinheitlicht `Session` und `OldSession` in einem Typ:

```swift
enum AnySession: Hashable, Identifiable {
    case regular(Session)
    case old(OldSession)

    var id: String { ... }
    var date: Date { ... }
    var activities: String { ... }
    var plans: String { ... }
    var thoughts: String { ... }
    var team: [TeamMember] { ... }
    var isOld: Bool { ... }
    var filePath: String? { ... }  // nil bei OldSession
    var hasTeam: Bool { ... }
}
```

Ersetzt das aktuelle `(date: Date, isOld: Bool, session: Any)` Tuple in `SessionsListView`.

### 2. NavigationStack in ContentView

Detail-Spalte in `ContentView.swift` mit `NavigationStack` wrappen. Bei Klick auf eine Session-Row wird die gesamte `GameDetailView` durch die `SessionDetailView` ersetzt (mit Back-Button).

### 3. SessionsListView klickbar machen

- `allSessions` liefert `[AnySession]` statt Tuples
- Rows werden `NavigationLink(value: AnySession)`
- `.navigationDestination(for: AnySession.self)` registrieren
- Vorherige Session (chronologisch) ermitteln und `previousTeam` an Detail-View weitergeben

### 4. SessionDetailView erweitern

Akzeptiert `AnySession` statt `Session`. Zusätzlicher Parameter `previousTeam: [TeamMember]`.

**Aufbau der Detailansicht:**

1. **Header** - Datum, Spielname, optional "Altes Format"-Badge, optional Obsidian-Button
2. **Team-Grid** - Sprites, Namen, Level (via `TeamSectionView`)
3. **Team-Veränderungen** (neu, nur wenn `previousTeam` vorhanden und Unterschiede existieren):
   - Neue Pokemon: grunes Badge "Neu"
   - Entfernte Pokemon: rotes Badge "Entfernt"
   - Level-Ups: Pfeil mit Delta (z.B. "+5")
   - Vergleich uber `pokemonName` (case-insensitive)
4. **Aktivitaten** - Textblock mit Gamecontroller-Icon
5. **Plane** - Textblock mit Listen-Icon
6. **Gedanken** - Textblock mit Brain-Icon

### 5. OldSession-Handling

OldSessions sind klickbar und zeigen die gleiche Detailansicht, mit:
- Kein "In Obsidian offnen"-Button (kein `filePath`)
- "Altes Format"-Badge im Header
- Team-Diff funktioniert identisch

## Betroffene Dateien

| Datei | Anderung |
|-------|----------|
| `PokéJournal/ContentView.swift` | NavigationStack um Detail-Spalte |
| `PokéJournal/Views/SessionsListView.swift` | AnySession, NavigationLinks, previousTeam-Berechnung |
| `PokéJournal/Views/SessionDetailView.swift` | AnySession-Support, Team-Diff-Sektion |
| Neue Datei oder `Session.swift` | AnySession-Enum Definition |

## Verifizierung

1. `./scripts/test.sh build` - sauberer Build
2. `./scripts/test.sh unit` - alle Tests grun
3. Manuell: Klick auf Session -> Detail mit Back-Button
4. Manuell: Team-Diff zeigt neue/entfernte Pokemon und Level-Anderungen
5. Manuell: OldSession klickbar, ohne Obsidian-Button, mit Badge
6. Manuell: Back-Button fuhrt zuruck zur GameDetailView
