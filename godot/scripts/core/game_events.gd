extends Node
## Global event bus. All systems communicate through signals here.
## Autoloaded as "GameEvents"

# Game State
signal game_started
signal game_over
signal game_paused(is_paused: bool)

# Combat
signal damage_dealt(target: Node2D, amount: float, is_crit: bool, damage_type: String)
signal enemy_killed(enemy: Node2D)
signal enemy_hit(enemy: Node2D, source: Node2D)

# Waves
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal boss_spawned(boss: Node2D)
signal boss_defeated(boss: Node2D)

# Progression
signal xp_gained(amount: float)
signal level_up(new_level: int)
signal kill_streak_changed(streak: int)
signal class_selected(class_key: String, class_info: Dictionary)
signal hero_evolved(new_class: String)

# Items
signal item_acquired(item: Resource)

# Hero
signal hero_health_changed(current: float, max_hp: float)
signal xp_changed(current: float, required: float)
