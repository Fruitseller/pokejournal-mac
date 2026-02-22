# PLAN: Timeline Redesign

## Ziel

Die bestehende Timeline überarbeiten:
- **Echter Zeitstrahl** mit proportionalen Abständen statt gleichmäßig verteilter Punkte
- **Visuelle Schnitte** bei langen Pausen (statt roter Labels)
- **Vereinfachung:** "Hat Team-Daten" und "Ist Legacy-Format" Unterscheidungen entfernen
- Sauber, minimal, verständlich ohne Legende

## Aktueller Zustand (zu ersetzen)

`Views/TimelineView.swift` (127 Zeilen):
- Gleichmäßig verteilte Kreise
- Farbcodierung: gefüllt = hat Team, hohl = kein Team, orange Rand = Legacy
- Farbbalken oben: grün/gelb/rot je nach Abstand
- "+Xd" Label bei langen Pausen

## Neues Design

### Zeitstrahl-Konzept

```
●───●──●─●───●──●                    ✂ 109d ✂                    ●──●───●─●
Dez 27  29  31  Jan 3  5                                          Jun 18  20  23  26
```

**Grundprinzip:**
- Horizontale Linie verbindet die Session-Punkte
- **Abstände proportional zur Zeit** (1 Tag = X Pixel, skalierbar)
- Alle Punkte gleich aussehen: einheitliche gefüllte Kreise in Accent-Farbe
- Bei Pausen über einem Schwellenwert (z.B. 30 Tage): **Schnitt im Zeitstrahl**

### Schnitt-Darstellung bei langen Pausen

```
●───●──●  ⟋⟋  89d  ⟋⟋  ●──●───●
```

- Wellenlinie oder Zickzack-Symbol (`⟋⟋` / `〰` / diagonale Linien)
- Dazwischen: Anzahl der Tage als dezentes Label
- Der Schnitt hat eine feste Breite (z.B. 60px), unabhängig von der tatsächlichen Pause
- So wird der Zeitstrahl nicht unnötig lang

### Proportionale Skalierung

**Innerhalb eines Segments** (zwischen zwei Schnitten):
- Minimaler Abstand: 20px (damit Punkte nicht überlappen)
- Maximaler Abstand: 60px (damit tägliches Spielen nicht zu weit wird)
- Skalierung: `pixelPerDay = clamp(baseScale, min: 20, max: 60)`
- Innerhalb eines Segments bleibt die Skalierung konsistent

**Schwellenwert für Schnitte:**
- Standard: 30 Tage
- Kann später konfigurierbar gemacht werden

### Interaktion

- **Hover über Punkt:** Tooltip mit Datum und ggf. Team-Zusammenfassung
- **Klick auf Punkt:** Navigiert zur Session / zeigt Detail-Popover
- **Horizontales Scrollen** bei vielen Sessions

### Datums-Labels

- Nicht jeder Punkt bekommt ein Label (zu eng)
- Labels nur an:
  - Erstem und letztem Punkt eines Segments
  - Regelmäßigen Intervallen (z.B. jede Woche, jeden Monat — je nach Zoom)
- Datum-Format: `"D. MMM"` (z.B. "27. Dez")

## Implementierungsschritte

### 1. TimelineView komplett neu schreiben
- **Datei:** `Views/TimelineView.swift` (überschreiben)
- Alte Implementierung ersetzen

**Neue Struktur:**

```swift
struct TimelineView: View {
    let game: Game

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    TimelineSegmentView(segment: segment)

                    if segment.hasGapAfter {
                        TimelineGapView(days: segment.gapDays)
                    }
                }
            }
        }
    }
}
```

### 2. Datenaufbereitung

```swift
struct TimelineSegment {
    let sessions: [(date: Date, isOld: Bool)]  // isOld nur intern, nicht visuell
    let gapDaysAfter: Int?  // nil = letztes Segment
}
```

**Logik:**
1. Alle Sessions (Session + OldSession) nach Datum sortieren
2. Abstände berechnen
3. Bei Abstand > 30 Tage: neues Segment beginnen
4. Segmente mit ihren Sessions zurückgeben

### 3. Segment-Rendering

- `Canvas` oder `Path` für die Verbindungslinie
- `Circle()` für Session-Punkte
- Proportionale Positionierung basierend auf Tagesabständen
- Datums-Labels unterhalb

### 4. Gap-Rendering (Schnitt)

- Zickzack-`Path` (diagonale Linien)
- Tages-Label dazwischen
- Feste Breite (~60px)
- Dezente Farbe (`secondary`)

### 5. Tests
- **Datei:** `Tests/TimelineDataTests.swift` (neu oder bestehende erweitern)
- Segment-Aufteilung bei verschiedenen Gap-Schwellenwerten
- Proportionale Abstände korrekt berechnet
- Edge Cases: einzelne Session, keine Gaps, nur Gaps

## Technische Hinweise

- Kein Swift Charts nötig — `HStack` + `Canvas`/`Path` reicht
- Performance: Selbst 100+ Sessions sind trivial für SwiftUI
- `TimelineView` existiert bereits und wird komplett ersetzt — kein neuer Tab nötig
- Die bestehenden Tests in `TimelineViewTests` (falls vorhanden) müssen angepasst werden
