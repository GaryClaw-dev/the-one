# Web Export Guide for itch.io

## Claude: Run This Command

Export + zip in one command:

```bash
cd /Users/garyclaw/Desktop/the-one/godot && /Users/garyclaw/Desktop/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" export/web/index.html && cd export && rm -f TheOne_web.zip && zip -r TheOne_web.zip web/ -x "web/.DS_Store" "web/*.import"
```

Output: `godot/export/TheOne_web.zip`

### What this does

1. Runs Godot headless export using the "Web" preset (already configured in `export_presets.cfg`)
2. Outputs to `godot/export/web/` (index.html + .js + .wasm + .pck + icons)
3. Removes any old zip, then zips the web folder (excluding .DS_Store and .import files)

### Key details

- **Godot binary:** `/Users/garyclaw/Desktop/Godot.app/Contents/MacOS/Godot`
- **Godot version:** 4.6.1
- **Export templates:** `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`
- **Export preset:** "Web" (defined in `godot/export_presets.cfg`, threads OFF, VRAM compression OFF)
- **Output path:** `godot/export/web/index.html` (set in the preset)
- **Zip output:** `godot/export/TheOne_web.zip` (~109MB)

## Upload to itch.io

1. Go to the game's itch.io dashboard -> **Edit game**
2. Under **Uploads**, delete the old zip
3. Upload `TheOne_web.zip`
4. Check **This file will be played in the browser**
5. Click **Save**

### itch.io Page Settings

- **Kind of project:** HTML
- **Viewport:** 720 x 1280
- **Mobile friendly:** Yes
- **Automatically start on page load:** Yes
- **SharedArrayBuffer:** Enable (not required since threads are off)

## Prerequisites (one-time setup)

- Godot 4.6.1 installed at `/Users/garyclaw/Desktop/Godot.app`
- Export templates installed (Editor -> Manage Export Templates -> Download and Install)

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Export templates not found" | Install templates via Editor -> Manage Export Templates |
| Export fails with "configuration errors" | Check that VRAM compression is OFF in export preset |
| Game loads but freezes (no enemies) | `item_database.gd` and `wave_manager.gd` must use hardcoded paths, not `DirAccess` |
| Black screen | Ensure the "Web" preset was used, not another platform |
| Audio doesn't play on iOS | Expected — tap-to-start screen triggers audio unlock |
