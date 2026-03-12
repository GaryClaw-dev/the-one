extends CanvasLayer
## Level-up choice panel. Shows 3 random abilities to pick from.
## Pauses game, big clickable/tappable buttons for mobile.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices

var _hero: HeroBase = null
var _pending_levels: Array[int] = []

func _ready() -> void:
	panel.visible = false
	# Ensure panel processes input during pause
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.level_up.connect(_on_level_up)
	GameEvents.class_selected.connect(_on_class_selected)
	GameEvents.hero_evolved.connect(_on_hero_evolved)
	GameEvents.game_started.connect(func():
		_refresh_hero()
		_pending_levels.clear()
	)

func _on_level_up(new_level: int) -> void:
	_refresh_hero()
	if not _hero:
		return

	# Show class selection at level 5
	if new_level == 5 and _hero.get_meta("class_selected", false) == false:
		var class_selection_ui = get_node_or_null("/root/ClassSelectionUI")
		if class_selection_ui:
			class_selection_ui.show_class_selection()
		return

	# Check for evolution at levels 15 and 25 (data-driven branching)
	if new_level in [15, 25]:
		var hero_class = _hero.get_meta("hero_class", "noob")
		var evo_tier = _hero.get_meta("hero_evolution_tier", 1)
		var expected_tier = 2 if new_level == 15 else 3
		if evo_tier < expected_tier:
			var evo_key = hero_class + "_" + str(new_level)
			var evo_ui = get_tree().current_scene.get_node_or_null("EvolutionUI")
			if evo_ui and evo_ui.has_evolution_point(evo_key):
				evo_ui.show_evolution(evo_key)
				return

	# If another UI is open (class selection, boss reward, evolution), queue for later
	var class_ui = get_node_or_null("/root/ClassSelectionUI")
	if class_ui and class_ui.panel.visible:
		_pending_levels.append(new_level)
		return
	var boss_ui = get_tree().current_scene.get_node_or_null("BossRewardUI")
	if boss_ui and boss_ui.get("panel") and boss_ui.panel.visible:
		_pending_levels.append(new_level)
		return
	var evo_ui = get_tree().current_scene.get_node_or_null("EvolutionUI")
	if evo_ui and evo_ui.get("panel") and evo_ui.panel.visible:
		_pending_levels.append(new_level)
		return

	_show_level_up(new_level)

func _on_class_selected(_class_key: String, _class_info: Dictionary) -> void:
	# Process any level-ups that were queued during class selection
	_refresh_hero()
	if _pending_levels.size() > 0:
		var next_level = _pending_levels.pop_front()
		# Use call_deferred so the class swap finishes first
		call_deferred("_show_level_up", next_level)

func _on_hero_evolved(_new_class: String) -> void:
	# Process any level-ups that were queued during evolution
	_refresh_hero()
	if _pending_levels.size() > 0:
		var next_level = _pending_levels.pop_front()
		call_deferred("_show_level_up", next_level)

func _show_level_up(level: int) -> void:
	_refresh_hero()
	if not _hero:
		return
	var abilities = ItemDatabase.get_random_abilities(3, _hero)
	if abilities.is_empty():
		return
	_show_choices(abilities)

func _refresh_hero() -> void:
	# Always use GameManager.active_hero — group lookup can return a
	# queue_free'd node that hasn't been removed from the tree yet.
	_hero = GameManager.active_hero as HeroBase

func _show_choices(abilities: Array[AbilityData]) -> void:
	# Clear old choices first
	for child in choices_container.get_children():
		child.queue_free()

	# Show panel BEFORE pausing so it's part of the scene
	panel.visible = true

	# Create choice buttons — big, touch-friendly, with icons
	for ability in abilities:
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.custom_minimum_size = Vector2(500, 100)

		var current_level = _hero.get_ability_level(ability)
		var new_level = current_level + 1

		var name_text = ability.ability_name
		if current_level > 0:
			name_text += " (Lv.%d)" % new_level
		var desc = ""
		if ability is ArcherAbilityData:
			desc = ability.get_description_for_level(new_level)
		else:
			desc = ability.description

		# Color by rarity
		var rarity_color = Rarity.get_color(ability.rarity)
		var style = StyleBoxFlat.new()
		style.bg_color = Color(rarity_color, 0.25)
		style.border_color = rarity_color
		style.set_border_width_all(3)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(12)
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

		# HBox: icon + text
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 12)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		if ability.icon:
			var icon_rect = TextureRect.new()
			icon_rect.texture = ability.icon
			icon_rect.custom_minimum_size = Vector2(64, 64)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon_rect)

		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 2)

		var name_lbl = Label.new()
		name_lbl.text = name_text
		name_lbl.add_theme_font_size_override("font_size", 20)
		name_lbl.add_theme_color_override("font_color", rarity_color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(name_lbl)

		if desc:
			var desc_lbl = Label.new()
			desc_lbl.text = desc
			desc_lbl.add_theme_font_size_override("font_size", 16)
			desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_vbox.add_child(desc_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)

		var captured = ability
		btn.pressed.connect(func(): _select_ability(captured))

		choices_container.add_child(btn)

	# Now pause the game (after UI is fully built)
	GameManager.pause_game()

func _select_ability(ability: AbilityData) -> void:
	AudioManager.play("click")
	_refresh_hero()
	if not _hero:
		_hide()
		return
	_hero.add_ability(ability)
	_hide()

func _hide() -> void:
	panel.visible = false
	GameManager.resume_game()
	# Process next queued level-up if any
	if _pending_levels.size() > 0:
		var next_level = _pending_levels.pop_front()
		call_deferred("_show_level_up", next_level)
