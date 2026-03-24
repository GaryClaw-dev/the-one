class_name EvolutionOptionData
extends Resource
## Data for a single evolution choice (one branch of a branching point).

@export var key: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var color: Color = Color.WHITE
@export var tier: int = 2

@export_group("Stat Bonuses")
## Each entry: { "stat": StatType(int), "type": ModType(int), "value": float, "label": String }
@export var stat_bonuses: Array[Dictionary] = []

@export_group("Passives")
@export var passives: Array[String] = []
