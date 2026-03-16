class_name EnemyData
extends Resource
## Data definition for an enemy type.

enum Behavior { RUSH, RANGED, ERRATIC, CHARGE, SPAWNER }

@export var enemy_name: String = "Enemy"
@export var scene: PackedScene
@export var color: Color = Color.WHITE
@export var sprite_path: String = ""

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
	# Steep phased compound growth:
	# Waves 1-15:  10% per wave (gentle intro)
	# Waves 16-30: 15% per wave (pressure ramps)
	# Waves 31-50: 20% per wave (endgame crunch)
	var multiplier: float
	if wave <= 15:
		multiplier = pow(1.10, wave - 1)
	elif wave <= 30:
		multiplier = pow(1.10, 14) * pow(1.15, wave - 15)
	else:
		multiplier = pow(1.10, 14) * pow(1.15, 15) * pow(1.20, wave - 30)
	return max_health * multiplier

func get_scaled_speed(wave: int) -> float:
	# Gentle compound growth, cap at 2.0x
	return move_speed * minf(2.0, pow(1.015, wave - 1))

func get_scaled_damage(wave: int) -> float:
	# Continuous compound: 7% per wave
	return damage * pow(1.07, wave - 1)

func get_scaled_xp(wave: int, is_first_appearance: bool = false) -> float:
	# Linear XP scaling — prevents runaway leveling
	var scaled = xp_value * (1.0 + 0.1 * (wave - 1))

	# First appearance bonus
	if is_first_appearance:
		scaled *= 1.5

	return scaled
