# Evolved Archer & Gunner Ability Pools

## Archer (Level 15+) Abilities

### 1. Headshot (Epic)
- **Level 1**: Critical hits deal +50% damage
- **Level 2**: Critical hits deal +100% damage
- **Level 3**: Critical hits deal +150% damage
- **Level 4**: Critical hits deal +200% damage
- **Level 5**: Critical hits deal +250% damage and execute enemies below 20% HP

### 2. Reload Discipline (Rare)
- **Level 1**: Every kill resets aimed shot counter
- **Level 2**: Every kill grants +15% attack speed for 2s
- **Level 3**: Every kill resets counter and +25% attack speed for 3s
- **Level 4**: Every kill resets counter and next shot pierces all
- **Level 5**: Every kill triggers an instant aimed shot

### 3. Archer's Tempo (Rare)
- **Level 1**: Attack speed increases by 10% per second (max +50%)
- **Level 2**: Attack speed increases by 15% per second (max +75%)
- **Level 3**: Attack speed increases by 20% per second (max +100%)
- **Level 4**: Max tempo grants +25% crit chance
- **Level 5**: Max tempo shots pierce and bounce once

### 4. Wind Mastery (Epic)
- **Level 1**: Projectiles home slightly (+15% accuracy)
- **Level 2**: Projectiles home moderately (+30% accuracy)
- **Level 3**: Projectiles curve around obstacles
- **Level 4**: Missed shots return for second pass
- **Level 5**: All projectiles create wind vortexes on impact

### 5. Perfect Draw (Legendary)
- **Level 1**: Standing still for 1s: next shot deals +100% damage
- **Level 2**: Standing still for 0.8s: next shot deals +150% damage
- **Level 3**: Standing still for 0.6s: next shot deals +200% damage
- **Level 4**: Perfect draws pierce infinitely
- **Level 5**: Perfect draws split into 3 on first hit

## Gunner (Level 25+) Abilities

### 1. Ricochet (Epic)
- **Level 1**: Projectiles bounce 2 times
- **Level 2**: Projectiles bounce 3 times (+10% damage per bounce)
- **Level 3**: Projectiles bounce 4 times (+15% damage per bounce)
- **Level 4**: Projectiles bounce 5 times (+20% damage per bounce)
- **Level 5**: Bounces seek nearest enemy and can hit same enemy

### 2. Incendiary Clips (Rare)
- **Level 1**: 20% chance to ignite (10 DPS for 3s)
- **Level 2**: 30% chance to ignite (20 DPS for 3s)
- **Level 3**: 40% chance to ignite (30 DPS for 4s)
- **Level 4**: 50% chance to ignite, spreads on death
- **Level 5**: All shots ignite, creates fire pools on death

### 3. Heavy Ordnance (Legendary)
- **Level 1**: Every 50 kills: orbital strike (500% damage)
- **Level 2**: Every 40 kills: orbital strike (750% damage)
- **Level 3**: Every 30 kills: orbital strike (1000% damage)
- **Level 4**: Every 20 kills: orbital strike with stun
- **Level 5**: Every 10 kills: carpet bombing run

### 4. Gunslinger (Legendary)
- **Level 1**: Dual wield - duplicate 25% of attacks
- **Level 2**: Dual wield - duplicate 40% of attacks
- **Level 3**: Dual wield - duplicate 60% of attacks
- **Level 4**: Dual wield - duplicate 80% of attacks
- **Level 5**: True dual wield - all attacks fire twice

### 5. Ammo Types (Epic)
- **Level 1**: Cycle between normal/armor piercing each reload
- **Level 2**: Add explosive rounds to cycle
- **Level 3**: Add homing rounds to cycle
- **Level 4**: Add chain lightning rounds to cycle
- **Level 5**: Fire all ammo types simultaneously

### 6. Trigger Happy (Rare)
- **Level 1**: No movement penalty while firing
- **Level 2**: +10% move speed while firing
- **Level 3**: +20% move speed while firing, dodge chance
- **Level 4**: +30% move speed, phase through enemies
- **Level 5**: Blur mode - leave damaging afterimages

## Passive Ability Implementations

### Aimed Shot (Archer Passive)
```gdscript
var _aimed_shot_counter: int = 0
func _on_attack():
    _aimed_shot_counter += 1
    if _aimed_shot_counter >= 5:
        _aimed_shot_counter = 0
        return {crit_guaranteed: true, pierce_bonus: 2}
```

### Wind Guidance (Archer Passive)
```gdscript
func _on_projectile_update(proj, delta):
    var nearest = find_nearest_enemy(proj.position, 200)
    if nearest:
        var desired_dir = (nearest.position - proj.position).normalized()
        proj.velocity = proj.velocity.lerp(desired_dir * proj.speed, 0.15)
```

### Bullet Hell (Gunner Passive)
```gdscript
func fire_projectile(direction, angle_offset = 0.0):
    # Fire in 30° cone instead of straight
    var spread = deg_to_rad(15)
    for i in range(-1, 2):
        var angle = angle_offset + i * spread
        base_fire_projectile(direction, angle)
```

### Explosive Rounds (Gunner Passive)
```gdscript
var explosive_chance = 0.25
func _on_projectile_hit(projectile, target):
    if randf() < explosive_chance:
        create_explosion(projectile.position, 100, damage * 0.5)
        # Chain to nearby enemies
        for enemy in get_enemies_in_radius(projectile.position, 150):
            if enemy != target and randf() < 0.5:
                create_explosion(enemy.position, 50, damage * 0.25)
```
