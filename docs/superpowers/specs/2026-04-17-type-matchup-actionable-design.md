# Typ-Matchup — Actionable Redesign

**Status:** Draft
**Datum:** 2026-04-17
**Ersetzt:** `plans/type-matchup-improvements.md` (archivieren)

## Kontext

`TypeMatchupView` (aktuell 262 Zeilen) zeigt drei Sektionen — Defensiv-Grid, Offensiv-Grid, Abdeckungs-Lücken — plus einen abstrakten Empfehlungs-Block ("Ein Feuer-Pokémon würde dein Team abrunden"). Die Analyse ist korrekt, aber passiv: der Spieler bekommt Rohdaten, muss daraus selbst ableiten, was zu tun ist.

Zwei konkrete Schmerzpunkte:

1. **Die Grids sind schwer zu scannen.** 18 flach angeordnete Zellen mit Text-Multipliern; die Problemzellen (×4, ×2) verstecken sich zwischen 12+ neutralen Zellen. Kein mentales Modell für "wo brennt's?".
2. **Die Empfehlungen sind nicht handlungsorientiert.** Der Spieler erfährt nicht, *welches* seiner Team-Mitglieder verzichtbar wäre und wodurch er es ersetzen sollte.

## Zielbild

Die View wechselt vom **Analyse-Dashboard** zum **Team-Coach**:

- Auf einen Blick erkennbar, welches Team-Mitglied wegen Redundanz tauschbar ist und durch welchen Typ.
- Defensiv-Übersicht nach Bedrohungsgrad gruppiert (Kritisch → Schwach → Neutral → Resistent → Immun).
- Offensiv-Übersicht bleibt flach, gewinnt aber durch Typ-Icons an Scanbarkeit.
- Abstrakte "Lücken" und "Empfehlung"-Sektionen entfallen — ihre Information lebt jetzt in der Team-Sektion und im Offensiv-Grid.

## Sheet-Struktur

```
┌─────────────────────────────────────────────────┐
│ Karmesin                               [Gen 9]  │
├─────────────────────────────────────────────────┤
│ Team-Check                                      │
│   Glurak   🔥💨   ★ Kernstück                   │
│                    Einziger Flug-Typ            │
│                                                 │
│   Endivie  🌿    ⚠ Ersetzen durch [💧] Wasser   │
│                    Redundant mit Meganie        │
│                                                 │
│   Meganie  🌿    ⚠ Ersetzen durch [💧] Wasser   │
│                    Redundant mit Endivie        │
│                                                 │
│   Mew      🧠    ◎ Ausgewogen                    │
├─────────────────────────────────────────────────┤
│ Defensiv-Übersicht                              │
│   ⚠ Kritisch (1)                                │
│     🧊 Eis     ×4    Glurak                     │
│   ⚠ Schwach  (3)                                │
│     ⚡ Elektro ×2    Glurak                     │
│     🪨 Gestein ×2    Glurak                     │
│     🧠 Psycho  ×2    Mew                        │
│   ▸ Neutral  (11)   (eingeklappt)               │
│   🛡 Resistent (2)   🌿 ×¼  💧 ×½               │
│   ✓ Immun (1)        🌍 ×0                      │
├─────────────────────────────────────────────────┤
│ Offensiv-Übersicht                              │
│   [🌿] [🔥] [💧] [⚡] [🧠] [🧊] [🥊] ...        │
└─────────────────────────────────────────────────┘
```

Sektionen **gestrichen** gegenüber dem heutigen Stand: "Abdeckungs-Lücken", Empfehlungs-Textblock.

## Team-Check — Algorithmus

### Berechnungen pro Team-Mitglied

| Metrik | Bedeutung |
|---|---|
| `unique_defense` | Anzahl Typen, gegen die nur dieses Mitglied resistent oder immun ist |
| `unique_offense` | Anzahl Typen, die nur dieses Mitglied mit `>1×` trifft |
| `leave_one_out` | Analyse des Teams ohne dieses Mitglied: wie viele neue ≥×2-Schwächen und neue Offensiv-Gaps (`all ≤ 1×`) entstehen? |
| `typ_ueberlappung` | Andere Team-Mitglieder mit mindestens einem gemeinsamen Typ — **nur für die Begründungszeile**, nicht für die Kategorisierung |

**Wichtig:** Typ-Überlappung ist kein Kategorisierungs-Kriterium. Bisasam (Pflanze/Gift) und Bibor (Käfer/Gift) teilen Gift, haben aber grundverschiedene Resistenzprofile — rein über `leave_one_out` wird die tatsächliche Team-Relevanz bewertet.

### Kategorisierung

| Kategorie | Bedingung |
|---|---|
| **Kernstück** ★ | `unique_defense + unique_offense ≥ 1` UND `leave_one_out` erzeugt ≥1 neuen Gap oder neue ≥×2-Schwäche |
| **Verzichtbar** ⚠ | `unique_defense + unique_offense == 0` UND `leave_one_out` erzeugt keine neuen Gaps und keine neuen ≥×2-Schwächen |
| **Ausgewogen** ◎ | alles dazwischen |

### Ersatz-Typ-Vorschlag (nur bei Verzichtbar)

1. Simuliere Team ohne dieses Mitglied.
2. Lasse `TypeChart.recommendation(...)` auf dem reduzierten Team laufen.
3. Top-1 Typ = Vorschlag.

Die Berechnung geschieht pro Mitglied unabhängig — zwei Verzichtbare können durchaus unterschiedliche Ersatz-Vorschläge erhalten, weil ihre reduzierten Teams verschieden sind. Nur im Spezialfall "identische Dual-Typen" (z.B. zwei Bisasam) fallen die Vorschläge zusammen.

**Audit-Abhängigkeit:** Die Qualität hängt vollständig an `TypeChart.recommendation(...)`. Aktuell scored diese Funktion Kandidaten mit `weaknesses_covered + gaps_filled` (gleichgewichtet). Vor der UI-Integration muss geprüft werden, ob dieses Scoring für "Ersatz bei Leave-one-out" sinnvolle Resultate liefert. Falls nicht, wird eine gewichtete Variante (×4-Schwächen höher als ×2, gleichzeitig Schwäche+Gap stärker als Einzel-Dimension) als Teil dieser Iteration nachgezogen.

### Begründungs-Halbsätze

Pro Zeile ein erklärender Nebensatz, abhängig von Kategorie:

- **Kernstück**: "Einziger Flug-Typ" / "Deckt 3 Schwächen allein ab" / "Einzige Antwort gegen Geist"
- **Verzichtbar** mit Typ-Überlappung: "Redundant mit Meganie"
- **Verzichtbar** ohne Typ-Überlappung: "Kein einzigartiger Beitrag"
- **Ausgewogen**: keine Begründung (weglassen)

### Edge-Cases

- **Leeres Team** → Hinweistext "Füge erst Pokémon zu deinem Team hinzu, um Matchup-Empfehlungen zu erhalten."
- **Nur Kernstück** → "Dein Team ist ausgewogen — keine Ersetzungs-Empfehlung."
- **Mehrere Verzichtbare** → jeder bekommt einen separat berechneten Ersatz-Vorschlag. Vorschläge können identisch oder unterschiedlich sein; Nutzer entscheidet, wie viele Tausche er vornimmt.

## Defensiv-Buckets

SwiftUI-Gerüst:

```swift
@AppStorage("typMatchup.neutralExpanded") private var neutralExpanded = false

List {
    Section {
        ForEach(critical) { row in DefensiveRow(row) }
    } header: {
        bucketHeader("Kritisch", symbol: "exclamationmark.octagon.fill",
                     tint: .red, count: critical.count)
    }

    Section { weakRows } header: {
        bucketHeader("Schwach", symbol: "exclamationmark.triangle.fill",
                     tint: .orange, count: weak.count)
    }

    Section {
        DisclosureGroup(isExpanded: $neutralExpanded) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) { neutralChips }
        } label: {
            bucketHeader("Neutral", symbol: "equal.circle",
                         tint: .secondary, count: neutral.count)
        }
    }

    Section { resistantRows } header: {
        bucketHeader("Resistent", symbol: "shield.lefthalf.filled",
                     tint: .blue, count: resistant.count)
    }

    Section { immuneRows } header: {
        bucketHeader("Immun", symbol: "checkmark.seal.fill",
                     tint: .green, count: immune.count)
    }
}
.listStyle(.inset)

// Header-Helper: nur das Icon ist farbig, Text bleibt neutral
private func bucketHeader(_ title: String, symbol: String,
                          tint: Color, count: Int) -> some View {
    HStack(spacing: 6) {
        Image(systemName: symbol).foregroundStyle(tint)
        Text(title)
        Spacer()
        Text("\(count)").foregroundStyle(.secondary).monospacedDigit()
    }
}
```

Zeile: `[Typ-Icon] [Typ-Label] [×Multiplier monospaced] [betroffene Team-Member, secondary]`.

Bucket-Farben leben **ausschließlich im SF-Symbol**. Text-Labels bleiben neutral — farbige Überschriften sind auf macOS unüblich und würden mit Liquid-Glass-Chrome brechen. Das Icon ist redundanter Kanal zur Farbe (Accessibility).

Leere Buckets werden ausgeblendet. "Neutral" ist per Default eingeklappt; der Zustand persistiert über `@AppStorage`, damit Nutzer, die ihn einmal öffnen, ihn nicht bei jedem Sheet-Aufruf neu aufklappen müssen.

## Offensiv-Grid — flach, aber lesbarer

Struktur wie heute (`LazyVGrid` mit Zellen in kanonischer Ordnung). **Zellen kommen ausschließlich aus `generation.allTypes`** — Gen 1 rendert 15 Zellen (ohne Unlicht, Stahl, Fee), Gen 2–5 rendert 17 (ohne Fee), Gen 6+ rendert 18. Dasselbe gilt für die Defensiv-Buckets. Icon-Set deckt 18 Typen, nicht genutzte Icons bleiben im Asset-Catalog liegen.

Änderungen gegenüber heute:

- **Typ-Icon prominent** (oben in Zelle), Label darunter klein
- **Zellen mit `×1` stark abgedunkelt** (`.opacity(0.3)`) — Auge wird auf Non-Trivial gelenkt
- **`>1×` Zellen**: dünner grüner Outline-Rahmen
- **`<1×` Zellen**: dünner roter Outline-Rahmen
- **Multiplier**: monospace-Zahl rechts unten

Hintergrund bleibt neutral (`.fill.quaternary`) — Farbe lebt im Typ-Icon, nicht im Container (macOS-Pattern aus Stocks/Storage).

## Icons — partywhale/pokemon-type-icons

- **Source**: <https://github.com/partywhale/pokemon-type-icons>
- **Lizenz**: MIT, alle 18 Typen inkl. Fee, SVG
- **Einbindung**: in `Assets.xcassets/TypeIcons/<typ>.svg` mit "Preserves Vector Data = YES"
- **Utility**: neuer `PokemonTypeIcon.image(for type: String) -> Image`
- **Rendering**: `.renderingMode(.template)` + `.foregroundStyle(PokemonTypeColor.color(for:))`
- **Lizenznotiz**: `CREDITS.md` im Repo-Root enthält den **vollständigen MIT-Lizenztext** inkl. Copyright-Header (nicht nur eine Erwähnung)
- **Gitignore**: SVGs werden committed (Design-Asset, kein generierter Content)

## Datenstruktur & Service

Neue Komponente `TeamCheckAnalyzer.swift` (Service-Layer, keine UI-Abhängigkeiten):

```swift
struct TeamMemberAnalysis: Equatable {
    let memberName: String
    let types: [String]
    let category: Category
    let reason: String?

    enum Category: Equatable {
        case kernstueck
        case ausgewogen
        case verzichtbar(ersatzTyp: String)
    }
}

enum TeamCheckAnalyzer {
    static func analyze(
        team: [(name: String, types: [String])],
        generation: TypeChartGeneration
    ) -> [TeamMemberAnalysis]
}
```

Bestehender `TypeChart` bleibt **überwiegend** unverändert — neuer Analyzer konsumiert ihn. Falls das Audit (siehe Abschnitt "Audit-Abhängigkeit") zeigt, dass `TypeChart.recommendation(...)` für den neuen Use Case unscharfe Vorschläge liefert, wird eine gewichtete Score-Variante hinzugefügt (4×-Schwächen doppelt gewichtet, Kandidaten mit Schwäche+Gap-Doppelnutzen bevorzugt).

**Performance:** Der Analyzer wird bei jeder Sichtbar-Werdung des Sheets neu berechnet. 6 Mitglieder × konstante TypeChart-Operationen ist billig (<1ms), aber Re-Renders durch SwiftData-Updates könnten denselben Input mehrfach triggern. Der View cached das `[TeamMemberAnalysis]`-Resultat in einem `@State` und invalidiert es, wenn sich `game.currentTeam` oder `game.generation` ändert (via `.onChange`).

View-Layer-Umbau: `TypeMatchupView` wird von `ScrollView + VStack` auf `List` umgestellt; `MatchupCell` bleibt für die Neutral-Disclosure-Chips und das Offensiv-Grid, wird aber auf Icon-Darstellung erweitert.

## Tests

Neue Datei `TeamCheckAnalyzerTests.swift`:

- Leeres Team → `[]`
- Einzelnes Mitglied → immer Kernstück
- 2 identische Dual-Typen (z.B. zwei Bisasam) → beide Verzichtbar, identischer Ersatz-Typ
- 2 Mitglieder mit einem geteilten Typ bei sonst unterschiedlichem Profil (Bisasam Pflanze/Gift + Bibor Käfer/Gift) → Typ-Überlappung existiert, aber Kategorisierung hängt rein an Leave-one-out — Ergebnis kann Kernstück/Kernstück sein (wenn beide einzigartige Beiträge liefern)
- Kernstück-Erkennung: Team mit einem Flug-Typ → Flug-Typ ist Kernstück (leave-one-out erzeugt neue Lücke)
- Ausgewogen-Kategorie: Mitglied bringt keine einzigartige Deckung, aber leave-one-out erzeugt neue Schwäche
- Ersatz-Vorschlag-Begründung: bei Typ-Überlappung "Redundant mit <Partner>", sonst "Kein einzigartiger Beitrag"
- **Generations-Regression**: Identisches Team (z.B. Bisasam + Arbok) unter `.gen1` vs `.gen6plus` → unterschiedliche Kategorisierung, weil Gift gegen Fee (Gen 6+) vs. nicht-existent (Gen 1) die Offensiv-Lücken verändert

Bestehende `TypeChartTests` bleiben unberührt.

## Accessibility

- `TeamMemberRow`: `.accessibilityElement(children: .combine)` mit Label "Glurak, Kernstück, einziger Flug-Typ"
- Verzichtbar: "Bisasam, verzichtbar, Vorschlag Wasser-Typ, redundant mit Meganie"
- Defensiv-Zeile: "Eis, vierfach Schaden, betrifft Glurak"
- Typ-Icons: `accessibilityLabel("<Typ>-Typ")`
- VoiceOver-Reihenfolge folgt Bucket-Priorität (Kritisch zuerst)

## Out of Scope / Spätere Iteration

Aus dem ursprünglichen `plans/type-matchup-improvements.md` werden folgende Punkte **nicht** jetzt umgesetzt:

- **Konkrete Pokémon-Namen** statt Typ-Vorschlag (§1 Variante 2/3) — Datenbasis für Spiel-Verfügbarkeit fehlt.
- **Dual-Typ-Popover** mit Multiplier-Herleitung (§3).
- **Score-Begründung im UI** mit gewichteten Schwächen (§4) — leave-one-out gewichtet bereits implizit.
- **Spiel-Verfügbarkeits-Daten** in `pokemon.json` (§1 Variante 3).

## Definition of Done

- `./scripts/test.sh build` sauber (0 errors, 0 warnings)
- `./scripts/test.sh unit` grün, inkl. neuer `TeamCheckAnalyzerTests`
- `./scripts/test.sh test` grün
- Sheet im laufenden App mit realem Team getestet: Team-Check zeigt plausible Kategorien, Defensiv-Buckets korrekt gefüllt, Neutral-Disclosure funktioniert, Icons rendern in Typ-Farbe
- `CREDITS.md` mit vollständigem MIT-Lizenztext für Icons existiert
- Alter Plan `plans/type-matchup-improvements.md` ins `plans/done/`-Verzeichnis verschoben (oder gelöscht — Historie bleibt in git)
