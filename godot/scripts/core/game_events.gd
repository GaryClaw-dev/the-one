extends Node
## Global event bus. All systems communicate through signals here.
## Autoloaded as "GameEvents"

# Game State
signal game_started
signal game_over
signal game_paused(is_paused: bool)

# Combat
signal damage_dealt(target: Node2D, amount: float, is_crit: bool)
signal enemy_killed(enemy: Node2D)
signal enemy_hit(enemy: Node2D, source: Node2D)

# Waves
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_spawned(boss: Node2D)

# Progression
signal xp_gained(amount: float)
signal level_up(new_level: int)
signal kill_streak_changed(streak: int)

# Loot & Gamba
signal loot_orb_picked_up
signal gamba_roll_started(item: Resource)
signal gamba_roll_result(item: Resource)
signal item_acquired(item: Resource)
signal reroll_used

# Hero
signal hero_health_changed(current: float, max_hp: float)
signal xp_changed(current: float, required: float)
