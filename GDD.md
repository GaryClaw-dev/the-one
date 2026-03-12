# THE ONE — Game Design Document
**Working Title:** The One
**Genre:** Progression RPG / Stationary Hero Defense with Class Branching
**Platform:** Mobile (portrait) — web export for playtesting
**Engine:** Godot 4.6 (GDScript)
**Art Style:** Thronefall-inspired — clean 2D with warm lighting
**Inspirations:** The Tower (mobile), Thronefall, Vampire Survivors, class-branching RPGs

---

## 1. CORE CONCEPT

A stationary hero stands at the center of the screen. Waves of enemies swarm from all directions. The hero auto-attacks. Everyone starts as **The Noob** — weak, throwing rocks. As you level up, you choose a class, then evolve that class through branching paths into something powerful. Bosses drop powerful items. The fantasy: start as nothing, become a legend.

**One sentence:** "Start weak. Choose your path. Become a legend."

---

## 2. GAMEPLAY LOOP

### Micro Loop (moment-to-moment)
1. Hero auto-attacks nearest enemies
2. Enemies swarm toward hero from screen edges
3. Kills drop XP orbs (no item drops from mobs)
4. XP fills a bar → level up → choose 1 of 3 abilities (class-specific pool)
5. Every 10 waves, a boss spawns — defeating it gives a powerful item (pick 1 of 3)
6. At level 5, choose your class — this defines your progression path
7. Repeat with escalating difficulty

### Macro Loop (run-to-run)
1. Start as The Noob
2. Survive as many waves as possible
3. Earn persistent currency (Soul Shards)
4. Unlock starting perks, cosmetics
5. Climb difficulty tiers

### Session Length
- Target: 10-20 minute runs

---

## 3. CLASS SYSTEM

Everyone starts as **The Noob**. At level 5, choose one of 3 starter classes. Each class evolves through branching choices as you progress.

### The Noob (Levels 1-4)
- **Auto-Attack:** Throws rocks (single slow projectile)
- **Passive:** None
- **Stats:** 80 HP, 5 ATK, 0.6 ATK SPD, 3% crit, 1.5x crit mult
- **Purpose:** Tutorial phase — feel weak, crave the class upgrade

### Class Selection at Level 5

#### Slingshot (Ranged Path)
- **Auto-Attack:** Faster projectiles, slight accuracy improvement
- **Passive:** "Steady Aim" — standing still increases accuracy
- **Evolution Path:** Slingshot → Archer → Crossbow → Gunner
- **Playstyle:** Precision damage, speed scaling, crit builds

#### Fighter (Melee Path)
- **Auto-Attack:** Short-range slash (wider hit area, slower)
- **Passive:** "Battle Hardened" — gain armor per wave survived
- **Evolution Path:** Fighter → Knight → Berserker → Warlord
- **Playstyle:** Tanky sustain, thorns, lifesteal, area control

#### Apprentice (Magic Path)
- **Auto-Attack:** Arcane bolt (medium speed, slight AoE)
- **Passive:** "Arcane Overflow" — consecutive casts increase damage
- **Evolution Path:** Apprentice → Mage → Warlock → Archmage
- **Playstyle:** AoE powerhouse, scaling damage, cooldown reduction

### Class Evolution
- Each evolution happens at specific level thresholds
- Player chooses between 2 branching options at each evolution point
- Each branch has unique abilities and playstyle modifications
- Example: Archer can branch into Crossbow (slow, heavy hits) or Ranger (fast, multi-shot)

---

## 4. ENEMIES

### Basic Enemies (Waves 1-10)
| Enemy | Behavior | Threat |
|-------|----------|--------|
| **Goblin** | Fast, low HP, rushes hero | Swarm pressure |
| **Skeleton** | Medium speed, tanky | Sustained damage |
| **Bat** | Erratic movement, hard to hit | Distraction |

### Mid-Tier (Waves 10-25)
| Enemy | Behavior | Threat |
|-------|----------|--------|
| **Orc Brute** | Tanky, charges in a line | Burst damage |
| **Necromancer** | Spawns skeletons, stays at range | Must prioritize |
| **Ghost** | Phases through damage briefly | Requires timing |

### Bosses (Every 10 waves)
- Unique models, attack patterns, and item drops
- Defeating a boss presents 3 powerful items — pick 1
- Boss difficulty scales with wave number
- Examples: Dragon (circle strafes + fire breath), Giant (ground pound AoE), Lich (resurrects corpses)

### Enemy Scaling
- Wave count increases enemy count, speed, HP
- New enemy types introduced every 3 waves
- Elite modifiers appear on regular enemies later (armored, fast, splitting)

---

## 5. ITEM SYSTEM

### Boss Drops Only
Items **only** drop from bosses (every 10 waves). No random mob drops. This makes each item feel significant and each boss fight meaningful.

### Boss Reward Flow
1. Defeat boss
2. Reward screen appears with 3 items
3. Player picks 1
4. Items provide stat modifiers (passive, always-on effects)

### Item Rarity Tiers
| Rarity | Color | Frequency |
|--------|-------|-----------|
| Common | Grey `#B0B0B0` | Early bosses |
| Uncommon | Green `#4CBB4C` | Wave 10-20 bosses |
| Rare | Blue `#4D9DE0` | Wave 20-30 bosses |
| Epic | Purple `#9B59B6` | Wave 30-40 bosses |
| Legendary | Gold `#E8C547` | Wave 40+ bosses |

### Item Categories
| Category | Examples |
|----------|---------|
| **Offensive** | Whetstone, Scope Lens, Berserker's Gauntlet |
| **Defensive** | Iron Plate, Chain Links, Fortified Bastion |
| **Utility** | Lucky Coin, Chrono Gear, Repeating Mechanism |
| **Cursed** | Powerful but with drawbacks (double damage but half HP) |

---

## 6. ABILITY SYSTEM

### Level-Up Choices
- Every level: pick 1 of 3 random abilities
- Abilities drawn from class-specific pool (after Chunk 2)
- Abilities can be leveled up (max 3-5 levels each)
- Higher levels = stronger effects

### Ability Pool (Current — all classes)
14 abilities covering attack, defense, speed, crit, healing, AoE, and utility stats.

### Future: Class-Specific Pools
Each class gets its own curated ability pool that synergizes with its playstyle. Shared "universal" abilities available to all classes.

---

## 7. PROGRESSION (Meta / Between Runs)

### Persistent Currency: "Soul Shards"
- Earned per run based on waves survived, enemies killed, level reached
- Spend on:
  - Starting perks (begin run with a random item, +10% XP, etc.)
  - Cosmetics (hero skins, death effects)

### Difficulty Tiers
- After beating Wave 50, unlock "Nightmare" mode
- Nightmare → Inferno → Apocalypse
- Each tier: enemies scale harder

---

## 8. ART & AUDIO DIRECTION

### Visual Style (Thronefall-Inspired)
- 2D top-down with soft, warm color palette
- Clean silhouettes — enemies and heroes instantly readable
- Minimal UI — health bar, XP bar, wave counter
- Particle effects for attacks, kills, level-ups
- Screen shake + flash on big moments
- Low detail models, high detail effects

### Audio
- Procedural SFX engine (no external audio files)
- Satisfying hit/kill sounds
- Level-up chords, kill streak sweeps
- Boss spawn rumble
- Item rarity fanfares (escalating)

---

## 9. TECHNICAL ARCHITECTURE (Godot)

### Project Structure
```
godot/
├── scenes/          — .tscn files (game, heroes, enemies, projectiles, orbs)
├── scripts/
│   ├── core/        — GameManager, GameEvents, StatSystem, AudioManager
│   ├── heroes/      — HeroBase, Noob, (future class scripts)
│   ├── enemies/     — EnemyBase, EnemyData, WaveManager
│   ├── loot/        — ItemData, AbilityData, ItemDatabase, XpOrb
│   ├── combat/      — Projectile, DamageNumbers
│   ├── progression/ — PlayerProgression, RunStats
│   └── ui/          — HUD, LevelUpUI, GameOverUI, StartScreen
├── resources/       — .tres data files (heroes, enemies, abilities, items)
└── art/             — Sprites organized by type
```

### Key Systems
1. **StatSystem** — Formula: `(base + flat) * (1 + sum_percent_add) * product(1 + percent_mult)`
2. **GameEvents** — Global signal bus for decoupled communication
3. **WaveManager** — Wave spawning, boss spawning every 10 waves
4. **ItemDatabase** — Item/ability registry, rarity lookups

---

## 10. MVP SCOPE (Current — Chunk 1)

- [x] The Noob hero (throws rocks)
- [x] 3 basic enemy types
- [x] Wave spawner (increasing difficulty)
- [x] Auto-attack system
- [x] XP + level-up with 3 random choices
- [x] 14 abilities
- [x] Bosses every 10 waves
- [x] No random mob drops (XP only)
- [x] Tap-to-start screen
- [x] Game over screen with stats
- [x] Procedural SFX
- [ ] Class selection at level 5 (Chunk 2)
- [ ] Boss reward screen (Chunk 4)

---

*Document created: 2026-03-11*
*Updated: 2026-03-12 — Pivoted from roguelike gamba to progression RPG with class branching*
*Author: Gary Claw + JD*
