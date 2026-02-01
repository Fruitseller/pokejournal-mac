#!/bin/bash
# Build and test script for PokéJournal

cd "$(dirname "$0")/../PokéJournal"

SCHEME=$(xcodebuild -list 2>/dev/null | grep -A 1 'Schemes:' | tail -1 | xargs)

case "$1" in
  build)
    xcodebuild build -project *.xcodeproj -scheme "$SCHEME" -destination "platform=macOS" 2>&1 | grep -E "(error:|warning:|BUILD|Compiling)" | tail -30
    ;;
  test)
    xcodebuild test -project *.xcodeproj -scheme "$SCHEME" -destination "platform=macOS" 2>&1 | grep -E "(Test Case|passed|failed|error:|BUILD|✓|✗)" | tail -50
    ;;
  clean)
    xcodebuild clean -project *.xcodeproj -scheme "$SCHEME" 2>&1 | tail -5
    ;;
  *)
    echo "Usage: $0 {build|test|clean}"
    exit 1
    ;;
esac
