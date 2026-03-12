extends Node
## The Gamba! Slot-machine loot rolls with pity system and rerolls.

@export_group("Rarity Weights")
@export var common_weight: float = 60.0
@export var uncommon_weight: float = 25.0
@export var rare_weight: float = 10.0
@export var epic_weight: float = 4.0
@export var legendary_weight: float = 1.0

@export_group("Pity System")
@export var pity_threshold: int = 20

@export_group("Rerolls")
@export var starting_rerolls: int = 3

@export_group("Scaling")
@export var rarity_boost_per_wave: float = 0.5
@export var luck_multiplier: float = 0.1

var rolls_since_epic: int = 0
var rerolls_remaining: int = 3
var total_rolls: int = 0
var current_roll: ItemData = null

func _ready() -> void:
	GameEvents.game_started.connect(_reset)
	GameEvents.loot_orb_picked_up.connect(_trigger_gamba)

func _reset() -> void:
	rolls_since_epic = 0
	rerolls_remaining = starting_rerolls
	total_rolls = 0
	current_roll = null

func _trigger_gamba() -> void:
	current_roll = roll()
	if current_roll:
		GameEvents.gamba_roll_started.emit(current_roll)

func roll() -> ItemData:
	total_rolls += 1
	rolls_since_epic += 1

	var wave_mgr = get_tree().current_scene.get_node_or_null("WaveManager")
	var current_wave: int = wave_mgr.current_wave if wave_mgr else 1
	var luck = _get_player_luck()

	# Pity check
	if rolls_since_epic >= pity_threshold:
		rolls_since_epic = 0
		return _roll_with_min_rarity(Rarity.Type.EPIC, current_wave, luck)

	var rarity = _roll_rarity(current_wave, luck)
	if rarity >= Rarity.Type.EPIC:
		rolls_since_epic = 0

	return ItemDatabase.get_random_item(rarity)

func reroll() -> ItemData:
	if rerolls_remaining <= 0:
		return current_roll
	rerolls_remaining -= 1
	GameEvents.reroll_used.emit()
	current_roll = roll()
	return current_roll

func accept_current_roll() -> void:
	if not current_roll:
		return
	GameEvents.gamba_roll_result.emit(current_roll)
	current_roll = null

func _roll_rarity(wave: int, luck: float) -> int:
	var bonus = wave * rarity_boost_per_wave + luck * luck_multiplier

	var c = maxf(common_weight - bonus * 2.0, 10.0)
	var u = uncommon_weight + bonus * 0.5
	var r = rare_weight + bonus * 0.3
	var e = epic_weight + bonus * 0.15
	var l = legendary_weight + bonus * 0.05

	var total = c + u + r + e + l
	var roll_val = randf() * total

	if roll_val < c: return Rarity.Type.COMMON
	roll_val -= c
	if roll_val < u: return Rarity.Type.UNCOMMON
	roll_val -= u
	if roll_val < r: return Rarity.Type.RARE
	roll_val -= r
	if roll_val < e: return Rarity.Type.EPIC
	return Rarity.Type.LEGENDARY

func _roll_with_min_rarity(min_rarity: int, wave: int, luck: float) -> ItemData:
	var rolled = _roll_rarity(wave, luck)
	var final_rarity = rolled if rolled >= min_rarity else min_rarity
	return ItemDatabase.get_random_item(final_rarity)

func _get_player_luck() -> float:
	var hero = get_tree().get_first_node_in_group("hero")
	if hero and hero is HeroBase:
		return hero.stats.get_stat(StatSystem.StatType.LUCK)
	return 0.0
