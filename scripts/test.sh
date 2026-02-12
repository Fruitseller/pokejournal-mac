#!/bin/bash
# Build and test script for PokéJournal
# Usage: ./scripts/test.sh [build|test|clean]

cd "$(dirname "$0")/.."

PROJECT=$(ls -d Pok*Journal/*.xcodeproj 2>/dev/null | head -1)
SCHEME=$(xcodebuild -project "$PROJECT" -list 2>/dev/null | grep -A1 'Schemes:' | tail -1 | xargs)

case "${1:-test}" in
    build)
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" build
        ;;
    test)
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" test
        ;;
    unit)
        # Only run unit tests, skip UI tests
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" test -only-testing:PokeJournalTests
        ;;
    *)
        echo "Usage: $0 [build|test|unit]"
        exit 1
        ;;
esac
