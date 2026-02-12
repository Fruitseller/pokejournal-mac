---
name: fix-bug
description: Bug systematisch fixen mit TDD — Problem verstehen, Failing Tests schreiben, Fix implementieren, Root Cause erklären und Prävention vorschlagen.
argument-hint: "[Bug-Beschreibung oder Issue-Referenz]"
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, AskUserQuestion, Task, EnterPlanMode
---

# Bug Fix Skill

Fixe den Bug beschrieben in: $ARGUMENTS

Folge diesen Phasen strikt und in der angegebenen Reihenfolge. Überspringe KEINE Phase und greife NICHT vor.

---

## Phase 1: Problem verstehen

**Ziel:** Das Problem vollständig verstehen, bevor Code angefasst wird.

1. Lies die Bug-Beschreibung sorgfältig. Identifiziere:
   - Was ist das **erwartete** Verhalten?
   - Was ist das **tatsächliche** Verhalten?
   - Welcher Teil der Codebase ist wahrscheinlich betroffen?

2. Erkunde den relevanten Code. Nutze Grep, Glob und Read, um die betroffenen Dateien zu finden und die aktuelle Implementierung zu verstehen.

3. **Falls irgendetwas unklar oder mehrdeutig ist**, stelle dem User klärende Fragen mit AskUserQuestion. NICHT raten oder annehmen. Beispiele:
   - Steps to reproduce
   - Welcher Input das Problem verursacht
   - Ob der Bug eine Regression ist oder schon immer existierte
   - Edge Cases und erwartetes Verhalten bei Grenzfällen

4. Sobald das Problem verstanden ist, schreibe eine kurze Zusammenfassung (2-3 Sätze):
   - Die Root Cause (oder deine Hypothese)
   - Welche Datei(en) und Funktion(en) betroffen sind

---

## Phase 2: Failing Tests schreiben (Red)

**Ziel:** Den Bug mit einem Test beweisen, bevor er gefixt wird.

1. Finde die richtige Test-Datei. Prüfe existierende Test Targets und Konventionen im Projekt.

2. Schreibe einen oder mehrere fokussierte Test Cases, die:
   - Den Bug exakt reproduzieren
   - Das **erwartete** (korrekte) Verhalten asserten
   - Aktuell FAILEN, weil der Bug noch besteht

3. Führe die Tests aus, um zu bestätigen, dass sie failen:
   ```bash
   ./scripts/test.sh unit
   ```

4. **Wichtig: Tests NICHT erzwingen.** Überspringe diese Phase komplett, wenn:
   - Der Bug rein visuell/UI ist und nicht sinnvoll unit-testbar ist
   - Testen das Mocken von Framework Internals erfordern würde (SwiftData, SwiftUI Rendering)
   - Der Test trivial tautologisch wäre und keinen Mehrwert bringt
   - Der Bug in Konfiguration, Build Settings oder Asset Management liegt

   Falls übersprungen, erkläre kurz warum ein Test hier nicht praktikabel ist.

---

## Phase 3: Fix implementieren (Green)

**Ziel:** Einen minimalen, sauberen Fix schreiben, der den Bug behebt.

1. Fixe die Root Cause — nicht das Symptom. Vermeide Workarounds oder Pflaster-Lösungen.

2. Halte die Änderung so klein wie möglich. Ändere nur was nötig ist.

3. Baue das Projekt, um die Kompilierung zu verifizieren:
   ```bash
   ./scripts/test.sh build
   ```

4. Führe alle Tests aus, um den Fix UND die Stabilität des restlichen Codes zu verifizieren:
   ```bash
   ./scripts/test.sh unit
   ```

5. Iteriere bis: Clean Build + alle Tests grün (inklusive der neuen aus Phase 2).

---

## Phase 4: Erklären und Prävention

**Ziel:** Dem User verständlich machen, was schiefgelaufen ist und wie es in Zukunft vermieden werden kann.

Präsentiere eine strukturierte Zusammenfassung:

### Bug Report

**Was war der Bug?**
Ein-Satz-Beschreibung des fehlerhaften Verhaltens.

**Root Cause:**
Technische Erklärung, warum der Bug aufgetreten ist. Referenziere spezifische Zeilen/Funktionen.

**Fix:**
Was wurde geändert und warum. Referenziere die konkreten Edits.

**Tests hinzugefügt:**
Liste der neuen Test Cases (oder Erklärung warum keine hinzugefügt wurden).

**Prävention:**
Wie ähnliche Bugs in Zukunft vermieden werden können. Das kann beinhalten:
- Coding Patterns, die bevorzugt oder vermieden werden sollten
- Guardrails oder Assertions, die hinzugefügt werden könnten
- Architekturelle Verbesserungen

**Vorgeschlagene Dokumentations-Updates:**
Falls zutreffend, schlage konkrete Ergänzungen für CLAUDE.md oder README.md vor, die helfen würden, diese Klasse von Bugs zu verhindern. Schlage nur Updates vor, wenn sie tatsächlich nützlich sind — nicht um des Vorschlagens willen. Präsentiere die Vorschläge als konkreten Text, der hinzugefügt werden könnte, und wo.
