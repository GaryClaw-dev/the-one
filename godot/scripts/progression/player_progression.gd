extends Node
## XP tracking and level-up system.

@export var base_xp_required: float = 100.0
@export var xp_scale_per_level: float = 1.15
@export var choices_per_level: int = 3

var level: int = 1
var current_xp: float = 0.0
var required_xp: float = 100.0

func _ready() -> void:
	GameEvents.xp_gained.connect(_add_xp)
	GameEvents.game_started.connect(_reset)

func _reset() -> void:
	level = 1
	current_xp = 0.0
	required_xp = base_xp_required
	GameEvents.xp_changed.emit(current_xp, required_xp)

func _add_xp(amount: float) -> void:
	current_xp += amount
	GameEvents.xp_changed.emit(current_xp, required_xp)

	while current_xp >= required_xp:
		current_xp -= required_xp
		level += 1
		required_xp = base_xp_required * pow(xp_scale_per_level, level - 1)
		GameEvents.level_up.emit(level)
		GameEvents.xp_changed.emit(current_xp, required_xp)
