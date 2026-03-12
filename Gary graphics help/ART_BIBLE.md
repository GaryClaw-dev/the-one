# THE ONE — Art Bible
## Visual Style: Thronefall-Inspired 2D

---

## 1. STYLE OVERVIEW

**Reference:** Thronefall's clean, warm, low-detail-but-beautiful aesthetic — translated to top-down 2D.

**Key Principles:**
- **Simple silhouettes, maximum readability** — you should identify any unit from its shape alone
- **Low detail models, high detail effects** — sprites are clean/minimal, VFX is where the juice lives
- **Warm, muted backgrounds** — earth tones, soft gradients
- **Saturated, distinct characters** — heroes and enemies pop against the ground
- **Soft lighting & glow** — Godot 2D lights, bloom, subtle ambient
- **Toy-like quality** — everything feels tactile, chunky, satisfying

**NOT this:** Pixel art. Retro. Busy/noisy. Dark/gritty.
**YES this:** Clean vectors. Soft shadows. Warm & inviting. "Cozy chaos."

---

## 2. COLOR PALETTE

### Background / Environment
```
Ground Base:     #3D2B1F (dark warm brown)
Ground Light:    #5C4033 (lighter earth)
Grass Accent:    #4A6741 (muted forest green)
Sand Variant:    #8B7355 (warm sand)
Stone/Path:      #6B6B6B (neutral grey)
```

### Heroes (saturated, bright — must pop)
```
The Noob:        #999999 (neutral grey) + #666666 (dark grey)
Slingshot:       #C4A35A (warm tan) + #8B7340 (dark leather)
Fighter:         #B84C4C (blood red) + #7A3030 (dark red trim)
Apprentice:      #6B4FBB (royal purple) + #9B7FEB (light purple glow)
Archer (evolved):#E8C547 (warm gold) + #8B6914 (dark gold trim)
```

### Enemies (desaturated, darker — threatening but readable)
```
Goblin:          #5B8C3E (olive green) + #3D5C29 (dark olive)
Skeleton:        #C4B99A (bone white) + #8B8068 (aged bone)
Bat:             #6B4F7A (dusty purple) + #3D2E47 (dark purple)
Orc Brute:       #7A5C3D (brown) + #4A3520 (dark brown)
Necromancer:     #2E2E3E (dark slate) + #6B4FBB (purple accents)
Ghost:           #B8C4D0 (pale blue-white, semi-transparent)
```

### UI / Effects
```
Health Red:      #E04040
XP Blue:         #4D9DE0
Mana Purple:     #9B59B6
```

### Rarity Colors (for item borders in boss rewards)
```
Common:          #B0B0B0 (grey)
Uncommon:        #4CBB4C (green)
Rare:            #4D9DE0 (blue)
Epic:            #9B59B6 (purple)
Legendary:       #E8C547 (gold)
```

---

## 3. SPRITE SPECIFICATIONS

### Resolution & Size
- **Base unit:** 32×32px per game tile
- **Heroes:** 32×32px (body fills ~24×28 of the space)
- **Basic enemies:** 24×24px to 32×32px
- **Bosses:** 64×64px
- **Projectiles:** 8×8 to 16×16px
- **Orbs (XP/Loot):** 12×12px
- **Items (inventory icons):** 32×32px

### Sprite Style
- **Flat shading** with 1-2 shadow tones per color
- **Bold, thick outlines** (1-2px dark outline on all sprites)
- **Minimal internal detail** — convey identity through shape + color, not busy textures
- **Slight rounded corners** — nothing sharp/angular, keeps the "soft" feel
- **No pixel art grid** — use clean anti-aliased edges (vector-rendered at target res)

---

## 4. HERO DESIGNS

### The Noob (Starting Hero — Everyone Starts Here)
- **Shape:** Small, round, unassuming — a simple circle/blob shape
- **Key features:** No distinguishing gear, maybe a rock in hand
- **Idle pose:** Standing idle, looking around nervously
- **Color:** Neutral grey (#999999) — intentionally plain
- **Animations needed:**
  - Idle (subtle breathing, 4 frames)
  - Attack (overhand rock throw, 4 frames)
  - Hit flash (white overlay, 2 frames)
  - Death (fall + fade)
- **Design intent:** Should look weak and forgettable — the contrast with evolved classes is the payoff

### Slingshot (Level 5 — Ranged Path)
- **Shape:** Slightly taller than Noob, lean silhouette
- **Key features:** Slingshot in hand, small pouch of stones
- **Color:** Warm tan/leather (#C4A35A), dark leather trim
- **Animations:** Same set, attack = slingshot pull + release

### Fighter (Level 5 — Melee Path)
- **Shape:** Wider, stockier than Noob — feels heavier
- **Key features:** Simple sword or club, basic shield
- **Color:** Blood red (#B84C4C), dark red trim, iron grey accents
- **Animations:** Same set, attack = short-range slash

### Apprentice (Level 5 — Magic Path)
- **Shape:** Rounder, wider base (robes), pointed hat
- **Key features:** Simple staff or wand, faint magic glow
- **Color:** Royal purple (#6B4FBB), light purple glow accents
- **Animations:** Same set, attack = staff raise + magic burst

### Archer (Evolved from Slingshot)
- **Shape:** Tall, lean triangle-ish silhouette
- **Key features:** Hood/cloak, visible bow on back, quiver
- **Color:** Gold body (#E8C547), brown leather details
- **Animations:** Same set, attack = bow draw + release

---

## 5. ENEMY DESIGNS

### Goblin (Wave 1+)
- **Shape:** Small, hunched, pointy ears, oversized head
- **Color:** Olive green, dark leather loincloth
- **Animation:** Quick scurrying run (4 frames), death pop

### Skeleton (Wave 1+)
- **Shape:** Humanoid, thin, visible ribs/bones
- **Color:** Off-white bone, dark eye sockets
- **Animation:** Jerky walk (bones clatter feel), throws bone projectile

### Bat (Wave 1+)
- **Shape:** Small, wide wingspan relative to body
- **Color:** Dusty purple, lighter wing membrane
- **Animation:** Wing flap (4 frames), erratic path shown through rotation

### Orc Brute (Wave 10+)
- **Shape:** Large (1.5x normal enemy), broad shoulders, tiny head
- **Color:** Brown/olive, metal armor scraps
- **Animation:** Slow stomping walk, charge wind-up

### Necromancer (Wave 10+)
- **Shape:** Tall, thin, hooded — mirror of wizard but darker
- **Color:** Dark slate with purple magic effects
- **Animation:** Floats slightly, raises hands to summon

### Ghost (Wave 10+)
- **Shape:** Classic ghost — wider at bottom, wavy edges, no legs
- **Color:** Pale blue-white, 50-70% opacity, slight glow
- **Animation:** Floating bob, phases in/out (opacity pulse)

---

## 6. PROJECTILE DESIGNS

| Projectile | Shape | Size | Color |
|-----------|-------|------|-------|
| Arrow | Thin elongated triangle | 4×12px | #E8C547 gold |
| Fire Arrow | Arrow + flame trail | 4×16px | #E04040 → #E8C547 |
| Arcane Bolt | Soft circle + tail | 8×8px | #9B59B6 purple glow |
| Bone | Chunky irregular shape | 6×10px | #C4B99A bone |
| Slime Spit | Blob with drip trail | 8×8px | #4CBB7F green |
| Enemy Bone Throw | Similar to hero bone, darker | 5×8px | #8B8068 |

---

## 7. EFFECTS & PARTICLES

### Kill Effects
- **Enemy death:** Quick "poof" — 3-4 frame expand + fade, uses enemy's color
- **Small particle burst** — 4-6 tiny squares scatter outward

### XP Orbs
- **XP Orb:** Small blue diamond, soft glow, magnetizes toward hero

### Damage Numbers
- **Style:** Clean sans-serif font, bold
- **Normal:** White, floats up + fades
- **Crit:** Yellow, 1.5x size, slight shake, "!" appended
- **Heal:** Green, floats up

### Screen Effects
- **Level up:** Brief white flash (10% opacity) + expanding ring from hero
- **Boss reward:** Gold flash overlay + screen shake when picking item
- **Boss spawn:** Screen darkens briefly, red vignette pulse
- **Wave clear:** Subtle green pulse from center

---

## 8. ENVIRONMENT / BACKGROUND

### Arena Style
The hero stands on a flat arena. No complex tilemap needed for MVP.

- **Ground:** Large subtle texture — warm brown earth with slight noise/variation
- **Edge:** Gradual fade to darker tones at screen edges (vignette)
- **Decorations (optional):** Scattered small stones, grass tufts (static, non-interactive)
- **No walls/obstacles** in MVP — pure open arena

### Future Biomes
| Biome | Ground | Accent | Mood |
|-------|--------|--------|------|
| Forest | Dark earth brown | Green grass tufts | Warm, natural |
| Dungeon | Stone grey | Torch warm glow | Moody, enclosed |
| Wasteland | Cracked sand | Dead tree silhouettes | Harsh, hot |
| Graveyard | Dark soil | Fog wisps, tombstones | Eerie, cool |

---

## 9. UI DESIGN

### Style
- **Clean, flat UI** — semi-transparent dark panels (#1A1A2E at 80% opacity)
- **Rounded corners** on all panels (8px radius)
- **Font:** Clean sans-serif (Godot default or similar), white text
- **Minimal borders** — use color and spacing, not heavy outlines
- **Rarity color accents** on item borders/backgrounds

### HUD (Always Visible)
```
┌──────────────────────────────────────────────┐
│ [█████████░░] HP: 85/100        Wave 3      │
│ [████░░░░░░░] XP: 42/100     Kills: 47      │
│ Lv.3                         Streak: 12x     │
│                                              │
│              (gameplay area)                  │
│                                              │
│                                              │
│ [Item1] [Item2] [Item3]                      │
└──────────────────────────────────────────────┘
```

### Boss Reward Panel (future — Chunk 4)
- Center screen, dark panel, rounded
- Shows 3 item choices with rarity-colored borders
- Item icon, name, description for each
- Player taps to select one
- Rarity flash + camera shake on selection

### Level Up Panel
- 3 choice buttons, stacked vertically
- Each shows: ability icon, name, description, rarity badge
- Slight hover scale (1.05x) on mouseover
- Selected choice pulses then panel closes

### Class Selection Panel (future — Chunk 2)
- Appears at level 5
- Shows 3 class cards: Slingshot, Fighter, Apprentice
- Each card has class name, passive description, preview
- Player taps to choose — defines their progression path

---

## 10. ANIMATION FRAME COUNTS

| Animation | Frames | FPS | Loop? |
|-----------|--------|-----|-------|
| Hero idle | 4 | 6 | Yes |
| Hero attack | 4 | 12 | No |
| Hero hit | 2 | 12 | No |
| Enemy walk | 4 | 8 | Yes |
| Enemy death | 3 | 12 | No |
| Projectile fly | 2 | 8 | Yes |
| XP orb pulse | 4 | 6 | Yes |
| Death poof | 4 | 12 | No |

---

## 11. ASSET DELIVERY FORMAT

- **Sprites:** PNG with transparency, organized in spritesheets or individual frames
- **Folder structure:**
```
godot/art/
├── heroes/
│   ├── archer/         (idle_0-3.png, attack_0-3.png, hit_0-1.png)
│   ├── wizard/
│   ├── slingshot/
│   ├── fighter/
│   └── apprentice/
├── enemies/
│   ├── goblin/
│   ├── skeleton/
│   ├── bat/
│   └── ...
├── projectiles/
│   ├── arrow.png
│   ├── fire_arrow.png
│   └── ...
├── effects/
│   ├── death_poof/
│   ├── level_up_ring/
│   └── ...
├── items/              (32x32 icons for each item)
│   ├── fire_arrow.png
│   ├── vampiric_fang.png
│   └── ...
├── ui/
│   ├── panel_bg.png
│   ├── button_normal.png
│   ├── health_bar_fill.png
│   └── ...
└── environment/
    ├── ground_forest.png
    ├── stone_decoration.png
    └── ...
```

---

## 12. PRIORITY ORDER (What to make first)

1. **The Noob** (idle + attack sprites) — replace the placeholder grey circle
2. **Goblin, Skeleton, Bat** sprites — already done
3. **Rock projectile** — replace the white rectangle with a small grey rock
4. **XP orb** — simple but polished
5. **Death poof effect** — spritesheet
6. **Ground texture** — already done
7. **Slingshot, Fighter, Apprentice** class sprites (Chunk 2)
8. **Boss sprites** — unique per boss type
9. **UI panels** — replace default Godot grey
10. **Evolved class sprites** (Archer, Knight, Mage, etc.) — as classes are implemented

---

*Created: 2026-03-11 by Gary Claw 🐾*
*Designed for: The One (Godot 2D)*
*Style Reference: Thronefall*
