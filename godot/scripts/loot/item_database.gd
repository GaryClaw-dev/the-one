extends Node
## Autoloaded as "ItemDatabase". Registry of all items and abilities.
## Auto-loads .tres resources from the resources/ folders on startup.

var all_items: Array[ItemData] = []
var all_abilities: Array[AbilityData] = []

var _items_by_rarity: Dictionary = {}
var _abilities_by_rarity: Dictionary = {}

func _ready() -> void:
	_load_items()
	_load_abilities()
	_build_lookups()

func _load_items() -> void:
	var dir = DirAccess.open("res://resources/items/")
	if not dir:
		push_warning("ItemDatabase: No items directory found")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var item = load("res://resources/items/" + file_name)
			if item is ItemData:
				all_items.append(item)
		file_name = dir.get_next()
	print("ItemDatabase: Loaded %d items" % all_items.size())

func _load_abilities() -> void:
	var dir = DirAccess.open("res://resources/abilities/")
	if not dir:
		push_warning("ItemDatabase: No abilities directory found")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var ability = load("res://resources/abilities/" + file_name)
			if ability is AbilityData:
				all_abilities.append(ability)
		file_name = dir.get_next()
	print("ItemDatabase: Loaded %d abilities" % all_abilities.size())

func _build_lookups() -> void:
	_items_by_rarity.clear()
	_abilities_by_rarity.clear()

	for r in range(5):
		_items_by_rarity[r] = []
		_abilities_by_rarity[r] = []

	for item in all_items:
		_items_by_rarity[item.rarity].append(item)

	for ability in all_abilities:
		_abilities_by_rarity[ability.rarity].append(ability)

func get_random_item(rarity: int) -> ItemData:
	var list: Array = _items_by_rarity.get(rarity, [])
	if list.is_empty():
		for r in range(rarity - 1, -1, -1):
			var fallback: Array = _items_by_rarity.get(r, [])
			if not fallback.is_empty():
				return fallback[randi() % fallback.size()]
		return null
	return list[randi() % list.size()]

func get_random_abilities(count: int, hero: HeroBase) -> Array[AbilityData]:
	var available: Array[AbilityData] = []
	for ability in all_abilities:
		var level = hero.get_ability_level(ability)
		if level < ability.max_level:
			available.append(ability)

	available.shuffle()
	var result: Array[AbilityData] = []
	for i in range(mini(count, available.size())):
		result.append(available[i])
	return result
