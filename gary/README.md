# Gary's Workspace — The One

This folder contains notes, instructions, and context for Gary (AI assistant) to pick up where we left off.

---

## Quick Resume

**Last session:** 2026-03-24
**What we were doing:** Fixing sprite animation quality for enemies and heroes
**Current state:** 2D game is live on itch.io, all enemies + 7 heroes have Ludo AI sprites and animations
**What still needs fixing:**
- Slingshot hero sprite looks like a gun (regenerate with better Ludo prompt)
- Archer hero faces backward in some frames
- Animation speed doesn't sync with actual attack cooldowns
- 3D prototype exists but doesn't render on web (WebGL limitation)

---

## Deploying to itch.io

### Export
```bash
cd ~/Desktop/the-one/godot
rm -rf .godot
/Users/garyclaw/Desktop/Godot.app/Contents/MacOS/Godot --headless --export-release "Web" export/web/index.html
```

### Push to itch.io
```bash
butler push ~/Desktop/the-one/godot/export/web jiddlebop/the-one:html5
```

### itch.io Settings
- **URL:** https://jiddlebop.itch.io/the-one
- **Game ID:** 4369538
- **Username:** JiddleBop
- **Butler CLI:** `/Users/garyclaw/.local/bin/butler`
- **Butler creds:** `~/Library/Application Support/itch/butler_creds`
- **API key:** stored in butler creds (don't need to pass manually)
- **After pushing:** Make sure "This file will be played in the browser" is checked on the html5 upload
- **Viewport:** 720 x 1280
- **Mobile friendly:** Yes

### Important Export Notes
- Use `--headless --export-release` (not --export-debug)
- Always `rm -rf .godot` before export to avoid stale cache issues
- The `class_evolution.gd` parse error is non-fatal — export still succeeds
- Keep .pck under ~50MB or itch.io will reject it
- Current .pck is ~13MB after sprite downscaling

---

## Ludo AI (Sprite Generation)

### Account
- **API Key:** `db9cc990-2e4f-4105-ad9c-a833aa22cb34`
- **Pricing:** 0.5 credits per static image, 5 credits per animation, 3 credits per 3D model
- **Web UI:** https://app.ludo.ai
- **API Docs:** https://api.ludo.ai/api-documentation/swagger.json

### Generating a Static Sprite
```bash
curl -s -X POST "https://api.ludo.ai/api/assets/image" \
  -H "Authorization: ApiKey db9cc990-2e4f-4105-ad9c-a833aa22cb34" \
  -H "Content-Type: application/json" \
  -d '{
    "image_type": "sprite",
    "prompt": "Top-down 3/4 view, [CHARACTER DESCRIPTION], chibi proportions, flat cel-shaded, thick dark outline, game sprite",
    "art_style": "Cel-Shaded",
    "perspective": "Top-Down",
    "n": 1,
    "augment_prompt": false
  }'
```
Returns: `[{"url": "https://storage.googleapis.com/..."}]`

### Animating a Sprite
```bash
# Convert static sprite to base64 first
B64=$(python3 -c "import base64; data=open('sprite.png','rb').read(); print('data:image/png;base64,'+base64.b64encode(data).decode())")

curl -s -X POST "https://api.ludo.ai/api/assets/sprite/animate" \
  -H "Authorization: ApiKey db9cc990-2e4f-4105-ad9c-a833aa22cb34" \
  -H "Content-Type: application/json" \
  -d "{
    \"motion_prompt\": \"walking forward\",
    \"initial_image\": \"$B64\",
    \"loop\": true,
    \"frames\": 16,
    \"frame_size\": 128,
    \"image_type\": \"sprite\",
    \"model\": \"standard\",
    \"duration\": 1.5,
    \"augment_prompt\": true
  }"
```
Returns: `{"spritesheet_url": "...", "video_url": "...", "num_frames": 16}`

The spritesheet is a 4x4 grid (for 16 frames). Must be normalized into a horizontal strip.

### Normalizing Sprite Sheets (4x4 grid → horizontal strip)
```python
from PIL import Image

sheet = Image.open("spritesheet.webp").convert("RGBA")
sw, sh = sheet.size
fw, fh = sw // 4, sh // 4

frames = []
for r in range(4):
    for c in range(4):
        frames.append(sheet.crop((c * fw, r * fh, (c+1) * fw, (r+1) * fh)))

# Find max content size, center in uniform cells
bboxes = [f.getbbox() or (0, 0, fw, fh) for f in frames]
max_dim = max(max(b[2]-b[0], b[3]-b[1]) for b in bboxes)
cell = max_dim + int(max_dim * 0.1) * 2

normalized = []
for frame, bbox in zip(frames, bboxes):
    content = frame.crop(bbox)
    nf = Image.new("RGBA", (cell, cell), (0, 0, 0, 0))
    nf.paste(content, ((cell - content.width) // 2, (cell - content.height) // 2))
    normalized.append(nf)

strip = Image.new("RGBA", (cell * 16, cell), (0, 0, 0, 0))
for i, f in enumerate(normalized):
    strip.paste(f, (i * cell, 0))
strip.save("enemy_anim.png")
```

### Ludo Tips
- Set `augment_prompt: false` for static sprites if you want exact control
- Set `augment_prompt: true` for animations (helps with motion quality)
- `loop: true` for idle/walk, `loop: false` for attack
- `duration: 1.5-2.0` for idle, `duration: 1.2` for attack
- The bat animation worked best — simple motions (flying, flapping) produce better results than complex ones
- Use Ludo's **Change Pose** feature in the web UI to set correct facing BEFORE animating

---

## Sprite Animation System (How It Works)

### Enemy Sprites
In `scripts/enemies/enemy_base.gd`:
- `_use_animated` flag checks if `data.sprite_sheet_idle != ""`
- If animated: hides Sprite2D, shows AnimatedSprite2D
- Creates `SpriteFrames` with idle/walk/attack animations
- Uses `AtlasTexture` to slice horizontal strips into individual frames
- Auto-detects frame size: `texture_width / frame_count` for width, `texture_height` for height
- Scale factor: `(768 / frame_width) * base_scale` to match static sprite visual size

### Enemy Resource Files (.tres)
Each enemy .tres needs these fields for animation:
```
sprite_path = "res://art/enemies/goblin/goblin_ludo.png"
sprite_sheet_idle = "res://art/enemies/goblin/goblin_anim.png"
sprite_sheet_walk = "res://art/enemies/goblin/goblin_anim.png"
sprite_sheet_attack = "res://art/enemies/goblin/goblin_attack_anim.png"
sheet_frame_count = 16
sheet_frame_size = Vector2(160, 160)
```

### Hero Sprites
In `scripts/heroes/hero_base.gd`:
- Similar system but detects animation sheets by checking file paths
- Maps hero name → folder name for art lookup
- Idle loops at 6fps, attack plays once at 12fps

### Animation Speed Sync (TODO)
Currently hardcoded FPS values. Should be calculated from `attack_cooldown`:
```
attack_fps = frame_count / attack_cooldown
```

---

## Game Direction & Vision

### Art Style (from ART_BIBLE.md)
- **Thronefall-inspired:** Clean, warm, low-detail-but-beautiful
- **Key principles:** Simple silhouettes, max readability, warm muted backgrounds, saturated characters
- **NOT:** Pixel art, retro, busy/noisy, dark/gritty
- **YES:** Clean vectors, soft shadows, warm & inviting, "cozy chaos"
- **Color palette:** Earth tones background, saturated heroes, desaturated enemies

### Where We're Headed
1. Fix sprite quality (correct facing, matching weapons, animation sync)
2. Eventually: real 3D models for desktop builds (3D prototype code exists)
3. More enemy variety + wave mechanics
4. Full class evolution trees (Fighter path, Wizard path)
5. Polish: screen shake, particles, juice

### What Works Well
- Core gameplay loop is solid and fun
- Wave progression and difficulty scaling
- Ability/item system with 86 abilities and 26 items
- Procedural audio (no external files needed)
- Ludo AI pipeline for rapid sprite generation

### What Needs Work
- Sprite animation quality (biggest pain point)
- Animation speed sync with gameplay
- More hero classes need animation support
- 3D rendering on web (currently broken)

---

## Key File Locations

| What | Where |
|------|-------|
| Godot project | `~/Desktop/the-one/godot/` |
| Game scene (2D) | `godot/scenes/game.tscn` |
| Game scene (3D) | `godot/scenes/game_3d.tscn` |
| Enemy base script | `godot/scripts/enemies/enemy_base.gd` |
| Hero base script | `godot/scripts/heroes/hero_base.gd` |
| Wave manager | `godot/scripts/enemies/wave_manager.gd` |
| Art bible | `~/Desktop/the-one/ART_BIBLE.md` |
| Enemy sprites | `godot/art/enemies/<name>/` |
| Hero sprites | `godot/art/heroes/<name>/` |
| Enemy data | `godot/resources/enemies/<name>.tres` |
| Hero data | `godot/resources/heroes/<name>_data.tres` |
| Export presets | `godot/export_presets.cfg` |
| Godot binary | `/Users/garyclaw/Desktop/Godot.app/Contents/MacOS/Godot` |
| Export templates | `~/Library/Application Support/Godot/export_templates/4.6.1.stable/` |

---

## GitHub

- **Repo:** https://github.com/GaryClaw-dev/the-one
- **Don't push export/ or .godot/ folders** (in .gitignore)
- **Don't push until JD verifies changes work on itch**
- Large sprite PNGs are fine in git (they're small after downscaling)

---

*Last updated: 2026-03-24 by Gary 🐾*
