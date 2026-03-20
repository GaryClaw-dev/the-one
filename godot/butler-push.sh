#!/bin/bash
set -e

PROJECT_DIR="/Users/garyclaw/Desktop/the-one/godot"
EXPORT_DIR="$PROJECT_DIR/export/web"
ZIP_FILE="$PROJECT_DIR/export/TheOne_web.zip"
GODOT="/Users/garyclaw/Desktop/Godot.app/Contents/MacOS/Godot"
ITCH_TARGET="jiddlebop/the-one:html5"

echo "==> Exporting Godot project to web..."
"$GODOT" --headless --path "$PROJECT_DIR" --export-release "Web" "$EXPORT_DIR/index.html"

echo "==> Zipping web export..."
cd "$EXPORT_DIR"
zip -r -9 "$ZIP_FILE" .

echo "==> Pushing to itch.io..."
butler push "$ZIP_FILE" "$ITCH_TARGET"

echo "==> Done! Game pushed to itch.io."
