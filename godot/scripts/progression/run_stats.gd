extends Node
## Tracks all stats for the current run. Used by game-over screen.

var enemies_killed: int = 0
var waves_completed: int = 0
var items_collected: int = 0
var legendaries_found: int = 0
var damage_dealt: float = 0.0
var highest_kill_streak: int = 0
var final_level: int = 1
var run_duration: float = 0.0
var soul_shards_earned: int = 0
var _run_start_time: float = 0.0

func _ready() -> void:
	load_best_stats()
	GameEvents.game_started.connect(_reset)
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	GameEvents.wave_completed.connect(_on_wave_completed)
	GameEvents.item_acquired.connect(_on_item)
	GameEvents.damage_dealt.connect(_on_damage)
	GameEvents.kill_streak_changed.connect(_on_streak)
	GameEvents.level_up.connect(_on_level_up)
	GameEvents.game_over.connect(_on_run_end)

func _exit_tree() -> void:
	GameEvents.game_started.disconnect(_reset)
	GameEvents.enemy_killed.disconnect(_on_enemy_killed)
	GameEvents.wave_completed.disconnect(_on_wave_completed)
	GameEvents.item_acquired.disconnect(_on_item)
	GameEvents.damage_dealt.disconnect(_on_damage)
	GameEvents.kill_streak_changed.disconnect(_on_streak)
	GameEvents.level_up.disconnect(_on_level_up)
	GameEvents.game_over.disconnect(_on_run_end)

func _on_enemy_killed(_e: Node2D) -> void:
	enemies_killed += 1

func _on_wave_completed(w: int) -> void:
	waves_completed = w

func _on_level_up(l: int) -> void:
	final_level = l

func _reset() -> void:
	enemies_killed = 0
	waves_completed = 0
	items_collected = 0
	legendaries_found = 0
	damage_dealt = 0.0
	highest_kill_streak = 0
	final_level = 1
	run_duration = 0.0
	soul_shards_earned = 0
	_run_start_time = Time.get_ticks_msec() / 1000.0

func _on_item(item: Resource) -> void:
	items_collected += 1
	if item is ItemData and item.rarity == Rarity.Type.LEGENDARY:
		legendaries_found += 1

func _on_damage(target: Node2D, amount: float, _is_crit: bool, _type: String = "") -> void:
	if target.is_in_group("enemies"):
		damage_dealt += amount

func _on_streak(streak: int) -> void:
	if streak > highest_kill_streak:
		highest_kill_streak = streak

func _on_run_end() -> void:
	run_duration = Time.get_ticks_msec() / 1000.0 - _run_start_time
	_calculate_soul_shards()
	_save_best_stats()

func _calculate_soul_shards() -> void:
	soul_shards_earned = 0
	soul_shards_earned += waves_completed * 10
	soul_shards_earned += enemies_killed / 10
	soul_shards_earned += legendaries_found * 25
	soul_shards_earned += highest_kill_streak
	soul_shards_earned += final_level * 5

# ---- Best Run Persistence ----

const SAVE_PATH = "user://best_stats.cfg"

var best_wave: int = 0
var best_kills: int = 0
var best_damage: float = 0.0
var best_streak: int = 0
var best_level: int = 0
var total_runs: int = 0

func _save_best_stats() -> void:
	var updated = false
	if waves_completed > best_wave:
		best_wave = waves_completed
		updated = true
	if enemies_killed > best_kills:
		best_kills = enemies_killed
		updated = true
	if damage_dealt > best_damage:
		best_damage = damage_dealt
		updated = true
	if highest_kill_streak > best_streak:
		best_streak = highest_kill_streak
		updated = true
	if final_level > best_level:
		best_level = final_level
		updated = true
	total_runs += 1

	var config = ConfigFile.new()
	config.set_value("best", "wave", best_wave)
	config.set_value("best", "kills", best_kills)
	config.set_value("best", "damage", best_damage)
	config.set_value("best", "streak", best_streak)
	config.set_value("best", "level", best_level)
	config.set_value("best", "total_runs", total_runs)
	config.save(SAVE_PATH)

func load_best_stats() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_wave = config.get_value("best", "wave", 0)
	best_kills = config.get_value("best", "kills", 0)
	best_damage = config.get_value("best", "damage", 0.0)
	best_streak = config.get_value("best", "streak", 0)
	best_level = config.get_value("best", "level", 0)
	total_runs = config.get_value("best", "total_runs", 0)
