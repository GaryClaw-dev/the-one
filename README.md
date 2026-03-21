# The One

**Stationary Hero Survivor RPG with Class Branching**

Start as The Noob. Throw rocks. Level up. Choose your class. Evolve into a legend.

## Status
- **Engine:** Godot 4.6 (GDScript)
- **Platform Target:** Mobile (portrait 720x1280), testing on Mac
- **Dev approach:** Claude Code as primary coder, Gary as project manager/art director
- **Current focus:** Slingshot class tree polish + base game loop

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
- **Wizard** (Magic) — AoE arcane bolts, Arcane Overflow passive
- Fighter & Apprentice — planned, currently locked

**Slingshot Evolution Tree:**
- Slingshot → **Archer** (Level 15) — precision marksman, aimed shot + wind guidance
  - Archer → **Gunner** (Level 25) — overwhelming firepower, bullet hell + explosive rounds

The Archer script handles all 16 slingshot-family archetypes (archer, repeater, ranger, crossbow, phantom, deadeye, tempest, etc.) — evolution data for further branches is planned.

## Abilities

**86 total abilities** across two systems:

- **45 generic stat-stick abilities** — shared pool, all classes
  - Common (19): single stat, modest value
  - Uncommon (5): single stat, ~2x Common value
  - Rare (15): two stats
  - Epic (2): three stats (Last Stand, Fortify)
  - Legendary (0): none yet in generic pool
- **41 class-specific abilities** (ArcherAbilityData) — proc-based mechanics
  - Archer (25): bleed, chain lightning, frostbite, ricochet, rain of arrows, etc.
  - Ranger (4): poison cloud, pack leader, camouflage, nature's wrath
  - Crossbow (3): bolt barrage, mechanical overload, grappling hook
  - Lumberjack (4), Thrower (3), Catapult (2): branch-specific

Rarity weighting: Common weight fixed at 100, higher rarities scale with luck stat.

## Enemies & Waves

**5 regular enemies + 1 special + 3 bosses:**

| Enemy | Type | Notes |
|-------|------|-------|
| Goblin | Rush | Fast, low HP |
| Skeleton | Rush/Tank | Slower, more HP |
| Bat | Erratic | Fast, unpredictable movement |
| Fodder Warrior | Elite | Tanky variant |
| War Drummer | Special | Dembow-rhythm attacks, spawns wave 15+ |
| Goblin Chief | Boss | Every 10 waves |
| Skeleton King | Boss | Every 10 waves |
| Bat Queen | Boss | Every 10 waves |

- Endless waves, no cap
- New enemy types introduced every 3 waves
- Boss waves halve regular enemy count
- Difficulty scales via spawn interval (0.5s → 0.08s), HP, speed, count
- 1.5s break between waves

## Items

**26 items** across 5 rarity tiers — only drop from bosses (pick 1 of 3). All have custom 32x32 sprite icons. No random mob drops.

## Audio

100% procedural — no external audio files. 17 SFX generated at runtime via waveform synthesis:
- Combat: hit, crit, kill
- Pickups: xp
- Progression: level_up, streak
- Items: rarity-specific fanfares (common through legendary)
- Waves: wave_start, wave_complete, boss
- War Drummer: drum_kick, drum_snare, drum_hat
- Game state: game_start, game_over, click

## Project Structure

```
the-one/
  GDD.md                    — Game Design Document
  ART_BIBLE.md              — Art style guide
  README.md                 — This file
  godot/
    project.godot           — Godot project config (720x1280 portrait)
    scenes/                 — 12 .tscn files (game, heroes, enemies, UI, effects)
    scripts/
      core/                 — GameManager, GameEvents, Rarity, StatSystem, AudioManager
      heroes/               — HeroBase, Noob, Archer, Wizard, ClassEvolution, HeroData
      enemies/              — EnemyBase, EnemyData, WaveManager, WarDrummer
      loot/                 — ItemData, AbilityData, ItemDatabase, XpOrb
      combat/               — Projectile, DamageNumberSpawner
      progression/          — PlayerProgression, RunStats
      ui/                   — HUD, LevelUpUI, GameOverUI, StartScreen, ClassSelectionUI, EvolutionUI
    resources/
      heroes/               — 3 HeroData + 2 Evolution .tres files
      enemies/              — 8 EnemyData .tres files (5 regular + 3 bosses)
      abilities/            — 86 AbilityData .tres files (45 generic + 41 class-specific)
      items/                — 26 ItemData .tres files
    art/                    — Sprites organized by type (heroes, enemies, items, UI)
```

## Autoloads
- **GameEvents** — Global signal bus (all systems communicate through signals)
- **GameManager** — Game state machine, pause depth, hero spawning
- **ItemDatabase** — Loads all item/ability resources, rarity lookups, weighted selection
- **AudioManager** — Procedural SFX engine, auto-connected to all game events

## Inspirations
- The Tower (mobile) — stationary hero concept
- Thronefall — clean, warm art style
- Vampire Survivors — wave survival
- Brotato — build archetypes
- Class branching RPGs — progression identity

*Created: 2026-03-11*
*Last updated: 2026-03-20*
