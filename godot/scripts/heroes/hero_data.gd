class_name HeroData
extends Resource
## Data definition for a hero. Create .tres files from this.

@export var hero_name: String = "Hero"
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var scene: PackedScene

@export_group("Base Stats")
@export var max_health: float = 100.0
@export var health_regen: float = 0.0
@export var armor: float = 0.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var projectile_speed: float = 400.0
@export var projectile_count: int = 1
@export var pickup_range: float = 80.0

@export_group("Unlock")
@export var unlocked_by_default: bool = false
@export var unlock_cost: int = 100

func apply_base_stats(stats: StatSystem) -> void:
	stats.set_base(StatSystem.StatType.MAX_HEALTH, max_health)
	stats.set_base(StatSystem.StatType.HEALTH_REGEN, health_regen)
	stats.set_base(StatSystem.StatType.ARMOR, armor)
	stats.set_base(StatSystem.StatType.ATTACK_DAMAGE, attack_damage)
	stats.set_base(StatSystem.StatType.ATTACK_SPEED, attack_speed)
	stats.set_base(StatSystem.StatType.CRIT_CHANCE, crit_chance)
	stats.set_base(StatSystem.StatType.CRIT_MULTIPLIER, crit_multiplier)
	stats.set_base(StatSystem.StatType.PROJECTILE_SPEED, projectile_speed)
	stats.set_base(StatSystem.StatType.PROJECTILE_COUNT, projectile_count)
	stats.set_base(StatSystem.StatType.PICKUP_RANGE, pickup_range)
	stats.set_base(StatSystem.StatType.XP_MULTIPLIER, 1.0)
	stats.set_base(StatSystem.StatType.LUCK, 0.0)
	stats.set_base(StatSystem.StatType.COOLDOWN_REDUCTION, 0.0)
	stats.set_base(StatSystem.StatType.LIFESTEAL, 0.0)
	stats.set_base(StatSystem.StatType.THORNS, 0.0)
	stats.set_base(StatSystem.StatType.DAMAGE_REDUCTION, 0.0)
