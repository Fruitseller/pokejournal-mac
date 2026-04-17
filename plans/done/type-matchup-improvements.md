# Typ-Matchup Verbesserungen

## Kontext

Die erste Version von `TypeMatchupView` liefert die Rohanalyse — Defensiv-/Offensiv-Grid, Abdeckungs-Lücken-Liste, Empfehlungs-Text. Zwei Schwachpunkte:

1. **Abdeckungs-Lücken & Empfehlungen sind zu abstrakt.** "Ein Wasser-Pokémon würde dein Team abrunden" sagt dem Spieler nicht, *welches* Wasser-Pokémon in der aktuellen Spielwelt verfügbar ist. Die Lücke "Drache" bleibt eine leere Capsule ohne konkreten Handlungsimpuls.
2. **Die Grids lesen sich flach.** Alle Zellen sehen formal gleich aus — nur die Hintergrundfarbe unterscheidet weak/neutral/resist. Typfarben, Sprites und Gruppierung nach Multiplikator fehlen. Lange deutsche Labels wie "Gestein" / "Elektro" passen bei 100pt Mindestbreite knapp.

## Zielbild

Ein Sheet, das auf einen Blick zeigt *was zu tun ist*, nicht nur *was ist*:

- Lücken-Chips führen zu konkreten Pokémon-Vorschlägen aus dem aktuellen Spiel (falls das Spiel bekannt ist) oder der Generation.
- Empfehlungen nennen 2–3 konkrete Pokémon-Namen pro Typ statt einer Phrase.
- Die Grids werden visuell ruhiger, die Zellen informations-dichter und nach Relevanz gruppiert.

## Verbesserungsbereiche

### 1. Konkrete Pokémon in Lücken & Empfehlungen

**Problem:** Die aktuelle Empfehlung ist ein Typname. Der Spieler muss selbst überlegen, welche Pokémon dieses Typs im aktuellen Spiel verfügbar sind und welche davon zur Team-Zusammensetzung passen.

**Idee:** Für jeden empfohlenen Typ 2–3 konkrete Pokémon-Kandidaten anzeigen:

```
Empfehlung
● [Sprite] Vulnona     Ein Feuer-Pokémon: deckt Eis-, Stahl- und Käfer-Lücken ab.
● [Sprite] Gengar      Ein Geist-Pokémon: resistent gegen deine Kampf-Schwäche.
● [Sprite] Nidoking    Ein Boden-Pokémon: füllt zwei Abdeckungs-Lücken.
```

**Kandidaten-Auswahl** (von einfach nach aufwändig):

1. **Einfach:** Alle Pokémon in `PokemonDatabase` mit passendem Typ filtern, drei zufällige / mit niedriger ID auswählen. Schnell, aber irrelevant falls das Pokémon im aktuellen Spiel nicht existiert.
2. **Besser:** Spiel-spezifische Verfügbarkeit prüfen. PokéJournal weiß aber nur, *welche* Pokémon bisher im Team waren — nicht, welche im Spiel verfügbar sind. Optionale Ergänzung: generation-basiertes Limit (`pokemon.id <= dexCap(generation)`).
3. **Aspirational:** `pokemon.json` um Spiel-Verfügbarkeit erweitern. Mehr Daten-Pipeline-Aufwand, aber fundierteste Empfehlungen.

Für V1 reicht Variante **2** (Generation-Cap).

**Analog für Abdeckungs-Lücken:** Pro Lücken-Typ zeigen, welche Pokémon diesen Typ super-effektiv treffen würden (gegenteilige Richtung — Angreifer-Vorschläge).

### 2. Visuelle Verbesserungen der Grids

**Problem:** Zellen sind austauschbar, nur Hintergrundfarbe differenziert. Typfarben aus `PokemonTypeColor` werden nicht genutzt.

**Ideen:**

- **Typ-Punkt links im Zellen-Header:** Ein kleiner farbiger Kreis in Typfarbe (`PokemonTypeColor.color(for:)`) vor dem Typ-Label. Bringt Wiedererkennungswert und bricht die Uniformität.
- **Multiplikator als Icon statt Text:** `2×` → ▲▲, `0.5×` → ▼, `0×` → ✕, `4×` → ▲▲▲▲. Oder Balken-Indikator.
- **Gruppiertes Layout statt flaches Grid:**
  - Defensiv: `⚠️ Schwächen (×2, ×4)` / `🛡 Resistenzen (×½, ×¼)` / `➖ Neutral` / `✓ Immunitäten`
  - Offensiv: analog nach Stärke-Bucket
  - Nur die ersten beiden Gruppen standardmäßig ausgeklappt, "Neutral" eingeklappt — reduziert visuelles Rauschen.
- **Sprite des schwächsten/stärksten Team-Mitglieds pro Zelle** (statt nur Tooltip): Bei einer 4×-Schwäche zeigt die Zelle den betroffenen Pokémon-Sprite klein rechts.
- **Responsive Breite:** Minimum 100pt ist für "Gestein" und "Elektro" grenzwertig bei Standard-Font. Option A: Mindestbreite auf 110pt anheben. Option B: `.minimumScaleFactor(0.8)` schon gesetzt — akzeptabel, aber nicht schön.

### 3. Kontextualisierung

**Problem:** Die drei Sektionen (Defensiv / Offensiv / Abdeckungs-Lücken) doppeln Information. Lücken-Liste ≈ alle Offensiv-Zellen mit Multiplikator ≤ 1.

**Ideen:**

- **Lücken-Sektion entfernen**, durch "schwache Offensive" Bucket im Grid ersetzen.
- **Dual-Typ-Zerlegung in Detail-Popover:** Bei Klick auf eine Zelle zeigt ein Popover, wie sich der Multiplikator zusammensetzt (z.B. "Gestein ×4 = Feuer×2 × Flug×2 für Glurak").
- **Zusammenfassungs-Banner am Kopf:**
  > "3 schwere Schwächen · 2 Abdeckungs-Lücken · Team-Balance 7/10"
  
  Ein kompakter Score, der die Übersichtlichkeit erhöht.

### 4. Empfehlungs-Scoring verfeinern

**Problem:** Der aktuelle Scoring-Algorithmus (`#weaknesses_covered + #gaps_filled`) gewichtet beide Aspekte gleich. Ein Kandidat, der 3 Lücken füllt aber keine Schwäche deckt, schlägt einen Kandidaten, der 2 schwere Schwächen abdeckt.

**Ideen:**

- **Gewichtung nach Schweregrad:** 4×-Schwächen stärker gewichten als 2×-Schwächen (doppelter Score-Wert).
- **Typen bevorzugen, die mehrere Dimensionen gleichzeitig bedienen:** Ein Typ, der sowohl eine Schwäche deckt *als auch* eine Lücke füllt, ist wertvoller als ein reiner Single-Purpose-Kandidat.
- **Team-Diversität als Bonus:** Wenn das Team bereits 3 verschiedene Typen enthält, sinkt der Wert eines vierten gleichartigen Typs.
- **Begründung im UI ausgeben:** "Feuer · deckt Eis-Schwäche und füllt 2 Lücken (Score 5)".

### 5. Accessibility & UX

- **VoiceOver:** `DefensiveCell` / `OffensiveCell` sollte als `.accessibilityElement(children: .combine)` behandelt werden, mit einem sprechenden Label ("Gestein, 4-fach Schaden, betrifft Glurak, Aerodactyl").
- **Tastatur-Navigation:** Zellen sind aktuell nicht fokussierbar. Bei Popover-Idee (Punkt 3) wäre Fokus-Support Pflicht.
- **Empty State:** Wenn das aktuelle Team leer ist (kein Session mit Team vorhanden), zeigt das Sheet momentan eine leere Übersicht. Besser: Hinweis "Füge erst ein Team in einer Session hinzu."
- **Loading-State:** Beim Öffnen des Sheets kann `PokemonDatabase.shared.find(byName:)` Millisekunden brauchen (Levenshtein-Fuzzy-Match über ~1000 Pokémon). Für größere Teams: einmalig vorberechnen.

## Priorisierung

**Must-have (nächste Iteration):**
- Konkrete Pokémon-Namen in Empfehlungen (§1, Variante 2)
- Typ-Punkt in Zellen-Header (§2, kleinster visueller Gewinn)
- Gewichtung schwerer Schwächen (§4, erste Bullet-Point)

**Should-have:**
- Gruppiertes Layout (§2)
- Lücken-Sektion durch Offensiv-Buckets ersetzen (§3, erste Idee)
- VoiceOver-Kombinationen (§5)

**Nice-to-have:**
- Sprite in Defensiv-Zellen (§2)
- Dual-Typ-Popover (§3)
- Score-Begründung im UI (§4)
- Spiel-Verfügbarkeits-Daten (§1, Variante 3)

## Offene Fragen

1. Wenn wir konkrete Pokémon vorschlagen — zeigen wir Basis-Stufe oder Final-Evolution? Wahrscheinlich Final, weil der Spieler den "finalen" Ziel-Vorschlag will.
2. Sollen bereits im Team vorhandene Pokémon-Evolutionslinien ausgeschlossen werden? (Keine Empfehlung von Evoli wenn Aquana im Team ist.)
3. Brauchen wir einen Toggle "Nur verfügbare Pokémon aus diesem Spiel anzeigen" — oder fühlt sich die Generation-Cap-Heuristik gut genug an?
4. Das UI wird mit mehr Dichte schnell überladen — besser zwei Tabs (Defensiv | Offensiv) im Sheet statt beider Grids untereinander?

## Wiederverwendete Komponenten

- `PokemonDatabase.shared.allPokemon()` — Kandidaten-Quelle
- `PokemonDatabase.shared.evolutionLine(for:)` — Evolutions-Dedup
- `PokemonTypeColor.color(for:)` — Typfarben
- `PokemonSpriteView` — Sprite-Anzeige in Empfehlungen
- Bestehende `MatchupCell` — als Basis für gruppiertes Layout erweiterbar
