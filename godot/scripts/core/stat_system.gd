class_name StatSystem
extends RefCounted
## RPG stat engine with base values + modifiers.
## Formula: (base + flat) * (1 + sum_percent_add) * product(1 + percent_mult)

enum StatType {
	MAX_HEALTH,
	HEALTH_REGEN,
	ARMOR,
	ATTACK_DAMAGE,
	ATTACK_SPEED,
	CRIT_CHANCE,
	CRIT_MULTIPLIER,
	PROJECTILE_SPEED,
	PROJECTILE_COUNT,
	PROJECTILE_PIERCE,
	AOE_RADIUS,
	KNOCKBACK_FORCE,
	LIFESTEAL,
	THORNS,
	PICKUP_RANGE,
	XP_MULTIPLIER,
	LUCK,
	COOLDOWN_REDUCTION,
	DAMAGE_REDUCTION
}

enum ModType {
	FLAT,
	PERCENT_ADD,
	PERCENT_MULTIPLY
}

var _base_values: Dictionary = {}
var _modifiers: Dictionary = {} # StatType -> Array[Dictionary]
var _cache: Dictionary = {}
var _dirty: Dictionary = {}

signal stat_changed(stat_type: int, new_value: float)

static func get_stat_name(stat_type: int) -> String:
	match stat_type:
		StatType.MAX_HEALTH: return "HP"
		StatType.HEALTH_REGEN: return "HP Regen"
		StatType.ARMOR: return "Armor"
		StatType.ATTACK_DAMAGE: return "ATK"
		StatType.ATTACK_SPEED: return "ATK SPD"
		StatType.CRIT_CHANCE: return "Crit"
		StatType.CRIT_MULTIPLIER: return "Crit DMG"
		StatType.PROJECTILE_SPEED: return "Proj SPD"
		StatType.PROJECTILE_COUNT: return "Proj Count"
		StatType.PROJECTILE_PIERCE: return "Pierce"
		StatType.AOE_RADIUS: return "AoE"
		StatType.KNOCKBACK_FORCE: return "Knockback"
		StatType.LIFESTEAL: return "Lifesteal"
		StatType.THORNS: return "Thorns"
		StatType.PICKUP_RANGE: return "Pickup"
		StatType.XP_MULTIPLIER: return "XP Mult"
		StatType.LUCK: return "Luck"
		StatType.COOLDOWN_REDUCTION: return "CDR"
		StatType.DAMAGE_REDUCTION: return "DMG Red"
	return "???"

func set_base(stat_type: int, value: float) -> void:
	_base_values[stat_type] = value
	_mark_dirty(stat_type)

func get_base(stat_type: int) -> float:
	return _base_values.get(stat_type, 0.0)

func get_stat(stat_type: int) -> float:
	if not _dirty.get(stat_type, false) and _cache.has(stat_type):
		return _cache[stat_type]

	var final = _calculate(stat_type)
	_cache[stat_type] = final
	_dirty[stat_type] = false
	return final

func add_modifier(stat_type: int, mod_type: int, value: float, source: Object = null) -> Dictionary:
	var mod = {
		"stat": stat_type,
		"type": mod_type,
		"value": value,
		"source": source
	}

	if not _modifiers.has(stat_type):
		_modifiers[stat_type] = []

	_modifiers[stat_type].append(mod)
	_modifiers[stat_type].sort_custom(func(a, b): return a["type"] < b["type"])
	_mark_dirty(stat_type)
	return mod

func remove_modifier(mod: Dictionary) -> void:
	var stat_type: int = mod.get("stat", -1)
	if not _modifiers.has(stat_type):
		return
	_modifiers[stat_type].erase(mod)
	_mark_dirty(stat_type)

func remove_all_from_source(source: Object) -> void:
	for stat_type in _modifiers:
		var mods: Array = _modifiers[stat_type]
		var to_remove = []
		for mod in mods:
			if mod["source"] == source:
				to_remove.append(mod)
		for mod in to_remove:
			mods.erase(mod)
		if to_remove.size() > 0:
			_mark_dirty(stat_type)

func clear_all_modifiers() -> void:
	_modifiers.clear()
	_cache.clear()
	_dirty.clear()

func _calculate(stat_type: int) -> float:
	var base_value: float = _base_values.get(stat_type, 0.0)

	if not _modifiers.has(stat_type) or _modifiers[stat_type].is_empty():
		return base_value

	var flat = 0.0
	var percent_add = 0.0
	var percent_mult = 1.0

	for mod in _modifiers[stat_type]:
		match mod["type"]:
			ModType.FLAT:
				flat += mod["value"]
			ModType.PERCENT_ADD:
				percent_add += mod["value"]
			ModType.PERCENT_MULTIPLY:
				percent_mult *= (1.0 + mod["value"])

	return (base_value + flat) * (1.0 + percent_add) * percent_mult

func _mark_dirty(stat_type: int) -> void:
	var old_value: float = _cache.get(stat_type, NAN)
	_dirty[stat_type] = true
	var new_value = get_stat(stat_type)

	if not is_equal_approx(old_value, new_value):
		stat_changed.emit(stat_type, new_value)
