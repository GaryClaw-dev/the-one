class_name AbilityData
extends Resource
## Data definition for a level-up ability.

enum AbilityCategory { AUTO, OFFENSIVE, DEFENSIVE, UTILITY }

@export var ability_name: String = "Ability"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var rarity: int = Rarity.Type.COMMON
@export var max_level: int = 5
@export var tier: int = 1  # Evolution tier required: 1=Slingshot, 2=Archer, 3=Gunner
@export var branch: String = ""  # Empty = all branches. "archer", "thrower", "crossbow", etc.
@export var ability_category: AbilityCategory = AbilityCategory.AUTO

@export_group("Modifiers Per Level")
## Each entry: { "stat": StatType, "type": ModType, "value": float }
@export var modifiers_per_level: Array[Dictionary] = []

func apply(stats: StatSystem, level: int, source: Object) -> void:
	for template in modifiers_per_level:
		stats.add_modifier(
			template["stat"],
			template["type"],
			template["value"] * level,
			source
		)

func remove(stats: StatSystem, source: Object) -> void:
	stats.remove_all_from_source(source)
