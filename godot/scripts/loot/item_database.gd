extends Node
## Autoloaded as "ItemDatabase". Registry of all items and abilities.
## Auto-loads .tres resources from the resources/ folders on startup.

var all_items: Array[ItemData] = []
var all_abilities: Array[AbilityData] = []
var archer_abilities: Array[AbilityData] = []
var fighter_abilities: Array[AbilityData] = []
var apprentice_abilities: Array[AbilityData] = []

var _items_by_rarity: Dictionary = {}
var _abilities_by_rarity: Dictionary = {}
var _class_abilities: Dictionary = {}

const SLINGSHOT_FAMILY = ["slingshot", "archer", "repeater", "ranger", "windwalker", "crossbow", "stormcaller", "beastlord", "phantom", "tempest", "spirit_archer", "gunslinger", "siege_master", "thunderlord", "demon_hunter"]

func _ready() -> void:
	_load_items()
	_load_abilities()
	_load_class_abilities()
	_build_lookups()

func _load_items() -> void:
	# Hardcoded paths — DirAccess can't list files inside exported .pck
	var paths := [
		"res://resources/items/aegis_of_eternity.tres",
		"res://resources/items/berserkers_gauntlet.tres",
		"res://resources/items/blast_powder.tres",
		"res://resources/items/bloodprice_amulet.tres",
		"res://resources/items/chain_links.tres",
		"res://resources/items/chrono_gear.tres",
		"res://resources/items/deathdealers_crest.tres",
		"res://resources/items/fire_arrow.tres",
		"res://resources/items/fortified_bastion.tres",
		"res://resources/items/gatling_core.tres",
		"res://resources/items/glass_cannon_prism.tres",
		"res://resources/items/iron_plate.tres",
		"res://resources/items/lucky_coin.tres",
		"res://resources/items/nova_engine.tres",
		"res://resources/items/parasite_heart.tres",
		"res://resources/items/phasing_bolt.tres",
		"res://resources/items/quiver_of_haste.tres",
		"res://resources/items/repeating_mechanism.tres",
		"res://resources/items/scope_lens.tres",
		"res://resources/items/serrated_blade.tres",
		"res://resources/items/shockwave_emitter.tres",
		"res://resources/items/snipers_mark.tres",
		"res://resources/items/soul_reaper.tres",
		"res://resources/items/thorn_ring.tres",
		"res://resources/items/vampiric_fang.tres",
		"res://resources/items/whetstone.tres",
	]
	for path in paths:
		var item = load(path)
		if item is ItemData:
			all_items.append(item)
	print("ItemDatabase: Loaded %d items" % all_items.size())

func _load_abilities() -> void:
	# Hardcoded paths — DirAccess can't list files inside exported .pck
	var paths := [
		"res://resources/abilities/blood_siphon.tres",
		"res://resources/abilities/concussive_force.tres",
		"res://resources/abilities/eagle_eye.tres",
		"res://resources/abilities/executioner.tres",
		"res://resources/abilities/iron_will.tres",
		"res://resources/abilities/lucky_star.tres",
		"res://resources/abilities/overclock.tres",
		"res://resources/abilities/piercing_gale.tres",
		"res://resources/abilities/rapid_fire.tres",
		"res://resources/abilities/razor_focus.tres",
		"res://resources/abilities/regeneration.tres",
		"res://resources/abilities/shrapnel_rounds.tres",
		"res://resources/abilities/split_shot.tres",
		"res://resources/abilities/thorn_mail.tres",
		# New generic offensive
		"res://resources/abilities/berserkers_fury.tres",
		"res://resources/abilities/marksmans_eye.tres",
		"res://resources/abilities/savage_strikes.tres",
		"res://resources/abilities/barrage_protocol.tres",
		"res://resources/abilities/precision_calibration.tres",
		"res://resources/abilities/impact_force.tres",
		# New generic defensive
		"res://resources/abilities/stone_skin.tres",
		"res://resources/abilities/resilience.tres",
		"res://resources/abilities/adaptive_shield.tres",
		"res://resources/abilities/fortify.tres",
		"res://resources/abilities/last_stand.tres",
		# New utility
		"res://resources/abilities/scavengers_instinct.tres",
		"res://resources/abilities/fortunes_favor.tres",
		"res://resources/abilities/temporal_flux.tres",
	]
	for path in paths:
		var ability = load(path)
		if ability is AbilityData:
			all_abilities.append(ability)
	print("ItemDatabase: Loaded %d abilities" % all_abilities.size())

func _load_class_abilities() -> void:
	# Load archer abilities
	var archer_paths := [
		# Tier 1 — Slingshot (level 5+)
		"res://resources/abilities/archer/steady_aim.tres",
		"res://resources/abilities/archer/quick_draw.tres",
		"res://resources/abilities/archer/eagle_eye_archer.tres",
		"res://resources/abilities/archer/piercing_shot.tres",
		"res://resources/abilities/archer/double_nock.tres",
		"res://resources/abilities/archer/lethal_precision.tres",
		"res://resources/abilities/archer/wind_arrows.tres",
		"res://resources/abilities/archer/hunter_focus.tres",
		"res://resources/abilities/archer/explosive_tips.tres",
		"res://resources/abilities/archer/archer_arsenal.tres",
		"res://resources/abilities/archer/marked_for_death.tres",
		"res://resources/abilities/archer/rain_of_arrows.tres",
		# On-hit effects (tier 1, all slingshot branches)
		"res://resources/abilities/archer/frostbite.tres",
		"res://resources/abilities/archer/chain_lightning.tres",
		"res://resources/abilities/archer/bleed.tres",
		"res://resources/abilities/archer/vampiric_strikes.tres",
		"res://resources/abilities/archer/shatter_shot.tres",
		"res://resources/abilities/archer/unstable_rounds.tres",
		# Tier 2 — Archer (level 15+)
		"res://resources/abilities/archer/headshot.tres",
		"res://resources/abilities/archer/reload_discipline.tres",
		"res://resources/abilities/archer/archers_tempo.tres",
		# (Thrower branch removed)
		# Crossbow/Repeater branch
		"res://resources/abilities/archer/ricochet.tres",
		"res://resources/abilities/archer/gunslinger.tres",
		"res://resources/abilities/crossbow/bolt_barrage.tres",
		"res://resources/abilities/crossbow/grappling_hook.tres",
		"res://resources/abilities/crossbow/mechanical_overload.tres",
		# Tier 3 — Ranger branch
		"res://resources/abilities/ranger/poison_cloud.tres",
		"res://resources/abilities/ranger/pack_leader.tres",
		"res://resources/abilities/ranger/natures_wrath.tres",
		"res://resources/abilities/ranger/camouflage.tres",
		# (Lumberjack/Catapult branches removed)
	]
	
	for path in archer_paths:
		var ability = load(path)
		if ability:
			archer_abilities.append(ability)
	
	# For now, fighter and apprentice use the default abilities
	fighter_abilities = all_abilities.duplicate()
	apprentice_abilities = all_abilities.duplicate()

	# Mix generic abilities into class-specific pools so all classes see them
	for cls in SLINGSHOT_FAMILY:
		var combined: Array[AbilityData] = []
		combined.append_array(all_abilities)
		combined.append_array(archer_abilities)
		_class_abilities[cls] = combined
	_class_abilities["fighter"] = fighter_abilities
	_class_abilities["apprentice"] = apprentice_abilities
	
	print("ItemDatabase: Loaded %d archer abilities" % archer_abilities.size())

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

## Returns `count` random items appropriate for a boss at the given wave.
## Higher waves = higher rarity floor. No duplicate items in the result.
func get_random_items_for_boss(count: int, wave: int, hero: HeroBase) -> Array[ItemData]:
	# Determine rarity range based on wave
	# Wave 10: Common-Uncommon, Wave 20: Uncommon-Rare, Wave 30: Rare-Epic, Wave 40+: Epic-Legendary
	var min_rarity: int = clampi((wave / 10) - 1, 0, 4)
	var max_rarity: int = clampi((wave / 10), 0, 4)

	# Gather candidate items (exclude items hero already owns)
	var owned_names: Dictionary = {}
	for item in hero.items:
		owned_names[item.item_name] = true

	var candidates: Array[ItemData] = []
	for r in range(min_rarity, max_rarity + 1):
		for item in _items_by_rarity.get(r, []):
			if not owned_names.has(item.item_name):
				candidates.append(item)

	# If not enough unique candidates, expand rarity range
	if candidates.size() < count:
		for r in range(5):
			if r >= min_rarity and r <= max_rarity:
				continue
			for item in _items_by_rarity.get(r, []):
				if not owned_names.has(item.item_name):
					candidates.append(item)

	candidates.shuffle()
	var result: Array[ItemData] = []
	for i in range(mini(count, candidates.size())):
		result.append(candidates[i])
	return result

func get_random_item(rarity: int) -> ItemData:
	var list: Array = _items_by_rarity.get(rarity, [])
	if list.is_empty():
		for r in range(rarity - 1, -1, -1):
			var fallback: Array = _items_by_rarity.get(r, [])
			if not fallback.is_empty():
				return fallback[randi() % fallback.size()]
		return null
	return list[randi() % list.size()]

## Stat types considered offensive (attack speed, damage, crit, projectile, AoE, knockback)
const OFFENSIVE_STATS := [3, 4, 5, 6, 7, 8, 9, 10, 11]  # +PROJ_COUNT, AOE_RADIUS, KNOCKBACK
## Stat types considered defensive (HP, regen, armor, lifesteal, thorns, damage reduction)
const DEFENSIVE_STATS := [0, 1, 2, 12, 13, 18]  # +LIFESTEAL

func _is_offensive(ability: AbilityData) -> bool:
	if ability.ability_category == AbilityData.AbilityCategory.OFFENSIVE:
		return true
	if ability.ability_category != AbilityData.AbilityCategory.AUTO:
		return false
	for mod in ability.modifiers_per_level:
		if mod.get("stat", -1) in OFFENSIVE_STATS:
			return true
	return false

func _is_defensive(ability: AbilityData) -> bool:
	if ability.ability_category == AbilityData.AbilityCategory.DEFENSIVE:
		return true
	if ability.ability_category != AbilityData.AbilityCategory.AUTO:
		return false
	for mod in ability.modifiers_per_level:
		if mod.get("stat", -1) in DEFENSIVE_STATS:
			return true
	return false

func get_random_abilities(count: int, hero: HeroBase) -> Array[AbilityData]:
	var available: Array[AbilityData] = []

	# Use class-specific abilities if hero has a class
	var hero_class = hero.get_meta("hero_class", "noob")
	var hero_branch = hero.get_meta("hero_branch", "")
	var ability_pool = _class_abilities.get(hero_class, all_abilities)

	# Filter by evolution tier and branch
	var hero_tier = hero.get_meta("hero_evolution_tier", 1)
	var branch_parts = hero_branch.split(".")
	for ability in ability_pool:
		if ability.tier > hero_tier:
			continue
		# Branch gate: if ability requires a specific branch, hero must have evolved through it
		if ability.branch != "" and ability.branch not in branch_parts:
			continue
		if hero_class in ability.excluded_archetypes:
			continue
		var level = hero.get_ability_level(ability)
		if level < ability.max_level:
			available.append(ability)

	if available.is_empty():
		return []

	# Guarantee at least one offensive and one defensive choice
	var offensive: Array[AbilityData] = []
	var defensive: Array[AbilityData] = []
	var others: Array[AbilityData] = []
	for ability in available:
		if _is_offensive(ability):
			offensive.append(ability)
		elif _is_defensive(ability):
			defensive.append(ability)
		else:
			others.append(ability)

	offensive.shuffle()
	defensive.shuffle()
	others.shuffle()

	var result: Array[AbilityData] = []
	var used: Dictionary = {}

	# Slot 1: guaranteed offensive
	if offensive.size() > 0:
		result.append(offensive[0])
		used[offensive[0]] = true
	# Slot 2: guaranteed defensive
	if defensive.size() > 0:
		result.append(defensive[0])
		used[defensive[0]] = true

	# Fill remaining slots from full shuffled pool (no duplicates)
	available.shuffle()
	for ability in available:
		if result.size() >= count:
			break
		if not used.has(ability):
			result.append(ability)
			used[ability] = true

	result.shuffle()
	return result
