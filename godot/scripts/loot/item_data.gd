class_name ItemData
extends Resource
## Data definition for a loot item.

enum Category { WEAPON, ARMOR, ACCESSORY, CONSUMABLE, CURSED }

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var category: Category = Category.WEAPON
@export var rarity: int = Rarity.Type.COMMON

@export_group("Stat Modifiers")
## Each entry: { "stat": StatType, "type": ModType, "value": float }
@export var modifiers: Array[Dictionary] = []

@export_group("Curse (if Cursed category)")
@export var curse_modifiers: Array[Dictionary] = []

@export_group("Evolution")
@export var evolution_partner: ItemData
@export var evolution_result: ItemData

func get_display_name() -> String:
	if rarity == Rarity.Type.COMMON:
		return item_name
	return "%s %s" % [Rarity.get_name(rarity), item_name]
