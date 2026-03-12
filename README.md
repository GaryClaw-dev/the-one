# The One

**Progression RPG with Class Branching**

Start as The Noob. Throw rocks. Level up. Choose your class. Evolve into a legend.

## Status
- **Phase:** Chunk 1 Complete (The Noob playable, old systems stripped)
- **Engine:** Godot 4.6 (GDScript)
- **Platform Target:** Mobile (portrait 720x1280), testing on Mac
- **Dev approach:** Claude Code as primary coder, Gary as project manager/art director

## New Direction

The game has pivoted from a roguelike gamba loot game to a **progression RPG with class branching**:

- Player always starts as **The Noob** (throws rocks, weakest stats)
- At **level 5**, pick one of 3 starter classes: **Slingshot**, **Fighter**, or **Apprentice**
- Classes **evolve with branching choices** (e.g. Slingshot → Archer → Crossbow → Gunner)
- **Bosses every 10 waves** drop powerful items (pick 1 of 3)
- **No random mob drops** — enemies only drop XP
- Level-ups grant abilities from a class-specific pool

## Chunk Roadmap

| Chunk | Scope | Status |
|-------|-------|--------|
| **1. Foundation** | Noob hero, remove gamba/mob drops, boss every 10 waves, tap-to-start | Done |
| **2. Class System** | Class selection UI at level 5, Slingshot class + ability pool | Next |
| **3. Ranged Progression** | Slingshot → Archer → Crossbow → Gunner evolutions | Planned |
| **4. Boss Items** | Boss reward screen, 5-10 boss-exclusive items for ranged path | Planned |
| **5. Fighter Class** | Melee class + ability pool + evolutions | Planned |
| **6. Apprentice Class** | Magic class + ability pool + evolutions | Planned |

## What's Working

### Core Gameplay
- Stationary hero auto-attacks nearest enemy
- Projectile system with pierce, crit, knockback, lifesteal
- Contact damage from enemies with attack cooldowns
- Health regen, armor, damage reduction all functional
- Kill streak tracking

### The Noob (Starting Hero)
- Throws rocks (single projectile)
- 80 HP, 5 ATK, 0.6 ATK SPD, 3% crit, 1.5x crit mult
- Weakest stats in the game — designed to feel like you need a class upgrade
- Grey circle placeholder sprite

### Enemies & Waves
- 3 enemy types: Goblin (rush), Skeleton (rush/tank), Bat (erratic/fast)
- Wave system with escalating difficulty (enemy count, spawn speed, HP/damage scaling)
- Bosses every 10 waves
- New enemy types introduced every 3 waves
- 1.5s break between waves
- Up to 60 enemies per wave

### Level-Up System
- 14 abilities with max 3-5 levels each
- 3 random choices on level-up (from full pool — class-specific pools coming in Chunk 2)
- Fast early XP curve

### Item System (Dormant)
- 26 items across 5 rarity tiers exist in the database
- All 26 items have custom sprite icons
- Items will be used for boss rewards (Chunk 4)
- No items drop during gameplay currently

### Sound Effects
- Procedural SFX engine (no external audio files needed)
- 17 unique sounds: combat, pickups, progression, waves, game state, UI

### UI (Portrait Mobile Layout)
- Tap-to-start screen with pulsing text, fades into gameplay
- Health bar with color coding (green/yellow/red)
- XP bar, level display, wave counter, kill counter
- Kill streak indicator, wave break timer
- Level-up screen with big tappable buttons
- Game over screen with run stats

### Art & Visuals
- Thronefall-inspired clean 2D style
- Real sprite art for Goblin, Skeleton, Bat
- All 26 item sprites integrated
- Camera shake and screen flash effects
- Enemy damage flash, death fade animation
- Tiled ground texture background

## Project Structure

```
the-one/
  GDD.md                    — Game Design Document
  ART_BIBLE.md              — Art style guide
  README.md                 — This file
  EXPORT_GUIDE.md           — Web export + itch.io upload guide
  Gary graphics help/
    ART_BIBLE.md            — Art reference for Gary
    ITEM_ART_DESCRIPTIONS.md — 32x32 sprite descriptions for all 26 items
    REMAINING_SPRITES_NEEDED.md — Sprites still needed
  godot/
    project.godot           — Godot project config (720x1280 portrait)
    scenes/                 — .tscn scene files
    scripts/
      core/                 — GameManager, GameEvents, Rarity, StatSystem, AudioManager
      heroes/               — HeroBase, Noob (Archer/Wizard still exist but unused)
      enemies/              — EnemyBase, EnemyData, WaveManager
      loot/                 — ItemData, AbilityData, ItemDatabase, XpOrb
      combat/               — Projectile, DamageNumberSpawner
      progression/          — PlayerProgression, RunStats
      ui/                   — HUD, LevelUpUI, GameOverUI, StartScreen
    resources/
      heroes/               — HeroData .tres files (noob, archer, wizard)
      enemies/              — EnemyData .tres files (goblin, skeleton, bat)
      abilities/            — 14 AbilityData .tres files
      items/                — 26 ItemData .tres files (dormant until boss rewards)
    art/                    — In-game sprites organized by type
```

## Autoloads
- **GameEvents** — Global signal bus (all systems communicate through signals)
- **GameManager** — Game state machine, pause depth, hero spawning
- **ItemDatabase** — Loads all item/ability resources, rarity lookups, random selection
- **AudioManager** — Procedural SFX engine, auto-connected to all game events

## Inspirations
- The Tower (mobile) — stationary hero concept
- Thronefall — clean, warm art style
- Vampire Survivors — wave survival
- Brotato — build archetypes
- Class branching RPGs — progression identity

*Created: 2026-03-11*
*Last updated: 2026-03-12*
