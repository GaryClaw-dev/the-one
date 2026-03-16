extends CanvasLayer
## Boss reward panel. Shows 3 random items to pick from after defeating a boss.
## Pauses game, big clickable/tappable buttons for mobile.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices
@onready var title_label: Label = $Panel/VBoxContainer/Title

var _hero: HeroBase = null
var _pending_bosses: Array[int] = []  # wave numbers queued
var _dimmer: ColorRect = null

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	GameEvents.game_started.connect(func():
		_pending_bosses.clear()
	)

	# Style the panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.95, 0.85, 0.4, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style the title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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

	title_label.text = "BOSS DEFEATED"
	_show_choices(items)

func _refresh_hero() -> void:
	_hero = GameManager.active_hero as HeroBase

func _show_choices(items: Array[ItemData]) -> void:
	for child in choices_container.get_children():
		child.queue_free()

	# Show dimmer + panel
	_show_dimmer()
	panel.visible = true

	# Subtitle — "Choose a reward"
	var subtitle = Label.new()
	subtitle.text = "Choose a reward"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.55))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices_container.add_child(subtitle)

	for item in items:
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.custom_minimum_size = Vector2(520, 110)

		# Color by rarity
		var rarity_color = Rarity.get_color(item.rarity)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(rarity_color, 0.12)
		style.border_color = Color(rarity_color, 0.7)
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.set_content_margin_all(12)
		btn.add_theme_stylebox_override("normal", style)

		var hover_style = style.duplicate()
		hover_style.bg_color = Color(rarity_color, 0.3)
		hover_style.border_color = rarity_color
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style = style.duplicate()
		pressed_style.bg_color = Color(rarity_color, 0.45)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var focus_style = style.duplicate()
		focus_style.border_color = Color.WHITE
		btn.add_theme_stylebox_override("focus", focus_style)

		# Structured layout: icon + text columns
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 14)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		# Item icon
		if item.get("icon") and item.icon:
			var icon_rect = TextureRect.new()
			icon_rect.texture = item.icon
			icon_rect.custom_minimum_size = Vector2(56, 56)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon_rect)

		# Text column
		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 3)

		# Item name with rarity tag
		var rarity_name = Rarity.get_rarity_name(item.rarity)
		var name_lbl = Label.new()
		if rarity_name:
			name_lbl.text = "[%s]  %s" % [rarity_name, item.item_name]
		else:
			name_lbl.text = item.item_name
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_color_override("font_color", rarity_color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)

		# Description
		if item.description:
			var desc_lbl = Label.new()
			desc_lbl.text = item.description
			desc_lbl.add_theme_font_size_override("font_size", 13)
			desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_vbox.add_child(desc_lbl)

		# Stat modifiers
		var mod_text = _get_modifier_text(item)
		if mod_text:
			var mod_lbl = Label.new()
			mod_lbl.text = mod_text
			mod_lbl.add_theme_font_size_override("font_size", 12)
			mod_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
			mod_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_vbox.add_child(mod_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)

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
	return "  |  ".join(parts)

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
	_hide_dimmer()
	GameManager.resume_game()
	_process_next_pending()

func _process_next_pending() -> void:
	if _pending_bosses.size() > 0:
		var next_wave = _pending_bosses.pop_front()
		call_deferred("_show_reward", next_wave)

func _show_dimmer() -> void:
	if _dimmer:
		return
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0, 0, 0, 0.7)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)
	move_child(_dimmer, 0)

func _hide_dimmer() -> void:
	if _dimmer:
		_dimmer.queue_free()
		_dimmer = null
