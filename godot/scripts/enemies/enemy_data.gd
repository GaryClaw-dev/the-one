class_name EnemyData
extends Resource
## Data definition for an enemy type.

enum Behavior { RUSH, RANGED, ERRATIC, CHARGE, SPAWNER }

@export var enemy_name: String = "Enemy"
@export var scene: PackedScene
@export var color: Color = Color.WHITE

@export_group("Stats")
@export var max_health: float = 20.0
@export var move_speed: float = 80.0
@export var damage: float = 5.0
@export var attack_cooldown: float = 1.0

@export_group("Behavior")
@export var behavior: Behavior = Behavior.RUSH
@export var attack_range: float = 30.0

@export_group("Drops")
@export var xp_value: float = 10.0
@export_range(0.0, 1.0) var loot_drop_chance: float = 0.05

@export_group("Scaling")
@export var hp_scale_per_wave: float = 0.1
@export var speed_scale_per_wave: float = 0.02

@export_group("Boss")
@export var is_boss: bool = false
@export var is_mini_boss: bool = false

func get_scaled_hp(wave: int) -> float:
	return max_health * (1.0 + hp_scale_per_wave * (wave - 1))

func get_scaled_speed(wave: int) -> float:
	return move_speed * (1.0 + speed_scale_per_wave * mini(wave - 1, 30))
