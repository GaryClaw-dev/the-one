# The One

**Stationary Hero Survivor RPG with Class Branching**

Start as The Noob. Throw rocks. Level up. Choose your class. Evolve into a legend.

## Status
- **Engine:** Godot 4.6.1 (GDScript)
- **Platform Target:** Mobile web (portrait 720x1280), deployed to itch.io
- **Live URL:** https://jiddlebop.itch.io/the-one
- **Dev approach:** Claude Code as primary coder, Gary (AI assistant) as project manager/art director
- **Repo:** https://github.com/GaryClaw-dev/the-one
- **Current focus:** Sprite animation quality, enemy/hero visual polish

## Recent Changes (March 2026)

### Enemies — Full Ludo AI Sprite Overhaul
- All 11 enemies now have **Ludo AI-generated sprites** (static + animated)
- **16-frame idle/walk animations** for all enemies via Ludo's animate API
- **16-frame attack animations** for all enemies (separate sheets)
- Animation system uses `AnimatedSprite2D` with `AtlasTexture` frame slicing
- Auto-detects frame size from texture dimensions (horizontal strips)
- Enemies without sheets fall back to static `Sprite2D` (backward compatible)
- Enemy sprite scale doubled: normal 0.08, mini-boss 0.12, boss 0.16
- Shadow circles removed from all static sprites
- Horizontal flip disabled for animated sprites (3/4 perspective looks wrong mirrored)
- Sprites face toward hero instead of velocity direction

### Heroes — Archer Path Animations
- 7 archer-path heroes have Ludo AI sprites + idle/attack animations:
  - Noob, Slingshot, Archer, Crossbow, Ranger, Repeater, Spirit Archer
- `hero_base.gd` updated with AnimatedSprite2D support
- Attack animation triggers on projectile fire, returns to idle via `animation_finished` signal
- Heroes without sheets (Fighter, Wizard, etc.) still use static Sprite2D

### New Enemy Types (from upstream)
- Dark Mage (ranged, wave 10+)
- Necromancer (spawner boss, summons skeleton minions)
- Troll Warlord (charge boss)
- Object pooling system added
- Audio manager overhauled with intensity layering
- HUD milestone banners
- Fighter class + melee combat system

### 3D Prototype (Experimental — NOT active)
- `scenes/game_3d.tscn` — top-down 3D camera with capsule placeholders
- Full 3D enemy/hero scripts (enemy_3d_base.gd, hero_3d_base.gd, etc.)
- **Does NOT work on web export** (WebGL rendering issues)
- Kept in repo for future desktop builds — switch via `run/main_scene` in project.godot
- To activate: change main_scene to `"res://scenes/game_3d.tscn"`
- To revert: change back to `"res://scenes/game.tscn"`

### Art Pipeline
- **Static sprites:** Generated via Ludo AI (ludo.ai) — cel-shaded, top-down 3/4 perspective
- **Animations:** Ludo's `/assets/sprite/animate` API — 16 frames per sheet, 4x4 grid → normalized to horizontal strips
- **Normalization:** Python script crops, centers, and strips all frames into consistent horizontal PNGs
- All sprites downscaled for web (96px animation frames, 256px statics) to keep .pck under 15MB

### Known Issues
- Slingshot hero sprite looks like it has a gun (needs regeneration with better prompt)
- Archer hero faces backward in some frames
- Animation speeds are hardcoded (idle 6fps, attack 12fps) — don't sync with actual attack cooldowns
- `class_evolution.gd` has a parse error (`var class_name` — reserved keyword) — non-fatal, doesn't affect gameplay

## Core Gameplay

- Stationary hero auto-attacks nearest enemy
- Projectile system with pierce, crit, knockback, lifesteal, AoE
- Contact damage from enemies with attack cooldowns
- Health regen, armor, damage reduction, thorns, CDR all functional
- Endless waves with escalating difficulty
- Bosses every 10 waves drop powerful items (pick 1 of 3)
- Level-ups offer 3 abilities (1 guaranteed offensive, 1 defensive, 1 any)
- Kill streak tracking, colored damage numbers

## Classes & Evolution

Player starts as **The Noob** (throws rocks, weakest stats). At **level 5**, pick a starter class:

- **Slingshot** (Ranged) — fast projectiles, Steady Aim passive
- **Fighter** (Melee) — close combat, shield block
- **Wizard** (Magic) — AoE arcane bolts, Arcane Overflow passive

**Slingshot Evolution Tree:**
- Slingshot → **Archer** (Level 15) → **Gunner** (Level 25)
- Full tree: archer, repeater, ranger, crossbow, phantom, deadeye, tempest, etc.

## Enemies

| Enemy | Type | Behavior | Boss? |
|-------|------|----------|-------|
| Goblin | Rush | Fast, low HP | No |
| Skeleton | Rush | Slower, more HP | No |
| Bat | Erratic | Unpredictable movement | No |
| Fodder Warrior | Rush | Basic melee | No |
| Dark Mage | Ranged | Keeps distance, fires projectiles | No |
| War Drummer | Spawner | Drums + minion buffs | Mini-boss |
| Goblin Chief | Erratic | Aggressive boss | Boss |
| Bat Queen | Erratic | Flying boss | Boss |
| Necromancer | Spawner | Summons skeleton minions | Boss |
| Skeleton King | Charge | Heavy melee boss | Boss |
| Troll Warlord | Charge | Massive club boss | Boss |

## Audio

100% procedural — 17 SFX generated at runtime via waveform synthesis. No external audio files.

## Project Structure

```
the-one/
  GDD.md                    — Game Design Document
  ART_BIBLE.md              — Art style guide
  EXPORT_GUIDE.md           — Web export instructions
  README.md                 — This file
  gary/                     — Gary (AI assistant) workspace & notes
  godot/
    project.godot           — 720x1280 portrait, mobile renderer
    scenes/                 — 2D game + 3D prototype scenes
    scripts/
      core/                 — GameManager, GameEvents, AudioManager, ObjectPool
      heroes/               — HeroBase, Noob, Archer, Fighter, Wizard + 3D variants
      enemies/              — EnemyBase, EnemyData, WaveManager + 3D variants
      loot/                 — ItemData, AbilityData, ItemDatabase, XpOrb
      combat/               — Projectile, DamageNumberSpawner
      progression/          — PlayerProgression, RunStats
      ui/                   — HUD, LevelUpUI, GameOverUI, StartScreen, ClassSelectionUI
    resources/
      heroes/               — HeroData + Evolution .tres files
      enemies/              — 11 EnemyData .tres files
      abilities/            — 86 AbilityData .tres files
      items/                — 26 ItemData .tres files
    art/
      enemies/              — Ludo AI sprites + animation strips per enemy
      heroes/               — Ludo AI sprites + animation strips per hero
      items/                — Item icons
      effects/              — VFX sprites
      projectiles/          — Projectile sprites
```

## Autoloads
- **GameEvents** — Global signal bus
- **GameManager** — Game state machine, hero spawning
- **ItemDatabase** — All item/ability resources, weighted selection
- **AudioManager** — Procedural SFX engine

## Inspirations
- The Tower (mobile) — stationary hero concept
- Thronefall — clean, warm art style
- Vampire Survivors — wave survival
- Brotato — build archetypes

*Created: 2026-03-11*
*Last updated: 2026-03-24*
