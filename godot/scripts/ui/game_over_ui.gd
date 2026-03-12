extends CanvasLayer
## Game over screen with run stats and retry/menu buttons.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var stats_label: Label = $Panel/VBox/Stats
@onready var shards_label: Label = $Panel/VBox/Shards
@onready var retry_btn: Button = $Panel/VBox/Buttons/RetryBtn
@onready var menu_btn: Button = $Panel/VBox/Buttons/MenuBtn

func _ready() -> void:
	panel.visible = false
	GameEvents.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

func _show() -> void:
	# Wait a beat before showing
	await get_tree().create_timer(1.0).timeout

	panel.visible = true

	var run_stats = get_tree().current_scene.get_node_or_null("RunStats")
	if not run_stats:
		return

	title_label.text = "DEFEATED"
	if run_stats.waves_completed >= 50:
		title_label.text = "VICTORY!"

	stats_label.text = """Waves Survived: %d
Enemies Slain: %d
Final Level: %d
Damage Dealt: %s
Items Found: %d
Gamba Rolls: %d
Legendaries: %d
Best Streak: x%d
Duration: %s""" % [
		run_stats.waves_completed,
		run_stats.enemies_killed,
		run_stats.final_level,
		_format_number(run_stats.damage_dealt),
		run_stats.items_collected,
		run_stats.gamba_rolls,
		run_stats.legendaries_found,
		run_stats.highest_kill_streak,
		_format_time(run_stats.run_duration)
	]

	shards_label.text = "+%d Soul Shards" % run_stats.soul_shards_earned
	shards_label.modulate = Color(0.6, 0.4, 1.0)

func _format_number(num: float) -> String:
	if num >= 1_000_000:
		return "%.1fM" % (num / 1_000_000.0)
	if num >= 1_000:
		return "%.1fK" % (num / 1_000.0)
	return str(roundi(num))

func _format_time(seconds: float) -> String:
	var m = floori(seconds / 60.0)
	var s = floori(fmod(seconds, 60.0))
	return "%d:%02d" % [m, s]

func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
