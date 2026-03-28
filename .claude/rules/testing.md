# Testing Rules

Tests are a design tool, not a verification afterthought. Write them early,
learn from the friction, and let them shape your code.

## Guidelines

- **Write the test before the code.** If you can't write the test first, you
  likely don't understand the requirement well enough yet.
- **One behavior per test.** When a test fails, you should immediately know
  what broke without reading the implementation.
- **Tests must be fast, isolated, and deterministic.** Flaky tests erode trust.
  Slow tests don't get run. Either outcome degrades the value of the suite.
- **New behavior requires a new test** that would fail if the code were reverted.
- **Bug fixes require a regression test** that reproduces the original failure
  before you write the fix.
- **Difficulty testing is usually a design signal.** When code is hard to test,
  that's often feedback worth acting on. Restructure for testability when you
  can. When you genuinely can't — opaque platform APIs, hardware-dependent
  behavior, framework constraints outside your control — document what isn't
  covered and why, and push test boundaries as close to the untestable seam
  as possible.
- **Test behavior, not implementation.** Tests should survive a refactor. If
  renaming a private method breaks a test, the test is coupled to the wrong
  thing.
- **Delete tests that don't earn their keep.** Redundant, brittle, or
  chronically slow tests cost attention without providing confidence.
- **Keep tests readable.** Arrange, Act, Assert — with minimal ceremony. A
  good test reads like a specification. If you need extensive setup, extract
  it or reconsider the design.
- **Don't mock what you don't own.** Wrap third-party dependencies behind your
  own interface, then mock that. Tests shouldn't break when a library ships a
  patch.

## Project-Specific Rules

- **Don't test framework behavior.** SwiftData cascade deletes, `@Query`
  reactivity, and similar Apple-framework guarantees are not our responsibility.
  Focus tests on our own logic: parsing, data transforms, business rules.
- **SwiftData in-memory containers for tests.** Use
  `ModelConfiguration(isStoredInMemoryOnly: true)` so tests stay fast and
  isolated. Never hit the real persistent store.
- **Test runner commands:**
  - `./scripts/test.sh unit` — fast unit tests only (`PokeJournalTests`).
  - `./scripts/test.sh test` — full suite including UI tests.
  - `./scripts/test.sh build` — build-only check.
- **Fuzzy matching needs edge-case coverage.** Pokémon name matching
  (Levenshtein, German/English variants, regional forms) is a core domain
  concern — test boundary values and near-miss thresholds.
- **Parsing tests use fixture strings, not vault files.** Keep markdown parser
  tests self-contained with inline YAML/markdown snippets. No filesystem
  dependency.
