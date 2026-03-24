class_name FighterAbilityData
extends AbilityData
## Extended ability data for fighter abilities with level-specific scaling

@export_group("Level Specific Values")
@export var level_values: Array[float] = [1.0, 2.0, 3.0, 4.0, 5.0]
@export var level_descriptions: Array[String] = []

# For abilities with multiple effects per level
@export var secondary_stat: int = -1
@export var secondary_mod_type: int = StatSystem.ModType.PERCENT_ADD
@export var secondary_values: Array[float] = []

# Special ability types
@export var special_type: String = "" # "war_cry", "whirlwind", "shield_bash", etc.
@export var special_values: Array[float] = []

func get_description_for_level(level: int) -> String:
	if level_descriptions.size() >= level:
		return level_descriptions[level - 1]
	return description

func apply(stats: StatSystem, level: int, source: Object) -> void:
	# Apply primary stat
	if modifiers_per_level.size() > 0:
		var template = modifiers_per_level[0]
		var value = level_values[level - 1] if level <= level_values.size() else template["value"] * level
		stats.add_modifier(
			template["stat"],
			template["type"],
			value,
			source
		)

	# Apply secondary stat if exists
	if secondary_stat >= 0 and secondary_values.size() >= level:
		stats.add_modifier(
			secondary_stat,
			secondary_mod_type,
			secondary_values[level - 1],
			source
		)

	# Handle special ability types
	if special_type != "":
		var hero = GameManager.active_hero
		if hero and hero.has_method("add_special_ability"):
			hero.add_special_ability(special_type, level, [level_values, special_values])
