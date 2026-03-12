# Evolution Branching — Sprites Needed

All sprites should follow the Art Bible style: Thronefall-inspired, clean warm tones, soft outlines, toy-like quality, flat shading with 1-2 shadow tones. PNG with transparency.

---

## Evolution Tree Reference

```
Noob (start)
  └─ Slingshot (level 5, tier 1) — sling + rocks
       ├─ Archer (level 15, tier 2) — bows, precision [EXISTS]
       │   ├─ Ranger (level 25, tier 3) — nature/beast, poison, wolves
       │   └─ Crossbow (level 25, tier 3) — heavy repeating crossbow, gadgets
       └─ Thrower (level 15, tier 2) — boulders, raw AoE power
           ├─ Lumberjack (level 25, tier 3) — throws ENTIRE TREES
           └─ Catapult (level 25, tier 3) — human siege engine, flaming boulders
```

---

## What We Already Have

| Sprite | File | Used For |
|--------|------|----------|
| Noob | `heroes/noob/noob.png` | Noob (pre-level 5) — small guy with stick |
| Archer (hooded, bow) | `heroes/archer/archer.png` | Archer (tier 2) — gold hooded cloak, bow + quiver |
| Wizard | `heroes/wizard/wizard.png` | Apprentice path (locked) |
| Arrow projectile | `projectiles/projectiles_sheet.png` | Gold arrow (top-left of sheet) |
| Fireball projectile | `projectiles/projectiles_sheet.png` | Fire effect (top-right of sheet) |
| Effects | `effects/effects_sheet.png` | Poof clouds, XP diamond, gold coin |

---

## HERO SPRITES (6 new needed)

### 1. Slingshot — `godot/art/heroes/slingshot/slingshot.png`
- **Who:** The first real class — a scrappy kid upgrading from the Noob
- **Build:** Slightly taller than Noob but still unimpressive, lean
- **Outfit:** Simple leather tunic, messy hair poking out, NO hood (that's Archer's thing)
- **Weapon:** Y-shaped wooden slingshot held in one hand, small pouch of rocks on belt
- **Palette:** Warm tan/leather (#C4A35A body, #8B7340 dark leather trim)
- **Feel:** A clear step up from Noob but still humble and grounded — "I found a stick and some rubber"

### 2. Thrower — `godot/art/heroes/thrower/thrower.png`
- **Who:** Tier 2 AoE powerhouse — chose strength over precision
- **Build:** Stocky, wide-shouldered, bare arms showing muscle — WIDER silhouette than Archer
- **Outfit:** Sleeveless leather vest, thick belt with rock pouches, heavy boots
- **Weapon:** Holds a chunky round boulder overhead in one hand (ready-to-throw pose)
- **Palette:** Earth brown (#8B6B4A body, #5C4033 vest, #A0845C skin tones)
- **Feel:** Heavy and powerful — you can tell this person throws rocks for a living

### 3. Ranger — `godot/art/heroes/ranger/ranger.png`
- **Who:** Tier 3 nature class — evolved from Archer, became one with the wild
- **Build:** Lean, hooded figure similar to Archer but more feral/organic
- **Outfit:** Green cloak with leaf/vine trim along edges, visible dagger on hip, bow slung on back
- **Companion:** A small wolf sitting at their feet or peeking from behind their leg
- **Palette:** Forest green (#4A7A3D cloak, #2E5C22 dark trim, #8B6914 leather accents)
- **Feel:** Wild and organic — Archer went clean precision, Ranger went feral nature

### 4. Crossbow — `godot/art/heroes/crossbow/crossbow.png`
- **Who:** Tier 3 gadgeteer — evolved from Archer into a mechanical weapons specialist
- **Build:** Medium, slightly more armored than Archer
- **Outfit:** Leather breastplate with metal studs/rivets, bandolier of bolts across chest, goggles pushed up on forehead
- **Weapon:** Holds a heavy repeating crossbow — chunky, mechanical-looking, oversized with visible gears/mechanisms
- **Palette:** Steel blue (#5A7A9A armor, #3D5C7A dark trim, #C4A35A brass/copper accents on the crossbow)
- **Feel:** Tinkerer/engineer vibe — looks like they built their weapon in a workshop

### 5. Lumberjack — `godot/art/heroes/lumberjack/lumberjack.png`
- **Who:** Tier 3 absurd powerhouse — evolved from Thrower, now throws entire trees
- **Build:** HUGE silhouette — tallest and widest hero sprite, barrel-chested
- **Outfit:** Plaid flannel shirt (red/brown checker pattern), thick bushy beard, knit cap/beanie
- **Weapon:** Holds a massive uprooted tree trunk over one shoulder like a baseball bat — roots and leaves still attached
- **Palette:** Forest brown-green (#6B4F3A shirt reds, #3D5C29 green accents, #8B6B4A skin)
- **Feel:** Absurd and comedic — the tree should be comically oversized. This is where the game gets silly.

### 6. Catapult — `godot/art/heroes/catapult/catapult.png`
- **Who:** Tier 3 siege class — evolved from Thrower into a walking war machine
- **Build:** Medium body but with a crude wooden siege contraption strapped to their back
- **Outfit:** Heavy leather blacksmith apron, soot-stained, thick gloves
- **Weapon/Gear:** A spring-loaded wooden catapult arm mounted on a backpack frame — the arm extends up and over their head
- **Palette:** Dark red/brown (#7A3030 leather apron, #5C4033 wood frame, #E04040 glowing ember accents where the boulders ignite)
- **Feel:** Part human, part siege engine — walking artillery. Should look dangerous and industrial.

---

## PROJECTILE SPRITES (6 new needed)

### 7. Rock/Pebble — `godot/art/projectiles/rock.png`
- **Size:** 8x8px
- **Shape:** Small irregular grey-brown stone, slightly rounded
- **Color:** #8B8068 (warm grey-brown) with a slight #A09880 highlight
- **Used by:** Slingshot basic attack
- **Feel:** Humble — just a rock. Matches the "start grounded" philosophy

### 8. Boulder — `godot/art/projectiles/boulder.png`
- **Size:** 14x14px — noticeably bigger than other projectiles
- **Shape:** Large chunky round rock with visible cracks and rough edges
- **Color:** #6B5A3D (dark earth brown) base with #8B7A5C lighter crack lines/highlights
- **Used by:** Thrower basic attack
- **Feel:** Heavy and impactful — you can almost hear it thud

### 9. Poison Arrow — `godot/art/projectiles/poison_arrow.png`
- **Size:** 4x14px (same shape as arrow)
- **Shape:** Arrow like existing one but with green dripping glow at the tip
- **Color:** #4CBB4C (green) poisoned tip fading into #E8C547 (gold) shaft
- **Used by:** Ranger attacks
- **Feel:** Archer's arrow but corrupted with nature magic — green drip trail

### 10. Crossbow Bolt — `godot/art/projectiles/crossbow_bolt.png`
- **Size:** 5x10px — shorter and thicker than an arrow
- **Shape:** Squared-off metal head, thick shaft, no feathers — mechanical look
- **Color:** #5A7A9A (steel blue) head, #8B7340 (brown) shaft
- **Used by:** Crossbow attacks
- **Feel:** Industrial, heavy, purpose-built to punch through armor

### 11. Tree Trunk — `godot/art/projectiles/tree_trunk.png`
- **Size:** 16x20px — the biggest projectile in the game
- **Shape:** An entire uprooted tree, trunk + branches + leaf tufts at the top
- **Color:** #5C4033 (brown trunk), #4A6741 (green) leaf tufts, #8B7340 (tan) root ball at base
- **Used by:** Lumberjack attacks
- **Feel:** Absolutely absurd — a whole tree flying through the air. The comedy IS the design.

### 12. Flaming Boulder — `godot/art/projectiles/flaming_boulder.png`
- **Size:** 16x16px — bigger than normal boulder
- **Shape:** Boulder wreathed in flames, fire trailing behind
- **Color:** #6B5A3D (rock core) engulfed in #E04040 (red) and #E8C547 (orange/gold) flames
- **Used by:** Catapult attacks
- **Feel:** Devastating — looks like it fell out of a medieval siege. The fire should be prominent.

---

## EFFECT SPRITES (8 new needed)

### 13. Splinter Burst — `godot/art/effects/splinter_burst.png`
- **Type:** 4-frame spritesheet (horizontal strip), each frame ~32x32px
- **What:** Wood splinters exploding outward radially from center
- **Color:** Brown/tan wood chips (#8B7340, #C4A35A) scattering from center point
- **Used by:** Lumberjack tree impact — the moment the tree shatters into splinters
- **Animation:** Frame 1: impact flash. Frame 2-3: splinters flying outward. Frame 4: fading debris

### 14. Poison Cloud — `godot/art/effects/poison_cloud.png`
- **Type:** 4-frame spritesheet (horizontal strip), each frame ~48x48px
- **What:** Green toxic cloud expanding then slowly fading
- **Color:** #4CBB4C (bright green) center fading to #2E7A2E (dark green) edges, 40-60% opacity throughout
- **Used by:** Ranger's Poison Cloud ability — lingers at enemy kill location
- **Animation:** Frame 1: small green puff. Frame 2: expanding cloud. Frame 3: full size, starting to fade. Frame 4: dissipating wisps

### 15. Fire Zone / Scorched Earth — `godot/art/effects/fire_zone.png`
- **Type:** 4-frame LOOPING spritesheet (horizontal strip), each frame ~48x48px
- **What:** Persistent ground fire flickering
- **Color:** #E04040 (red) and #E8C547 (orange) flickering flames sitting on #3D2B1F (charred/blackened ground)
- **Used by:** Catapult's Scorched Earth passive — stays on ground for several seconds
- **Animation:** Looping flame flicker — flames dance and shift between frames

### 16. Wolf Slash — `godot/art/effects/wolf_slash.png`
- **Type:** 3-frame spritesheet (horizontal strip), each frame ~24x24px
- **What:** Quick claw slash / bite mark appearing on enemy
- **Color:** #C4C4C4 (white/silver) claw marks with slight #E04040 (red) at tips
- **Used by:** Ranger's wolf companion attacks — plays on the enemy being bitten
- **Animation:** Frame 1: slash lines appear. Frame 2: full slash marks visible. Frame 3: fading

### 17. Earthshaker Shockwave — `godot/art/effects/earthshaker.png`
- **Type:** 4-frame spritesheet (horizontal strip), each frame ~64x64px
- **What:** Expanding ground ripple/ring with dust particles
- **Color:** #8B7340 (earth brown) ring expanding outward, small #A09880 dust particles
- **Used by:** Thrower's Earthshaker passive — plays at kill location, pushes enemies
- **Animation:** Frame 1: ground crack at center. Frame 2: ring expanding. Frame 3: ring wider + dust. Frame 4: dust settling/fading

### 18. Boulder Impact — `godot/art/effects/boulder_impact.png`
- **Type:** 3-frame spritesheet (horizontal strip), each frame ~32x32px
- **What:** Ground crack + dust explosion when boulders/trees land
- **Color:** #6B5A3D (brown) dust cloud with #8B8068 (grey) small rock fragments
- **Used by:** All AoE impacts — Thrower, Catapult, Lumberjack projectile landings
- **Animation:** Frame 1: impact flash + ground crack. Frame 2: dust cloud expanding. Frame 3: debris settling

### 19. Bolt Barrage Flash — `godot/art/effects/bolt_barrage.png`
- **Type:** 3-frame spritesheet (horizontal strip), each frame ~48x48px
- **What:** Steel-blue expanding ring burst — mechanical/electric feel
- **Color:** #5A7A9A (steel blue) ring flash with #C4C4C4 (white) center
- **Used by:** Crossbow's Bolt Barrage ability trigger — plays around hero when bolts fire in all directions
- **Animation:** Frame 1: bright center flash. Frame 2: ring expanding. Frame 3: ring fading

### 20. Nature's Wrath Roots — `godot/art/effects/roots_eruption.png`
- **Type:** 4-frame spritesheet (horizontal strip), each frame ~48x48px
- **What:** Thorny roots/vines erupting up from the ground
- **Color:** #5C4033 (dark brown) roots/vines with #4A6741 (green) leaf accents and #7A3030 (dark red) thorns
- **Used by:** Ranger's Nature's Wrath ability — roots burst from ground hitting all nearby enemies
- **Animation:** Frame 1: ground cracks. Frame 2: roots burst upward. Frame 3: roots at full extension with thorns visible. Frame 4: roots retract/crumble

---

## COMPANION SPRITE (1 needed)

### 21. Wolf — `godot/art/heroes/ranger/wolf.png`
- **Size:** 20x16px
- **Shape:** Small loyal wolf, side-view, alert ears up, slight crouch
- **Color:** Grey-brown fur (#8B8068 light fur, #5C4A3D dark back/ears), bright #E8C547 (yellow) eyes
- **Used by:** Ranger's wolf companion — currently wolf attacks are invisible (just damage numbers), this sprite makes them visible
- **Feel:** Small, cute, loyal, toy-like — matches the Thronefall "cozy" aesthetic. NOT scary.

---

## PORTRAIT SPRITES (5 needed — for evolution selection UI)

These appear in the evolution choice panel when the player picks their next class. Bust/close-up style, 128x128px.

### 22. Thrower Portrait — `godot/art/portraits/thrower_portrait.png`
- Close-up bust: stocky shoulders, boulder raised in one hand
- Same earth brown palette as hero sprite
- Confident, strong expression

### 23. Ranger Portrait — `godot/art/portraits/ranger_portrait.png`
- Hooded green figure, wolf peeking over their shoulder or beside them
- Forest green palette, mysterious eyes under hood

### 24. Crossbow Portrait — `godot/art/portraits/crossbow_portrait.png`
- Goggles on forehead, heavy crossbow held up, confident/cocky smirk
- Steel blue palette with brass accents

### 25. Lumberjack Portrait — `godot/art/portraits/lumberjack_portrait.png`
- Big bearded face grinning, tree trunk visible over shoulder
- Plaid shirt visible, knit cap — looks like a friendly giant

### 26. Catapult Portrait — `godot/art/portraits/catapult_portrait.png`
- Soot-stained face, determined look, siege frame visible rising behind them
- Dark red/brown palette, ember glow accents

---

## SUMMARY

| Category | Count | Priority | Notes |
|----------|-------|----------|-------|
| Hero sprites | 6 new | **HIGH** | Each class MUST look unique — silhouette alone should tell you the class |
| Projectile sprites | 6 new | **HIGH** | Players see these every second — readability is critical |
| Effect sprites | 8 new | **MEDIUM** | Adds juice and feedback, game technically works without |
| Companion sprite | 1 (wolf) | **MEDIUM** | Wolf attacks are currently invisible damage numbers |
| Portraits | 5 new | **LOW** | Evolution UI functions without them, just shows text |
| **TOTAL** | **26 sprites** | | |

### Production Order (suggested)
1. **Slingshot + Rock** — needed first since everyone starts here
2. **Thrower + Boulder + Earthshaker** — tier 2 alternative to Archer
3. **Ranger + Poison Arrow + Wolf** — tier 3 from Archer
4. **Crossbow + Bolt** — tier 3 from Archer
5. **Lumberjack + Tree Trunk + Splinter Burst** — tier 3 from Thrower
6. **Catapult + Flaming Boulder + Fire Zone** — tier 3 from Thrower
7. Remaining effects (poison cloud, roots, bolt barrage, boulder impact, wolf slash)
8. Portraits (lowest priority)
