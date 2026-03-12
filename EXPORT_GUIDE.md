# Export & Upload Guide

How to export The One for web and upload to itch.io for playtesting.

## Prerequisites

- Godot 4.6.1 installed
- Export templates installed at `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`
- itch.io account with the game page created

### Installing Export Templates (one-time setup)

If Godot says "Export templates not found":

1. Open Godot
2. Go to **Editor → Manage Export Templates**
3. Click **Download and Install**
4. Wait for the ~1.2GB download to finish

Or manually: download `Godot_v4.6.1-stable_export_templates.tpz` from https://github.com/godotengine/godot/releases/tag/4.6.1-stable, rename to `.zip`, extract, and move the `templates/` folder to `~/Library/Application Support/Godot/export_templates/4.6.1.stable/`.

## Export Steps

### Option A: From Godot Editor (Easiest)

1. Open the project in Godot (`godot/project.godot`)
2. Go to **Project → Export**
3. Select the **Web** preset (already configured)
4. Click **Export Project**
5. Choose `export/web/index.html` as the output path
6. Uncheck **Export with Debug** for a smaller build
7. Click **Save**

### Option B: From Terminal

```bash
cd /Users/garyclaw/Desktop/the-one/godot
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" export/web/index.html
```

## Zip for Upload

After exporting, zip the web folder:

```bash
cd /Users/garyclaw/Desktop/the-one/godot/export
zip -r TheOne_web.zip web/
```

The zip will be in `godot/export/TheOne_web.zip`.

## Upload to itch.io

1. Go to your game's itch.io dashboard → **Edit game**
2. Under **Uploads**, delete the old zip
3. Click **Upload files** and select `TheOne_web.zip`
4. Check **This file will be played in the browser**
5. Scroll down and click **Save**
6. Visit your game page and test it loads

## itch.io Game Page Settings

These settings work best for our portrait mobile game:

- **Kind of project:** HTML
- **Embed options:**
  - Viewport dimensions: **720 x 1280**
  - Check **Mobile friendly**
  - Check **Automatically start on page load**
  - SharedArrayBuffer: **Enable** (if available, not required since we export without threads)
- **Frame options:** optional, but a dark background color looks good

## Sharing with Playtesters

Send them the itch.io URL. On iOS they open it in Safari. Works best in fullscreen — tap the share button → **Add to Home Screen** for an app-like experience.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Export templates not found" | Install templates (see Prerequisites above) |
| Export fails with "configuration errors" | Open export preset, make sure VRAM compression is OFF for both desktop and mobile |
| Game loads but freezes (no enemies) | Check that `item_database.gd` and `wave_manager.gd` use hardcoded paths, not `DirAccess` |
| Black screen | Make sure you exported the **Web** preset, not a different platform |
| Slow/choppy on mobile Safari | Normal for debug builds — export without debug for better performance |
| Audio doesn't play on iOS | iOS requires a user interaction before audio works — our tap-to-start screen handles this |

## Quick Reference (Copy-Paste)

Full export + zip in one go from terminal:

```bash
cd /Users/garyclaw/Desktop/the-one/godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" export/web/index.html && cd export && zip -r TheOne_web.zip web/
```
