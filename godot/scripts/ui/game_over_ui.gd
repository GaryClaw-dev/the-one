extends CanvasLayer
## Game over screen with run stats and retry/menu buttons.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var stats_label: Label = $Panel/VBox/Stats
@onready var shards_label: Label = $Panel/VBox/Shards
@onready var retry_btn: Button = $Panel/VBox/Buttons/RetryBtn
@onready var menu_btn: Button = $Panel/VBox/Buttons/MenuBtn

var _dimmer: ColorRect = null
var _abilities_sep: HSeparator = null
var _abilities_header: Label = null
var _abilities_label: Label = null

func _ready() -> void:
	panel.visible = false
	GameEvents.game_over.connect(_show)
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_menu)

	# Style the panel background
	var panel_style = UIConst.make_panel_style()
	panel_style.bg_color = UIConst.BG_DARKER
	panel_style.set_content_margin_all(UIConst.SPACE_LG)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style the title
	title_label.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_TITLE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Style stats text
	stats_label.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_STATS)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.75))

	# Style buttons
	_style_button(retry_btn, Color(0.3, 0.75, 0.4))
	_style_button(menu_btn, Color(0.6, 0.6, 0.55))

	# Create abilities section (hidden until _show populates it)
	var vbox = $Panel/VBox
	var buttons_idx = $Panel/VBox/Buttons.get_index()

	_abilities_sep = HSeparator.new()
	_abilities_sep.modulate = Color(0.5, 0.5, 0.5, 0.35)
	_abilities_sep.visible = false
	vbox.add_child(_abilities_sep)
	vbox.move_child(_abilities_sep, buttons_idx)

	_abilities_header = Label.new()
	_abilities_header.text = "ABILITIES"
	_abilities_header.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_ABILITIES)
	_abilities_header.add_theme_color_override("font_color", Color(UIConst.GOLD, 0.8))
	_abilities_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_abilities_header.visible = false
	vbox.add_child(_abilities_header)
	vbox.move_child(_abilities_header, buttons_idx + 1)

	_abilities_label = Label.new()
	_abilities_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_abilities_label.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_ABILITIES)
	_abilities_label.add_theme_color_override("font_color", Color(0.72, 0.85, 0.95))
	_abilities_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_abilities_label.visible = false
	vbox.add_child(_abilities_label)
	vbox.move_child(_abilities_label, buttons_idx + 2)

func _style_button(btn: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color, 0.2)
	style.border_color = Color(color, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_font_size_override("font_size", 20)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color, 0.35)
	hover_style.border_color = color
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(color, 0.5)
	btn.add_theme_stylebox_override("pressed", pressed_style)

func _show() -> void:
	# Wait a beat before showing
	await get_tree().create_timer(1.0).timeout

	# Add dimmer
	_show_dimmer()
	panel.visible = true

	# Slower dramatic entrance
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.35)

	# Press feedback on buttons
	UIConst.add_press_feedback(retry_btn, get_tree())
	UIConst.add_press_feedback(menu_btn, get_tree())

	var run_stats = get_tree().current_scene.get_node_or_null("RunStats")
	if not run_stats:
		return

	title_label.text = "LOOKS LIKE MAMA RAISED A LOSER"
	title_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	stats_label.text = """Waves Survived: %d
Enemies Slain: %d
Final Level: %d
Damage Dealt: %s
Items Found: %d
Legendaries: %d
Best Streak: x%d
Duration: %s""" % [
		run_stats.waves_completed,
		run_stats.enemies_killed,
		run_stats.final_level,
		_format_number(run_stats.damage_dealt),
		run_stats.items_collected,
		run_stats.legendaries_found,
		run_stats.highest_kill_streak,
		_format_time(run_stats.run_duration)
	]

	shards_label.text = "+%d Soul Shards" % run_stats.soul_shards_earned
	shards_label.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_SHARDS)
	shards_label.modulate = Color(0.6, 0.4, 1.0)

	# Best records line
	var records: Array[String] = []
	if run_stats.waves_completed >= run_stats.best_wave and run_stats.best_wave > 0:
		records.append("NEW BEST WAVE!")
	if run_stats.enemies_killed >= run_stats.best_kills and run_stats.best_kills > 0:
		records.append("NEW KILL RECORD!")
	if records.size() > 0:
		var record_label = Label.new()
		record_label.text = "  ".join(records)
		record_label.add_theme_font_size_override("font_size", UIConst.FONT_GAMEOVER_STATS)
		record_label.modulate = Color(1.0, 0.85, 0.2)
		record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shards_label.get_parent().add_child(record_label)
		shards_label.get_parent().move_child(record_label, shards_label.get_index() + 1)

	# Populate abilities summary
	var hero = GameManager.active_hero as HeroBase if GameManager else null
	if hero and hero.abilities.size() > 0:
		var entries: Array = []
		for ability in hero.abilities:
			entries.append("%s Lv.%d" % [ability.ability_name, hero.abilities[ability]])
		entries.sort()
		_abilities_label.text = "  •  ".join(entries)
		_abilities_sep.visible = true
		_abilities_header.visible = true
		_abilities_label.visible = true
	else:
		_abilities_sep.visible = false
		_abilities_header.visible = false
		_abilities_label.visible = false

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
	AudioManager.play("click")
	_hide_dimmer()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu() -> void:
	AudioManager.play("click")
	_hide_dimmer()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _show_dimmer() -> void:
	if _dimmer:
		return
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0, 0, 0, 0.75)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)
	move_child(_dimmer, 0)
	UIConst.animate_dimmer(_dimmer, get_tree())

func _hide_dimmer() -> void:
	if _dimmer:
		_dimmer.queue_free()
		_dimmer = null
