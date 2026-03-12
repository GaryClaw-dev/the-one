extends Node
## Tracks all stats for the current run. Used by game-over screen.

var enemies_killed: int = 0
var waves_completed: int = 0
var items_collected: int = 0
var gamba_rolls: int = 0
var legendaries_found: int = 0
var damage_dealt: float = 0.0
var highest_kill_streak: int = 0
var final_level: int = 1
var run_duration: float = 0.0
var soul_shards_earned: int = 0
var _run_start_time: float = 0.0

func _ready() -> void:
	GameEvents.game_started.connect(_reset)
	GameEvents.enemy_killed.connect(func(_e): enemies_killed += 1)
	GameEvents.wave_completed.connect(func(w): waves_completed = w)
	GameEvents.item_acquired.connect(_on_item)
	GameEvents.gamba_roll_result.connect(func(_i): gamba_rolls += 1)
	GameEvents.damage_dealt.connect(_on_damage)
	GameEvents.kill_streak_changed.connect(_on_streak)
	GameEvents.level_up.connect(func(l): final_level = l)
	GameEvents.game_over.connect(_on_run_end)

func _reset() -> void:
	enemies_killed = 0
	waves_completed = 0
	items_collected = 0
	gamba_rolls = 0
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

func _on_damage(target: Node2D, amount: float, _is_crit: bool) -> void:
	if target.is_in_group("enemies"):
		damage_dealt += amount

func _on_streak(streak: int) -> void:
	if streak > highest_kill_streak:
		highest_kill_streak = streak

func _on_run_end() -> void:
	run_duration = Time.get_ticks_msec() / 1000.0 - _run_start_time
	_calculate_soul_shards()

func _calculate_soul_shards() -> void:
	soul_shards_earned = 0
	soul_shards_earned += waves_completed * 10
	soul_shards_earned += enemies_killed / 10
	soul_shards_earned += legendaries_found * 25
	soul_shards_earned += highest_kill_streak
	soul_shards_earned += final_level * 5
