extends CanvasLayer
## Evolution UI shown at levels 15, 25, 35, and 50.
## Branching system: player picks between 2 evolution options.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var info_label: Label = $Panel/VBoxContainer/Info
@onready var confirm_btn: Button = $Panel/VBoxContainer/ConfirmBtn

# Evolution data loaded from .tres resource files
var EVOLUTION_POINTS: Dictionary = {}

# Tier lookup built from loaded data
var TIER_FOR_CLASS: Dictionary = {}

func _load_evolution_data() -> void:
	var paths := [
		"res://resources/heroes/evolutions/slingshot_15.tres",
		"res://resources/heroes/evolutions/archer_25.tres",
		"res://resources/heroes/evolutions/crossbow_25.tres",
		"res://resources/heroes/evolutions/ranger_35.tres",
		"res://resources/heroes/evolutions/windwalker_35.tres",
		"res://resources/heroes/evolutions/repeater_35.tres",
		"res://resources/heroes/evolutions/stormcaller_35.tres",
		# Fighter evolutions
		"res://resources/heroes/evolutions/fighter_15.tres",
		"res://resources/heroes/evolutions/knight_25.tres",
		"res://resources/heroes/evolutions/berserker_25.tres",
	]
	for path in paths:
		var point_data = load(path) as EvolutionPointData
		if not point_data:
			push_warning("Failed to load evolution: " + path)
			continue
		var key = "%s_%d" % [point_data.from_class, point_data.level]
		var options_array: Array = []
		for opt in point_data.options:
			options_array.append({
				"key": opt.key,
				"name": opt.display_name,
				"description": opt.description,
				"color": opt.color,
				"stat_bonuses": opt.stat_bonuses,
				"passives": opt.passives,
			})
			TIER_FOR_CLASS[opt.key] = opt.tier
		EVOLUTION_POINTS[key] = {
			"from_class": point_data.from_class,
			"level": point_data.level,
			"options": options_array,
		}

var _choices_container: HBoxContainer = null
var _dimmer: ColorRect = null

# Portrait textures for evolution choices
var _portraits: Dictionary = {}

func _load_portraits() -> void:
	_portraits = {
		"archer": load("res://art/portraits/archer_portrait.png"),
		"repeater": load("res://art/portraits/repeater_portrait.png"),
		"ranger": load("res://art/portraits/ranger_portrait.png"),
		"windwalker": load("res://art/portraits/windwalker_portrait.png"),
		"crossbow": load("res://art/portraits/crossbow_portrait.png"),
		"stormcaller": load("res://art/portraits/stormcaller_portrait.png"),
		"beastlord": load("res://art/portraits/beastlord_portrait.png"),
		"phantom": load("res://art/portraits/phantom_portrait.png"),
		"tempest": load("res://art/portraits/tempest_portrait.png"),
		"spirit_archer": load("res://art/portraits/spirit_archer_portrait.png"),
		"gunslinger": load("res://art/portraits/gunslinger_portrait.png"),
		"siege_master": load("res://art/portraits/siege_master_portrait.png"),
		"thunderlord": load("res://art/portraits/thunderlord_portrait.png"),
		"demon_hunter": load("res://art/portraits/demon_hunter_portrait.png"),
		# Fighter evolutions
		"knight": load("res://art/portraits/knight_portrait.png") if ResourceLoader.exists("res://art/portraits/knight_portrait.png") else null,
		"berserker": load("res://art/portraits/berserker_portrait.png") if ResourceLoader.exists("res://art/portraits/berserker_portrait.png") else null,
		"paladin": load("res://art/portraits/paladin_portrait.png") if ResourceLoader.exists("res://art/portraits/paladin_portrait.png") else null,
		"guardian": load("res://art/portraits/guardian_portrait.png") if ResourceLoader.exists("res://art/portraits/guardian_portrait.png") else null,
		"blademaster": load("res://art/portraits/blademaster_portrait.png") if ResourceLoader.exists("res://art/portraits/blademaster_portrait.png") else null,
		"warlord": load("res://art/portraits/warlord_portrait.png") if ResourceLoader.exists("res://art/portraits/warlord_portrait.png") else null,
	}

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the old single-option nodes — we build UI dynamically now
	info_label.visible = false
	confirm_btn.visible = false

	# Style the panel background
	panel.add_theme_stylebox_override("panel", UIConst.make_panel_style())

	_load_evolution_data()
	_load_portraits()

func has_evolution_point(point_key: String) -> bool:
	return EVOLUTION_POINTS.has(point_key)

func show_evolution(point_key: String) -> void:
	if not EVOLUTION_POINTS.has(point_key):
		return

	var point = EVOLUTION_POINTS[point_key]

	# Add background dimmer
	_show_dimmer()

	# Title
	title_label.text = "EVOLUTION"
	title_label.add_theme_font_size_override("font_size", UIConst.FONT_TITLE)
	title_label.add_theme_color_override("font_color", UIConst.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Clear previous dynamic UI
	if _choices_container and is_instance_valid(_choices_container):
		_choices_container.queue_free()
		_choices_container = null

	# Build side-by-side choice panels
	_choices_container = HBoxContainer.new()
	_choices_container.process_mode = Node.PROCESS_MODE_ALWAYS
	_choices_container.add_theme_constant_override("separation", UIConst.SPACE_MD)
	_choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	$Panel/VBoxContainer.add_child(_choices_container)

	for i in point.options.size():
		var option = point.options[i]
		var choice_btn = _build_choice_panel(option)
		_choices_container.add_child(choice_btn)
		# Staggered entrance animation + press feedback
		UIConst.animate_entrance(choice_btn, get_tree(), i * 0.08)
		UIConst.add_press_feedback(choice_btn, get_tree())

	panel.visible = true
	UIConst.animate_entrance(panel, get_tree(), 0.0, 0.3)
	GameManager.pause_game()
	AudioManager.play("item_legendary")

func _build_choice_panel(option: Dictionary) -> Button:
	var btn = Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.custom_minimum_size = UIConst.EVO_CARD_SIZE
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var color: Color = option.color

	# Normal style
	var style = UIConst.make_card_style(color)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = UIConst.make_hover_style(color)
	hover_style.set_corner_radius_all(12)
	hover_style.set_content_margin_all(14)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = UIConst.make_pressed_style(color)
	pressed_style.set_corner_radius_all(12)
	pressed_style.set_content_margin_all(14)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# Content VBox inside button
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)

	# Portrait image (above name for visual impact)
	var portrait_key: String = option.key
	if _portraits.has(portrait_key):
		var portrait_rect = TextureRect.new()
		portrait_rect.texture = _portraits[portrait_key]
		portrait_rect.custom_minimum_size = UIConst.ICON_EVO_PORTRAIT
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(portrait_rect)

	# Class name
	var name_lbl = Label.new()
	name_lbl.text = option.name
	name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_EVO_NAME)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = option.description
	desc_lbl.add_theme_font_size_override("font_size", UIConst.FONT_DESC)
	desc_lbl.add_theme_color_override("font_color", UIConst.TEXT_SECONDARY)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	# Separator
	var sep1 = HSeparator.new()
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep1.modulate = Color(color, 0.3)
	vbox.add_child(sep1)

	# Stat bonuses
	var stats_lbl = Label.new()
	var stats_text = ""
	for bonus in option.stat_bonuses:
		stats_text += bonus.label + "\n"
	stats_lbl.text = stats_text.strip_edges()
	stats_lbl.add_theme_font_size_override("font_size", UIConst.FONT_STAT_BONUS)
	stats_lbl.add_theme_color_override("font_color", UIConst.STAT_GREEN)
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_lbl)

	# Separator
	var sep2 = HSeparator.new()
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sep2.modulate = Color(color, 0.3)
	vbox.add_child(sep2)

	# Passives
	var passives_lbl = Label.new()
	var passives_text = ""
	for passive in option.passives:
		passives_text += passive + "\n"
	passives_lbl.text = passives_text.strip_edges()
	passives_lbl.add_theme_font_size_override("font_size", UIConst.FONT_PASSIVE)
	passives_lbl.add_theme_color_override("font_color", UIConst.PASSIVE_PURPLE)
	passives_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	passives_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(passives_lbl)

	btn.add_child(vbox)

	# Connect
	var captured_option = option
	btn.pressed.connect(func(): _on_choice_selected(captured_option))

	return btn

func _on_choice_selected(option: Dictionary) -> void:
	AudioManager.play("click")
	var hero = GameManager.active_hero as HeroBase
	if not hero:
		_hide()
		return

	# Apply stat bonuses as permanent modifiers
	for bonus in option.stat_bonuses:
		hero.stats.add_modifier(bonus.stat, bonus.type, bonus.value, self)

	# Update max health / current health after HP bonus — full heal on evolution
	var new_max = hero.stats.get_stat(StatSystem.StatType.MAX_HEALTH)
	hero.max_health = new_max
	hero.current_health = new_max
	GameEvents.hero_health_changed.emit(hero.current_health, hero.max_health)

	# Update hero class meta
	var evo_key: String = option.key
	hero.set_meta("hero_class", evo_key)
	hero.set_meta("hero_evolution_tier", TIER_FOR_CLASS.get(evo_key, 2))
	var old_branch = hero.get_meta("hero_branch", "slingshot")
	hero.set_meta("hero_branch", old_branch + "." + evo_key)

	# Register evolution passives on the hero
	_apply_evolution_passives(hero, evo_key)

	GameEvents.hero_evolved.emit(evo_key)
	_hide()

func _apply_evolution_passives(hero: HeroBase, evo_key: String) -> void:
	match evo_key:
		# Tier 2
		"archer":
			hero.add_special_ability("precision_surge", 1, [[10.0], [3.0]])
		"crossbow":
			pass  # Crossbow passives are built into the attack pattern
		# Tier 3
		"ranger":
			hero.add_special_ability("wolf_companion", 1, [[1.0], [3.0]])
			hero.add_special_ability("poison_coat", 1, [[1.0], [5.0]])
		"windwalker":
			pass  # Homing is built into the attack pattern
		"repeater":
			hero.add_special_ability("explosive", 1, [[0.25], [0.5]])
			hero.add_special_ability("bullet_storm", 1, [[15.0], [3.0]])
		"stormcaller":
			pass  # Chain lightning is built into the attack pattern
		# Tier 5
		"beastlord":
			# Upgrade wolf companion to 3 wolves, faster interval
			hero.add_special_ability("wolf_companion", 1, [[3.0], [2.0]])
		"phantom":
			# Doubles poison DoT
			if hero.special_abilities.has("poison_coat"):
				var pc = hero.special_abilities["poison_coat"]
				pc["special_values"][0] *= 2.0
		"tempest":
			pass  # Vortex is built into the attack pattern
		"spirit_archer":
			pass  # Ethereal arrows + hawk built into attack pattern
		"gunslinger":
			pass  # Bullet Time built into attack pattern
		"siege_master":
			# Scorched Earth built into attack pattern via _apply_siege_meta
			pass
		"thunderlord":
			pass  # Enhanced chains built into attack pattern
		"demon_hunter":
			pass  # Curse + desperation built into attack pattern
		# ── Fighter evolutions ──
		"knight":
			pass  # Shield Wall is built into fighter.gd _update_special_abilities
		"berserker":
			pass  # Blood Rage + Frenzy built into fighter.gd attack + kill tracking
		"paladin":
			pass  # Holy Aura + Consecrate built into fighter.gd
		"guardian":
			pass  # Fortress + Ironclad built into fighter.gd
		"blademaster":
			pass  # Combo Master built into fighter.gd attack pattern
		"warlord":
			pass  # Execution built into fighter.gd attack pattern

func _hide() -> void:
	panel.visible = false
	if _choices_container and is_instance_valid(_choices_container):
		_choices_container.queue_free()
		_choices_container = null
	_hide_dimmer()
	GameManager.resume_game()

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
