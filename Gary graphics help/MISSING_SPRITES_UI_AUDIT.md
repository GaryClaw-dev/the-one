# Missing Sprites & UI Consistency Audit

## MISSING PORTRAIT (Blocking)

| Asset | Status | Notes |
|-------|--------|-------|
| `slingshot_portrait.png` | **MISSING** | Slingshot is the first class players pick at Lv 5. Currently uses `archer_portrait.png` as placeholder. Needs its own portrait matching the slingshot hero sprite style (Thronefall top-down, warm palette). |

The slingshot hero sprite (`art/heroes/slingshot/slingshot.png`) already exists — only the portrait is missing.

---

## UNUSED / ORPHAN PORTRAITS (Can Remove)

These portraits exist but are NOT referenced anywhere in code. They belong to removed class concepts:

| File | Old Concept |
|------|-------------|
| `catapult_portrait.png` | Catapult class (removed) |
| `lumberjack_portrait.png` | Lumberjack class (removed) |
| `thrower_portrait.png` | Thrower class (removed) |

---

## UNUSED HERO SPRITE FOLDERS (Can Remove)

These hero sprite directories exist but have no code references:

| Folder | Old Concept |
|--------|-------------|
| `art/heroes/cannibal/` | Cannibal class (removed) |
| `art/heroes/catapult/` | Catapult class (removed) |
| `art/heroes/lumberjack/` | Lumberjack class (removed) |
| `art/heroes/thrower/` | Thrower class (removed) |
| `art/heroes/wizard/` | Wizard (replaced by Apprentice scene) |
| `art/heroes/slime/` | Slime (unused starter variant) |

---

## ACTIVE PORTRAITS (All Present)

All evolution classes have matching portraits:

| Class | Portrait | Tier |
|-------|----------|------|
| Noob | noob_portrait.png | Starter |
| Fighter | fighter_portrait.png | Starter (Locked) |
| Apprentice | apprentice_portrait.png | Starter (Locked) |
| **Slingshot** | **MISSING** | **Starter** |
| Archer | archer_portrait.png | Tier 2 |
| Repeater | repeater_portrait.png | Tier 2 |
| Ranger | ranger_portrait.png | Tier 3 |
| Windwalker | windwalker_portrait.png | Tier 3 |
| Crossbow | crossbow_portrait.png | Tier 3 |
| Stormcaller | stormcaller_portrait.png | Tier 3 |
| Beastlord | beastlord_portrait.png | Tier 4 |
| Phantom | phantom_portrait.png | Tier 4 |
| Tempest | tempest_portrait.png | Tier 4 |
| Spirit Archer | spirit_archer_portrait.png | Tier 4 |
| Gunslinger | gunslinger_portrait.png | Tier 4 |
| Siege Master | siege_master_portrait.png | Tier 4 |
| Thunderlord | thunderlord_portrait.png | Tier 4 |
| Demon Hunter | demon_hunter_portrait.png | Tier 4 |

---

## ACTIVE HERO SPRITES (All Present)

All 15 evolution classes have hero sprites in `art/heroes/{name}/{name}.png`.

---

## ACTIVE PROJECTILE SPRITES (All Present)

| Projectile | File |
|------------|------|
| Rock | `art/projectiles/rock/rock.png` |
| Poison Arrow | `art/projectiles/poison_arrow/poison_arrow.png` |
| Crossbow Bolt | `art/projectiles/crossbow_bolt/crossbow_bolt.png` |
| Wind Arrow | `art/projectiles/wind_arrow/wind_arrow.png` |
| Lightning Arrow | `art/projectiles/lightning_arrow/lightning_arrow.png` |
| Dark Arrow | `art/projectiles/dark_arrow/dark_arrow.png` |
| Siege Bolt | `art/projectiles/siege_bolt/siege_bolt.png` |
| Ghost Arrow | `art/projectiles/ghost_arrow/ghost_arrow.png` |

---

## ACTIVE EFFECT SPRITES (All Present)

| Effect | File |
|--------|------|
| Lightning Bolt | `art/effects/lightning_bolt/lightning_bolt.png` |
| Chain Lightning | `art/effects/chain_lightning/chain_lightning.png` |
| Spirit Hawk | `art/effects/spirit_hawk/spirit_hawk.png` |
| Stealth Smoke | `art/effects/stealth_smoke/stealth_smoke.png` |
| Predator Mark | `art/effects/predator_mark/predator_mark.png` |
| Tornado Vortex | `art/effects/tornado_vortex/tornado_vortex.png` |
| Curse Aura | `art/effects/curse_aura/curse_aura.png` |
| Bullet Split | `art/effects/bullet_split/bullet_split.png` |
| Wind Trail | `art/effects/wind_trail/wind_trail.png` |

---

## COMPANION SPRITES (All Present)

| Companion | File |
|-----------|------|
| Wolf | `art/companion/wolf.png` (legacy) |
| Dire Wolf | `art/companion/dire_wolf.png` |
| Spirit Hawk | `art/companion/spirit_hawk.png` |

---

## PRIORITY

1. **Create `slingshot_portrait.png`** — this is the only blocking missing asset. Style: Thronefall top-down, warm earthy palette, simple slingshot-wielding character portrait matching the existing hero sprite.
