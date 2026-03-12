extends CanvasLayer
## Boss reward panel. Shows 3 random items to pick from after defeating a boss.
## Pauses game, big clickable/tappable buttons for mobile.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices
@onready var title_label: Label = $Panel/VBoxContainer/Title

var _hero: HeroBase = null
var _pending_bosses: Array[int] = []  # wave numbers queued

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	GameEvents.game_started.connect(func():
		_pending_bosses.clear()
	)

func _on_boss_defeated(boss: Node2D) -> void:
	_refresh_hero()
	if not _hero:
		return

	# Get the wave from WaveManager
	var wm = get_node_or_null("/root/WaveManager")
	if not wm:
		wm = get_tree().current_scene.get_node_or_null("WaveManager")
	var wave: int = wm.current_wave if wm else 10

	# If another UI is open (level-up, class selection), queue this reward
	if _is_another_ui_open():
		_pending_bosses.append(wave)
		return

	_show_reward(wave)

func _is_another_ui_open() -> bool:
	# Check level-up UI
	var lvl_ui = get_tree().current_scene.get_node_or_null("LevelUpUI")
	if lvl_ui and lvl_ui.get("panel") and lvl_ui.panel.visible:
		return true
	# Check class selection UI
	var cls_ui = get_node_or_null("/root/ClassSelectionUI")
	if cls_ui and cls_ui.get("panel") and cls_ui.panel.visible:
		return true
	return false

func _show_reward(wave: int) -> void:
	_refresh_hero()
	if not _hero:
		return

	var items = ItemDatabase.get_random_items_for_boss(3, wave, _hero)
	if items.is_empty():
		_process_next_pending()
		return

	title_label.text = "BOSS DEFEATED!"
	_show_choices(items)

func _refresh_hero() -> void:
	_hero = GameManager.active_hero as HeroBase

func _show_choices(items: Array[ItemData]) -> void:
	for child in choices_container.get_children():
		child.queue_free()

	panel.visible = true

	for item in items:
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS

		# Build label: name + description + stat modifiers
		var label_text = item.item_name
		if item.description:
			label_text += "\n" + item.description
		# Show stat modifiers
		var mod_text = _get_modifier_text(item)
		if mod_text:
			label_text += "\n" + mod_text

		btn.text = label_text
		btn.custom_minimum_size = Vector2(500, 110)
		btn.add_theme_font_size_override("font_size", 18)

		# Color by rarity
		var rarity_color = Rarity.get_color(item.rarity)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(rarity_color, 0.25)
		style.border_color = rarity_color
		style.set_border_width_all(3)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(16)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = style.duplicate()
		hover_style.bg_color = Color(rarity_color, 0.5)
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = style.duplicate()
		pressed_style.bg_color = Color(rarity_color, 0.7)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var focus_style = style.duplicate()
		focus_style.border_color = Color.WHITE
		btn.add_theme_stylebox_override("focus", focus_style)

		# Rarity label color
		var rarity_name = Rarity.get_rarity_name(item.rarity)
		if rarity_name:
			btn.text = "[%s] %s" % [rarity_name, label_text]

		var captured = item
		btn.pressed.connect(func(): _select_item(captured))

		choices_container.add_child(btn)

	GameManager.pause_game()
	AudioManager.play("item_legendary")

func _get_modifier_text(item: ItemData) -> String:
	var parts: Array[String] = []
	for mod in item.modifiers:
		var stat_name = StatSystem.get_stat_name(mod["stat"])
		var value = mod["value"]
		var mod_type = mod["type"]
		if mod_type == StatSystem.ModType.PERCENT_ADD or mod_type == StatSystem.ModType.PERCENT_MULTIPLY:
			parts.append("%+.0f%% %s" % [value * 100, stat_name])
		else:
			parts.append("%+.0f %s" % [value, stat_name])
	if item.category == ItemData.Category.CURSED:
		for mod in item.curse_modifiers:
			var stat_name = StatSystem.get_stat_name(mod["stat"])
			var value = mod["value"]
			parts.append("CURSE: %+.0f%% %s" % [value * 100, stat_name])
	return ", ".join(parts)

func _select_item(item: ItemData) -> void:
	AudioManager.play("click")
	_refresh_hero()
	if not _hero:
		_hide()
		return
	_hero.add_item(item)
	_hide()

func _hide() -> void:
	panel.visible = false
	GameManager.resume_game()
	_process_next_pending()

func _process_next_pending() -> void:
	if _pending_bosses.size() > 0:
		var next_wave = _pending_bosses.pop_front()
		call_deferred("_show_reward", next_wave)
