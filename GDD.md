# THE ONE — Game Design Document
**Working Title:** The One  
**Genre:** Roguelike Survivor / Stationary Hero Defense  
**Platform:** PC (Steam) — mobile-friendly design  
**Engine:** Unity (2D, URP)  
**Art Style:** Thronefall-inspired — clean, low-poly 2D with warm lighting, soft shadows  
**Inspirations:** The Tower (mobile), Megabonk, Vampire Survivors, Thronefall

---

## 1. CORE CONCEPT

A stationary hero stands at the center of the screen. Waves of enemies swarm from all directions. The hero auto-attacks. As enemies die, they drop XP and loot — triggering roguelike item/ability selections with RNG gacha mechanics. The dopamine loop: kill → drop → gamble → power spike → bigger kills.

**One sentence:** "Stand your ground, roll the dice, become a god."

---

## 2. GAMEPLAY LOOP

### Micro Loop (moment-to-moment)
1. Hero auto-attacks nearest enemies
2. Enemies swarm toward hero from screen edges
3. Kills drop XP orbs + random loot rolls
4. XP fills a bar → level up → choose 1 of 3 random upgrades (roguelike)
5. Loot drops trigger "GAMBA ROLLS" — slot-machine style reveals for items/abilities
6. Repeat with escalating difficulty

### Macro Loop (run-to-run)
1. Pick a hero
2. Survive as many waves as possible
3. Earn persistent currency (Bones? Slime? Gold?)
4. Unlock new heroes, starting perks, cosmetics
5. Climb difficulty tiers / prestige system

### Session Length
- Target: 10-20 minute runs
- Designed for "one more run" addiction

---

## 3. HEROES

Each hero has a unique auto-attack, passive, and synergy with certain item pools.

### 🏹 ARCHER
- **Auto-Attack:** Rapid arrows in aimed direction (nearest enemy)
- **Passive:** "Eagle Eye" — crit chance scales with kill streak
- **Playstyle:** High DPS, glass cannon, rewards precision scaling
- **Synergizes with:** Speed items, crit items, multishot
- **Power Fantasy:** Screen fills with arrows, everything dies before reaching you

### 🔮 WIZARD
- **Auto-Attack:** Arcane bolts (slower, AoE splash)
- **Passive:** "Arcane Overflow" — spell damage increases per consecutive cast
- **Playstyle:** AoE powerhouse, slow start but massive scaling
- **Synergizes with:** AoE items, elemental effects, cooldown reduction
- **Power Fantasy:** Entire screen explodes in chain reactions

### 🦴 CANNIBAL
- **Auto-Attack:** Bone throw (medium range, piercing)
- **Passive:** "Consume" — eating enemy corpses heals + temporary stat boost
- **Playstyle:** Sustain tank, risk/reward (corpses disappear after a few seconds)
- **Synergizes with:** Lifesteal, thorns, corpse explosion, bone armor
- **Power Fantasy:** Unkillable monster surrounded by bones and gore

### 🟢 SLIME
- **Auto-Attack:** Slime spit (slow, applies DoT puddles on ground)
- **Passive:** "Mitosis" — at certain HP thresholds, spawn mini-slimes that fight
- **Playstyle:** Area denial, summon-heavy, grows literally bigger with power
- **Synergizes with:** Summon items, slow effects, poison/acid, size scaling
- **Power Fantasy:** The slime becomes enormous, mini-slimes everywhere, the floor is acid

---

## 4. ENEMIES

### Basic Enemies (Waves 1-10)
| Enemy | Behavior | Threat |
|-------|----------|--------|
| **Goblin** | Fast, low HP, rushes hero | Swarm pressure |
| **Skeleton** | Medium speed, throws bones at range | Chip damage |
| **Bat** | Erratic movement, hard to hit | Distraction |
| **Mushroom** | Slow, explodes on death near hero | Positioning |

### Mid-Tier (Waves 10-25)
| Enemy | Behavior | Threat |
|-------|----------|--------|
| **Orc Brute** | Tanky, charges in a line | Burst damage |
| **Necromancer** | Spawns skeletons, stays at range | Must prioritize |
| **Ghost** | Phases through damage briefly | Requires timing |
| **Slime King** | Splits into smaller slimes on death | Exponential swarm |

### Elite/Boss (Every 5-10 waves)
- **Mini-bosses:** Buffed versions of regular enemies with unique modifiers
- **Bosses (every 10 waves):** Unique models, attack patterns, loot pinatas
- Boss examples: Dragon (circle strafes + fire breath), Giant (ground pound AoE), Lich (resurrects all on-screen corpses)

### Enemy Scaling
- Wave count increases enemy count, speed, HP
- New enemy types introduced gradually
- Elite modifiers appear on regular enemies later (armored, fast, splitting, vampiric)

---

## 5. THE GAMBA SYSTEM (Core Innovation)

This is what makes the game addictive. Two parallel upgrade systems:

### 5A. Level-Up Choices (Roguelike Standard)
- Every level: pick 1 of 3 random abilities/upgrades
- Rarity tiers: Common → Uncommon → Rare → Epic → Legendary
- Higher waves = better rarity chances
- Abilities can stack/evolve (2 specific abilities combine into an evolved form)

### 5B. LOOT DROPS — "The Gamba" (Megabonk-inspired)
When enemies die, they have a chance to drop a **Loot Orb**. Picking it up triggers a **slot-machine style roll**:

```
┌─────────────────────────────┐
│   🎰  GAMBA ROLL  🎰        │
│                             │
│   [⚔️]  [🛡️]  [💀]         │
│                             │
│   ► EPIC BONE ARMOR ◄      │
│   +40% DEF, Thorns dmg     │
│                             │
│   [KEEP]     [REROLL 🎲]   │
└─────────────────────────────┘
```

- **Visual:** Slots spin with item icons, land on result
- **Rarity animation:** Screen flashes gold for legendaries, shake for epics
- **Reroll mechanic:** Spend currency to reroll (limited per run, purchasable)
- **Pity system:** Guaranteed epic+ every X rolls without one
- **Dopamine design:** Sound effects escalate, visual effects intensify with rarity

### 5C. Item Categories
| Category | Examples |
|----------|---------|
| **Weapons** | Flaming arrows, bone scythe, arcane orb |
| **Armor** | Bone plate, slime shield, ethereal cloak |
| **Accessories** | Lucky charm (+luck), speed boots, magnet ring |
| **Consumables** | Mega bomb, full heal, time freeze |
| **Cursed Items** | Powerful but with drawbacks (double damage but half HP) |

### 5D. Evolution System
Certain item combos create evolved items:
- Fire Arrow + Multishot = **Flame Barrage** (auto rain of fire arrows)
- Bone Armor + Lifesteal = **Vampiric Exoskeleton** (heal on being hit)
- Slime Puddle + Poison = **Toxic Wasteland** (permanent ground DoT)
- Crit Chance + Kill Streak = **Executioner** (guaranteed crits after 10-kill streak)

---

## 6. PROGRESSION (Meta / Between Runs)

### Persistent Currency: "Soul Shards"
- Earned per run based on waves survived, enemies killed, items found
- Spend on:
  - **Hero unlocks** (start with Archer, unlock others)
  - **Starting perks** (begin run with a random Common item, +10% XP, etc.)
  - **Cosmetics** (hero skins, death effects, gamba machine skins)
  - **Bestiary entries** (lore unlocks)

### Prestige / Difficulty Tiers
- After beating Wave 50, unlock "Nightmare" mode
- Nightmare → Inferno → Apocalypse
- Each tier: enemies scale harder, but loot tables improve
- Leaderboard per tier

---

## 7. ART & AUDIO DIRECTION

### Visual Style (Thronefall-Inspired)
- **2D top-down** with soft, warm color palette
- Clean silhouettes — enemies and heroes instantly readable
- Minimal UI — health bar, XP bar, wave counter, item slots
- Particle effects for attacks, kills, loot drops
- Screen shake + flash on big moments (crits, legendaries, boss kills)
- **Low detail models, high detail effects** — the chaos IS the visual appeal

### Color Language
- Hero attacks: bright, saturated (blue magic, green slime, white arrows)
- Enemy attacks: red/orange/dark
- Loot: color-coded by rarity (white → green → blue → purple → gold)
- Background: muted earth tones (forest, dungeon, wasteland per biome)

### Audio
- Satisfying hit sounds (crunch, splat, thwack)
- Escalating music per wave tier
- ASMR-level satisfying gamba roll sounds
- Legendary drop: distinct "DING" that becomes Pavlovian
- Each hero has unique attack SFX

---

## 8. TECHNICAL ARCHITECTURE (Unity)

### Project Structure
```
TheOne/
├── Assets/
│   ├── Scripts/
│   │   ├── Core/           # GameManager, WaveManager, InputManager
│   │   ├── Heroes/         # HeroBase, Archer, Wizard, Cannibal, Slime
│   │   ├── Enemies/        # EnemyBase, spawning, AI
│   │   ├── Combat/         # DamageSystem, Projectiles, AoE
│   │   ├── Loot/           # LootTable, GambaSystem, ItemDatabase
│   │   ├── UI/             # HUD, GambaUI, LevelUpUI, MenuUI
│   │   └── Progression/    # SaveSystem, CurrencyManager, Unlocks
│   ├── Prefabs/
│   │   ├── Heroes/
│   │   ├── Enemies/
│   │   ├── Projectiles/
│   │   ├── Effects/
│   │   └── UI/
│   ├── Art/
│   │   ├── Sprites/
│   │   ├── Animations/
│   │   ├── VFX/
│   │   └── Tilesets/
│   ├── Audio/
│   │   ├── SFX/
│   │   └── Music/
│   ├── ScriptableObjects/
│   │   ├── Items/
│   │   ├── Enemies/
│   │   ├── Heroes/
│   │   └── Waves/
│   └── Scenes/
│       ├── MainMenu.unity
│       ├── Game.unity
│       └── GameOver.unity
├── Packages/
└── ProjectSettings/
```

### Key Systems Priority (Build Order)
1. **Core:** Hero movement (stationary), camera, game loop
2. **Combat:** Auto-attack, projectiles, damage numbers
3. **Enemies:** Spawner, basic AI (move toward hero), wave system
4. **Loot:** XP orbs, level-up choice UI
5. **Gamba:** Loot drop rolls, slot machine UI, item application
6. **Items:** Item database, stat modifiers, evolution combos
7. **Heroes:** Implement all 4 hero kits
8. **Progression:** Save/load, soul shards, unlocks
9. **Polish:** VFX, SFX, screen shake, juice
10. **Content:** More enemies, items, biomes, bosses

### Performance Targets
- Handle 200+ enemies on screen smoothly
- Object pooling for all spawned entities
- ECS or DOTS for enemy AI if needed at scale

---

## 9. MVP SCOPE (Phase 1)

**Goal:** Playable prototype with core loop working

- [ ] 1 hero (Archer)
- [ ] 3 basic enemy types
- [ ] Wave spawner (increasing difficulty)
- [ ] Auto-attack system
- [ ] XP + level-up with 3 random choices
- [ ] 5-10 upgradeable abilities
- [ ] Basic gamba loot drop (visual roll)
- [ ] 10 items across rarities
- [ ] Game over screen with stats
- [ ] Placeholder art (shapes/sprites)
- [ ] Basic SFX

**Estimated dev time:** 2-4 weeks with Claude Code assisting

---

## 10. MONETIZATION (Future — Optional)

If we go mobile/F2P:
- Cosmetic skins only (no P2W)
- Ad-supported rerolls (watch ad = free reroll)
- Battle pass with cosmetic tiers
- Premium currency for cosmetic shop only

If Steam/premium:
- One-time purchase ($4.99-$9.99)
- No microtransactions
- DLC hero packs / biome expansions

---

*Document created: 2026-03-11*  
*Author: Gary Claw 🐾 + JD*
