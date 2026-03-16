# Needed Assets — Archer Evolution Tree Redesign

## Evolution Tree Overview

```
Slingshot (Lv5)
├── Archer (Lv15) ─── Precision Path
│   ├── Ranger (Lv25) ─── Nature/Poison/Wolf
│   │   ├── Beastlord (Lv35) ─── Wolf Army
│   │   └── Phantom (Lv35) ─── Stealth Assassin
│   └── Windwalker (Lv25) ─── Wind/Homing
│       ├── Tempest (Lv35) ─── Tornado Crowd Control
│       └── Spirit Archer (Lv35) ─── Ghost Arrows/Hawks
│
└── Repeater (Lv15) ─── Speed Path
    ├── Crossbow (Lv25) ─── Mechanical/Gadgets
    │   ├── Gunslinger (Lv35) ─── Bullet Hell
    │   └── Siege Master (Lv35) ─── Explosive AoE
    └── Stormcaller (Lv25) ─── Lightning/Elemental
        ├── Thunderlord (Lv35) ─── Chain Lightning
        └── Demon Hunter (Lv35) ─── Cursed/Lifesteal
```

---

## Hero Sprites — `art/heroes/{class}/{class}.png`

Top-down 2D sprite, Thronefall style, transparent background, same scale as existing heroes.

| Class | Tier | Path | Description |
|-------|------|------|-------------|
| **repeater** | 3 | `art/heroes/repeater/repeater.png` | Fast-looking archer with a smaller rapid-fire bow or hand crossbow. Orange-red tint. Aggressive stance, lighter armor than Archer. |
| **windwalker** | 4 | `art/heroes/windwalker/windwalker.png` | Elegant archer with flowing robes/scarf blowing in wind. Light sky blue tint. Wind wisps around them. Longbow with curved design. |
| **stormcaller** | 4 | `art/heroes/stormcaller/stormcaller.png` | Archer crackling with electricity. Yellow/electric blue tint. Lightning arcs around body. Medium armor with storm motifs. |
| **beastlord** | 5 | `art/heroes/beastlord/beastlord.png` | Fur-clad hunter with animal pelts/fang necklace. Deep brown/amber tint. Wild, feral look. Bow made from antlers or bone. |
| **phantom** | 5 | `art/heroes/phantom/phantom.png` | Hooded assassin in dark cloak, partially transparent/shadowy. Deep purple/black tint. Sleek dark bow. One glowing eye visible under hood. |
| **tempest** | 5 | `art/heroes/tempest/tempest.png` | Storm mage-archer surrounded by swirling wind. Teal/cyan tint. Robes torn by constant wind. Hair/cape flowing dramatically. Bow with tornado engravings. |
| **spirit_archer** | 5 | `art/heroes/spirit_archer/spirit_archer.png` | Ethereal/ghostly archer, slightly translucent with white glow. White/pale blue tint. Spirit energy flowing from bow. Hawk perched on shoulder or circling. |
| **gunslinger** | 5 | `art/heroes/gunslinger/gunslinger.png` | Dual-wielding crossbow/hand-cannon user. Brass/gold tint. Western/steampunk vibe. Bandolier of bolts. Confident gunslinger pose. |
| **siege_master** | 5 | `art/heroes/siege_master/siege_master.png` | Heavy-armored archer with massive siege crossbow/launcher on back. Dark orange/ember tint. Bulky, intimidating. Smoke/embers around them. |
| **thunderlord** | 5 | `art/heroes/thunderlord/thunderlord.png` | Lightning god-warrior with electric aura. Bright yellow/white tint. Armor with lightning bolt patterns. Crackling energy bow. Raijin-inspired. |
| **demon_hunter** | 5 | `art/heroes/demon_hunter/demon_hunter.png` | Dark warrior with cursed/demonic gear. Dark red/crimson tint. Glowing red eyes. Dark energy seeping from weapon. Jagged armor with demonic motifs. |

---

## Portraits — `art/portraits/{class}_portrait.png`

Larger character art for evolution choice UI. Same style as existing portraits.

| Class | Path |
|-------|------|
| **repeater** | `art/portraits/repeater_portrait.png` |
| **windwalker** | `art/portraits/windwalker_portrait.png` |
| **stormcaller** | `art/portraits/stormcaller_portrait.png` |
| **beastlord** | `art/portraits/beastlord_portrait.png` |
| **phantom** | `art/portraits/phantom_portrait.png` |
| **tempest** | `art/portraits/tempest_portrait.png` |
| **spirit_archer** | `art/portraits/spirit_archer_portrait.png` |
| **gunslinger** | `art/portraits/gunslinger_portrait.png` |
| **siege_master** | `art/portraits/siege_master_portrait.png` |
| **thunderlord** | `art/portraits/thunderlord_portrait.png` |
| **demon_hunter** | `art/portraits/demon_hunter_portrait.png` |

---

## Projectile Sprites — `art/projectiles/{type}/{type}.png`

Small projectile sprite, transparent background, roughly same size as existing projectiles.

| Projectile | Path | Used By | Description |
|------------|------|---------|-------------|
| **wind_arrow** | `art/projectiles/wind_arrow/wind_arrow.png` | Windwalker, Tempest, Spirit Archer | Arrow with wind trails/wisps streaming behind it. Light blue/white. |
| **lightning_arrow** | `art/projectiles/lightning_arrow/lightning_arrow.png` | Stormcaller, Thunderlord | Arrow crackling with electricity. Yellow/electric blue glow. Lightning arcs off the shaft. |
| **dark_arrow** | `art/projectiles/dark_arrow/dark_arrow.png` | Demon Hunter | Arrow wreathed in dark/purple energy. Sinister, cursed look. Red/crimson core with dark aura. |
| **siege_bolt** | `art/projectiles/siege_bolt/siege_bolt.png` | Siege Master | Large, heavy explosive bolt. Dark orange with ember trail. Bigger than normal projectiles (~1.5x). |
| **ghost_arrow** | `art/projectiles/ghost_arrow/ghost_arrow.png` | Spirit Archer | Semi-transparent ethereal arrow. White/pale glow. Ghostly trail. Should look like it passes through things. |

---

## VFX / Effects — `art/effects/{effect}/{effect}.png`

Effect sprites for abilities. Transparent background.

| Effect | Path | Used By | Description |
|--------|------|---------|-------------|
| **lightning_bolt** | `art/effects/lightning_bolt/lightning_bolt.png` | Stormcaller, Thunderlord | Lightning bolt striking from sky. Bright yellow/white. Dramatic, jagged. For the sky bolt ability. |
| **chain_lightning** | `art/effects/chain_lightning/chain_lightning.png` | Stormcaller, Thunderlord | Electric arc connecting two points. Yellow/blue crackling line. For the chain effect between enemies. |
| **tornado_vortex** | `art/effects/tornado_vortex/tornado_vortex.png` | Tempest | Swirling tornado/whirlwind. Teal/gray. Circular, meant to sit on the ground as a pull zone. ~60-80px diameter. |
| **spirit_hawk** | `art/effects/spirit_hawk/spirit_hawk.png` | Spirit Archer | Ghostly/ethereal hawk diving downward. White/pale blue, semi-transparent. Aggressive diving pose. |
| **stealth_smoke** | `art/effects/stealth_smoke/stealth_smoke.png` | Phantom | Puff of dark purple/black smoke. For vanish/appear transitions. Wispy, fading. |
| **curse_aura** | `art/effects/curse_aura/curse_aura.png` | Demon Hunter | Dark red/purple aura circle. Sinister glowing ring with runes/symbols. Applied around cursed enemies. |
| **predator_mark** | `art/effects/predator_mark/predator_mark.png` | Beastlord | Glowing amber/green target indicator. Wolf paw print or fang symbol. Placed above marked enemies. |
| **bullet_split** | `art/effects/bullet_split/bullet_split.png` | Gunslinger | Small burst/spark effect for when projectiles split into two. Brass/gold sparks. |
| **wind_trail** | `art/effects/wind_trail/wind_trail.png` | Windwalker | Flowing wind streak/trail. Light blue, wispy. Follows behind homing arrows. |

---

## Companion Sprites — `art/companion/`

| Companion | Path | Description |
|-----------|------|-------------|
| **spirit_hawk** | `art/companion/spirit_hawk.png` | Ethereal hawk companion. White/pale blue, semi-transparent. Top-down view, wings spread. Same scale approach as wolf. |
| **dire_wolf** | `art/companion/dire_wolf.png` | Larger, fiercer wolf variant for Beastlord. Can be a recolored/scaled wolf — darker fur, glowing amber eyes, bigger. |

---

## Priority Order

### P0 — Needed to tell classes apart visually
1. All 11 hero sprites (players see these during gameplay)
2. All 11 portraits (players see these during evolution choices)

### P1 — Needed for combat to feel right
3. 5 projectile sprites (each path should shoot distinct projectiles)
4. lightning_bolt + chain_lightning effects (Stormcaller/Thunderlord core mechanic)
5. tornado_vortex effect (Tempest core mechanic)
6. spirit_hawk companion + effect (Spirit Archer core mechanic)

### P2 — Polish
7. stealth_smoke, curse_aura, predator_mark, bullet_split, wind_trail
8. dire_wolf companion variant

---

## Existing Assets (no work needed)

| Asset | Path |
|-------|------|
| Slingshot hero | `art/heroes/slingshot/slingshot.png` |
| Archer hero | `art/heroes/archer/archer.png` |
| Ranger hero | `art/heroes/ranger/ranger.png` |
| Crossbow hero | `art/heroes/crossbow/crossbow.png` |
| Archer portrait | `art/portraits/archer_portrait.png` |
| Ranger portrait | `art/portraits/ranger_portrait.png` |
| Crossbow portrait | `art/portraits/crossbow_portrait.png` |
| Rock projectile | `art/projectiles/rock/rock.png` |
| Poison arrow projectile | `art/projectiles/poison_arrow/poison_arrow.png` |
| Crossbow bolt projectile | `art/projectiles/crossbow_bolt/crossbow_bolt.png` |
| Wolf companion | `art/companion/wolf.png` |
| Wolf slash effect | `art/effects/wolf_slash/wolf_slash.png` |
| Poison cloud effect | `art/effects/poison_cloud/poison_cloud.png` |
| Fire zone effect | `art/effects/fire_zone/fire_zone.png` |
| Bolt barrage effect | `art/effects/bolt_barrage/bolt_barrage.png` |
