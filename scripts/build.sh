#!/bin/bash
# Build and test script for PokéJournal

cd "$(dirname "$0")/../PokeJournal"

SCHEME=$(xcodebuild -list 2>/dev/null | grep -A 1 'Schemes:' | tail -1 | xargs)

case "$1" in
  build)
    xcodebuild build -project *.xcodeproj -scheme "$SCHEME" -destination "platform=macOS" 2>&1 | grep -E "(error:|warning:|BUILD|Compiling)" | tail -30
    ;;
  test)
    xcodebuild test -project *.xcodeproj -scheme "$SCHEME" -destination "platform=macOS" 2>&1 | grep -E "(Test Case|passed|failed|error:|BUILD|✓|✗)" | tail -50
    ;;
  archive)
    ARCHIVE_PATH="$TMPDIR/PokeJournal.xcarchive"
    EXPORT_DIR="${2:-$HOME/Applications}"
    mkdir -p "$EXPORT_DIR"

    echo "Archiving (Release)..."
    xcodebuild archive \
      -project *.xcodeproj \
      -scheme "$SCHEME" \
      -destination "platform=macOS" \
      -archivePath "$ARCHIVE_PATH" \
      2>&1 | grep -E "(error:|warning:|ARCHIVE|Compiling)" | tail -30

    if [ ! -d "$ARCHIVE_PATH" ]; then
      echo "Archive failed."
      exit 1
    fi

    echo "Exporting to $EXPORT_DIR..."
    APP_NAME=$(ls "$ARCHIVE_PATH/Products/Applications/" | head -1)
    rm -rf "$EXPORT_DIR/$APP_NAME"
    cp -R "$ARCHIVE_PATH/Products/Applications/$APP_NAME" "$EXPORT_DIR/$APP_NAME"
    rm -rf "$ARCHIVE_PATH"

    echo "Done: $EXPORT_DIR/$APP_NAME"
    ;;
  clean)
    xcodebuild clean -project *.xcodeproj -scheme "$SCHEME" 2>&1 | tail -5
    ;;
  *)
    echo "Usage: $0 {build|test|clean|archive [output-dir]}"
    exit 1
    ;;
esac
