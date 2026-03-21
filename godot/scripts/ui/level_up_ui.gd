extends CanvasLayer
## Level-up choice panel. Shows 3 random abilities to pick from.
## Pauses game, big clickable/tappable buttons for mobile.

@onready var panel: PanelContainer = $Panel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/Choices

var _hero: HeroBase = null
var _pending_levels: Array[int] = []
var _dimmer: ColorRect = null
var _title_label: Label = null

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

	# Style the panel background
	panel.add_theme_stylebox_override("panel", UIConst.make_panel_style())

	# Add a title label above choices
	_title_label = $Panel/VBoxContainer.get_node_or_null("TitleLabel")
	if not _title_label:
		_title_label = Label.new()
		_title_label.name = "TitleLabel"
		$Panel/VBoxContainer.add_child(_title_label)
		$Panel/VBoxContainer.move_child(_title_label, 0)
	_title_label.text = "LEVEL UP"
	_title_label.add_theme_font_size_override("font_size", UIConst.FONT_TITLE)
	_title_label.add_theme_color_override("font_color", UIConst.GOLD)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.visible = false

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

	# Check for evolution at levels 15, 25, 35, and 50 (data-driven branching)
	if new_level in [15, 25, 35, 50]:
		var hero_class = _hero.get_meta("hero_class", "noob")
		var evo_tier = _hero.get_meta("hero_evolution_tier", 1)
		var expected_tier: int
		match new_level:
			15: expected_tier = 2
			25: expected_tier = 3
			35: expected_tier = 4
			50: expected_tier = 5
			_: expected_tier = 2
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

	# Show dimmer + panel
	_show_dimmer()
	panel.visible = true
	if _title_label:
		_title_label.visible = true
		_title_label.text = "LEVEL UP"

	# Animate panel entrance
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.25)

	# Create choice buttons — big, touch-friendly, with icons
	for i in abilities.size():
		var ability = abilities[i]
		var btn = Button.new()
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.custom_minimum_size = UIConst.CHOICE_BTN_SIZE

		var current_level = _hero.get_ability_level(ability)
		var new_level = current_level + 1

		var name_text = ability.ability_name
		if current_level > 0:
			name_text += "  Lv.%d" % new_level
		var desc = ""
		if ability is ArcherAbilityData:
			desc = ability.get_description_for_level(new_level)
		else:
			desc = ability.description

		# Rarity tag and category tag
		var rarity_color = Rarity.get_color(ability.rarity)
		var rarity_name = Rarity.get_rarity_name(ability.rarity)
		var category_name = ""
		match ability.ability_category:
			AbilityData.AbilityCategory.OFFENSIVE: category_name = "OFF"
			AbilityData.AbilityCategory.DEFENSIVE: category_name = "DEF"
			AbilityData.AbilityCategory.UTILITY: category_name = "UTL"
		var style = UIConst.make_card_style(rarity_color)
		UIConst.apply_rarity_glow(style, ability.rarity, rarity_color)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", UIConst.make_hover_style(rarity_color))
		btn.add_theme_stylebox_override("pressed", UIConst.make_pressed_style(rarity_color))

		var focus_style = style.duplicate()
		focus_style.border_color = Color.WHITE
		btn.add_theme_stylebox_override("focus", focus_style)

		# HBox: icon + text
		var hbox = HBoxContainer.new()
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_theme_constant_override("separation", 14)
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		if ability.icon:
			var icon_rect = TextureRect.new()
			icon_rect.texture = ability.icon
			icon_rect.custom_minimum_size = UIConst.ICON_ABILITY
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon_rect)

		var text_vbox = VBoxContainer.new()
		text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_vbox.add_theme_constant_override("separation", 4)

		# Top row: name + rarity/category tags
		var top_hbox = HBoxContainer.new()
		top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_hbox.add_theme_constant_override("separation", 8)

		var name_lbl = Label.new()
		name_lbl.text = name_text
		name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_ABILITY_NAME)
		name_lbl.add_theme_color_override("font_color", rarity_color)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top_hbox.add_child(name_lbl)

		# Rarity tag (skip for Common to reduce clutter)
		if ability.rarity != Rarity.Type.COMMON:
			var rarity_lbl = Label.new()
			rarity_lbl.text = rarity_name.to_upper()
			rarity_lbl.add_theme_font_size_override("font_size", 12)
			rarity_lbl.add_theme_color_override("font_color", Color(rarity_color, 0.8))
			rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rarity_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			top_hbox.add_child(rarity_lbl)

		# Category tag
		if category_name:
			var cat_lbl = Label.new()
			cat_lbl.text = category_name
			cat_lbl.add_theme_font_size_override("font_size", 12)
			cat_lbl.add_theme_color_override("font_color", UIConst.TEXT_TERTIARY)
			cat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			top_hbox.add_child(cat_lbl)

		text_vbox.add_child(top_hbox)

		if desc:
			var desc_lbl = Label.new()
			desc_lbl.text = desc
			desc_lbl.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
			desc_lbl.add_theme_color_override("font_color", UIConst.TEXT_SECONDARY)
			desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
			desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_vbox.add_child(desc_lbl)

		hbox.add_child(text_vbox)
		btn.add_child(hbox)

		var captured = ability
		btn.pressed.connect(func(): _select_ability(captured))

		choices_container.add_child(btn)

		# Staggered entrance animation + press feedback
		UIConst.animate_entrance(btn, get_tree(), i * 0.06)
		UIConst.add_press_feedback(btn, get_tree())

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
	if _title_label:
		_title_label.visible = false
	_hide_dimmer()
	GameManager.resume_game()
	# Process next queued level-up if any
	if _pending_levels.size() > 0:
		var next_level = _pending_levels.pop_front()
		call_deferred("_show_level_up", next_level)

func _show_dimmer() -> void:
	if _dimmer:
		return
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = UIConst.DIMMER_COLOR
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)
	move_child(_dimmer, 0)
	UIConst.animate_dimmer(_dimmer, get_tree())

func _hide_dimmer() -> void:
	if _dimmer:
		_dimmer.queue_free()
		_dimmer = null
