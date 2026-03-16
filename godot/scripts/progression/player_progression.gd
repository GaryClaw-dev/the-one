extends Node
## XP tracking and level-up system.
## Curve: fast early levels (5-10 sec), gradually slowing.
## Inspired by Vampire Survivors: level 2 at 5 XP, +10 per level.

@export var choices_per_level: int = 3

var level: int = 1
var current_xp: float = 0.0
var required_xp: float = 5.0

func _ready() -> void:
	GameEvents.xp_gained.connect(_add_xp)
	GameEvents.game_started.connect(_reset)

func _reset() -> void:
	level = 1
	current_xp = 0.0
	required_xp = _xp_for_level(2)
	GameEvents.xp_changed.emit(current_xp, required_xp)

func _add_xp(amount: float) -> void:
	current_xp += amount
	GameEvents.xp_changed.emit(current_xp, required_xp)

	while current_xp >= required_xp:
		current_xp -= required_xp
		level += 1
		required_xp = _xp_for_level(level + 1)
		GameEvents.level_up.emit(level)
		GameEvents.xp_changed.emit(current_xp, required_xp)

func _xp_for_level(target_level: int) -> float:
	# Flatter curve: 8 XP base, +3% compound (was 10 / +5%)
	# Faster early levels, still scales for late game
	# Milestones: -20% at 5, 15, 25 (class evolution levels)

	var base = 10.0
	var compound = pow(1.05, target_level - 1)
	var requirement = base * target_level * compound

	# Slow down the Noob phase: levels 2-5 take ~2x longer
	if target_level <= 5:
		requirement *= 2.0

	# Class evolution levels are easier to reach
	if target_level in [5, 15, 25, 35, 50]:
		requirement *= 0.75

	return requirement
