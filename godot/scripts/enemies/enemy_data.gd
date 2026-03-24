class_name EnemyData
extends Resource
## Data definition for an enemy type.

enum Behavior { RUSH, RANGED, ERRATIC, CHARGE, SPAWNER }

@export var enemy_name: String = "Enemy"
@export var scene: PackedScene
@export var color: Color = Color.WHITE
@export var sprite_path: String = ""

@export_group("Sprite Sheets")
@export var sprite_sheet_idle: String = ""
@export var sprite_sheet_walk: String = ""
@export var sprite_sheet_attack: String = ""
@export var sheet_frame_count: int = 4
@export var sheet_frame_size: Vector2 = Vector2(384, 1024)

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

@export_group("Scaling")
@export var hp_scale_per_wave: float = 0.1
@export var speed_scale_per_wave: float = 0.02

@export_group("Boss")
@export var is_boss: bool = false
@export var is_mini_boss: bool = false

func get_scaled_hp(wave: int) -> float:
	# Uniform 10% compound growth per wave
	return max_health * pow(1.10, wave - 1)

func get_scaled_speed(wave: int) -> float:
	# Gentle compound growth, cap at 2.0x
	return move_speed * minf(2.0, pow(1.015, wave - 1))

func get_scaled_damage(wave: int) -> float:
	# Continuous compound: 5% per wave
	return damage * pow(1.05, wave - 1)

func get_scaled_xp(wave: int, is_first_appearance: bool = false) -> float:
	# Linear XP scaling — prevents runaway leveling
	var scaled = xp_value * (1.0 + 0.1 * (wave - 1))

	# First appearance bonus
	if is_first_appearance:
		scaled *= 1.5

	return scaled
