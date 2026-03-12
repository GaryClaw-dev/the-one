# Game Pacing Analysis & Redesign

## Current Pacing Problems

### 1. XP Curve Issues
- **Too Fast Early**: Level 2 at 5 XP = ~5 seconds
- **Too Slow Mid-Game**: Level 10+ requires 135+ XP = 3+ minutes per level
- **Linear Scaling**: Doesn't account for player power growth

### 2. Enemy Scaling Mismatched
- **HP**: +10% per wave compounds too quickly 
- **Damage**: +10% per wave makes late game one-shots
- **XP Drops**: Fixed values don't scale with difficulty

### 3. Power Spike Timing
- Class selection at level 5 (~30 seconds)
- No major milestones until much later
- Abilities feel incremental, not transformative

## Research: Successful Pacing Models

### Vampire Survivors
- **Level Time**: 8-15 seconds consistently
- **XP Scaling**: Enemies drop more XP over time
- **Power Spikes**: Every 5-10 levels feels significant

### Hades
- **Room-Based**: Clear progress markers
- **Boon Synergies**: 3-4 choices create build identity  
- **Scaling**: Enemies get new attacks, not just stats

### Risk of Rain 2
- **Time Pressure**: Difficulty scales with time
- **Item Stacking**: Linear improvements become exponential
- **Stage Transitions**: Clear difficulty jumps

## New Pacing Strategy

### Core Philosophy
1. **Consistent Dopamine**: Level up every 20-40 seconds
2. **Power Valleys & Peaks**: Struggle → Power Spike → New Challenge
3. **Build Identity**: Meaningful choices by level 10

### XP Formula Redesign
```gdscript
func _xp_for_level(level: int) -> float:
    # Base: 10 XP per level
    # Scaling: +5% compound per level
    # Milestones: -20% at 5, 15, 25 (class upgrades)
    
    var base = 10.0
    var compound = pow(1.05, level - 1)
    var requirement = base * level * compound
    
    # Class evolution levels are easier
    if level in [5, 15, 25]:
        requirement *= 0.8
    
    return requirement
```

### Enemy XP Scaling
```gdscript
func get_xp_value(wave: int) -> float:
    # Base XP + 15% per wave
    # Bonus for new enemy types
    var scaled = base_xp * (1.0 + 0.15 * (wave - 1))
    
    # First appearance bonus
    if is_new_enemy_type:
        scaled *= 1.5
        
    return scaled
```

### Enemy Stat Scaling
```gdscript
# HP: Sublinear growth
HP = base_hp * pow(wave, 0.7) 

# Damage: Stepped increases
Damage = base_damage * (1 + floor(wave/5) * 0.25)

# Speed: Capped growth  
Speed = base_speed * min(1.5, 1 + wave * 0.03)
```

## Class Evolution System

### Level 5: Base Class Choice
**Slingshot** → Archer (15) → Gunner (25) → Sniper (40)
**Fighter** → Knight (15) → Berserker (25) → Warlord (40)  
**Apprentice** → Mage (15) → Warlock (25) → Archmage (40)

### Level 15: Archer Evolution

#### Archer (from Slingshot)
**Identity**: Precision marksman with burst potential

**Base Stat Changes**:
- Attack Speed: +20%
- Crit Chance: +10%  
- Projectile Speed: +30%

**New Mechanics**:
1. **Aimed Shot** (Passive)
   - Every 5th attack is a guaranteed crit
   - Aimed shots pierce +2 enemies
   
2. **Focus Mode** (Active, 10s cooldown)
   - Next 3 attacks deal 300% damage
   - Time slows by 50% while aiming
   
3. **Wind Guidance** 
   - Projectiles curve slightly toward enemies
   - +15% accuracy (new hidden stat)

**Ability Pool Expansion**:
- **Headshot**: Crits deal +50-250% damage
- **Reload Discipline**: Every kill resets shot counter
- **Archer's Tempo**: Attack speed ramps up to +100%

### Level 25: Gunner Evolution  

#### Gunner (from Archer)
**Identity**: Overwhelming firepower and area control

**Base Stat Changes**:
- Attack Speed: +50% 
- Projectile Count: +1
- AOE Radius: All attacks gain 50 radius

**New Mechanics**:
1. **Bullet Hell** (Passive)
   - Attacks fire in a cone (30° spread)
   - Each projectile can hit multiple enemies
   
2. **Explosive Rounds** (Passive)
   - 25% chance for any projectile to explode
   - Explosions chain to nearby enemies
   
3. **Suppressing Fire** (Active, 15s cooldown)
   - Channel for 3s: +300% attack speed
   - Creates a kill zone in front of you
   - Pushback increases by 200%

**New Ability Pool**:
- **Ricochet**: Projectiles bounce 2-5 times
- **Incendiary Clips**: Burn damage over time
- **Heavy Ordnance**: Periodic missile strikes
- **Gunslinger**: Dual wield (double all attacks)

### Progression Milestones

| Level | Event | Power Increase |
|-------|-------|----------------|
| 1-4   | Learn basics | +20% per level |
| 5     | Class choice | +50% spike |
| 6-14  | Build identity | +15% per level |
| 15    | Class evolution | +100% spike |
| 16-24 | Master class | +10% per level |
| 25    | Final form | +150% spike |
| 26-40 | Endgame scaling | +5% per level |

## Implementation Priority

1. **Fix XP Curve** - More consistent leveling pace
2. **Enemy XP Scaling** - Rewards match difficulty
3. **Ability Rework** - Bigger impacts per level
4. **Class Evolution UI** - Epic moment presentation
5. **New Ability Pools** - Class-specific fantasies
6. **Enemy Behavior** - New attacks, not just stats
