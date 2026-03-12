extends CanvasLayer
## Evolution UI shown at levels 15 and 25.
## Branching system: player picks between 2 evolution options.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var info_label: Label = $Panel/VBoxContainer/Info
@onready var confirm_btn: Button = $Panel/VBoxContainer/ConfirmBtn

# Branching evolution points keyed by "{current_class}_{level}"
const EVOLUTION_POINTS = {
	"slingshot_15": {
		"from_class": "slingshot",
		"level": 15,
		"options": [
			{
				"key": "archer",
				"name": "Archer",
				"description": "Precision marksman with burst potential",
				"color": Color.CYAN,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% ATK Speed"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.10, "label": "+10% Crit Chance"},
					{"stat": StatSystem.StatType.PROJECTILE_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.3, "label": "+30% Proj Speed"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
				],
				"passives": ["Aimed Shot: Every 5th attack = crit + pierce", "Wind Guidance: Projectiles home toward enemies", "Precision Surge: Every 10s, 3 shots deal 3x damage"],
			},
			{
				"key": "thrower",
				"name": "Thrower",
				"description": "Raw power AoE specialist hurling boulders",
				"color": Color("8B4513"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.4, "label": "+40% ATK Damage"},
					{"stat": StatSystem.StatType.AOE_RADIUS, "type": StatSystem.ModType.FLAT, "value": 60.0, "label": "+60 AoE Radius"},
					{"stat": StatSystem.StatType.KNOCKBACK_FORCE, "type": StatSystem.ModType.FLAT, "value": 80.0, "label": "+80 Knockback"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.35, "label": "+35% Max HP"},
				],
				"passives": ["Boulder Toss: Attacks deal AoE splash", "Earthshaker: AoE kills push enemies outward", "Crushing Impact: AoE hits slow enemies 30%"],
			},
		]
	},
	"archer_25": {
		"from_class": "archer",
		"level": 25,
		"options": [
			{
				"key": "ranger",
				"name": "Ranger",
				"description": "Nature's ally with poison and wolf companions",
				"color": Color.FOREST_GREEN,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.15, "label": "+15% Crit Chance"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 2.0, "label": "+2 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% Max HP"},
					{"stat": StatSystem.StatType.HEALTH_REGEN, "type": StatSystem.ModType.FLAT, "value": 3.0, "label": "+3 HP Regen"},
				],
				"passives": ["Wolf Companion: Wolf attacks enemies every 3s", "Poison Coat: All shots apply poison DoT"],
			},
			{
				"key": "crossbow",
				"name": "Crossbow",
				"description": "Heavy repeating crossbow with mechanical gadgets",
				"color": Color.STEEL_BLUE,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.5, "label": "+50% ATK Speed"},
					{"stat": StatSystem.StatType.PROJECTILE_COUNT, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Projectile"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.3, "label": "+30% Max HP"},
				],
				"passives": ["Bolt Spread: Attacks fire in a 30° cone", "Explosive Bolts: 25% chance for AoE on hit", "Rapid Reload: Every 15s, triple ATK speed for 3s"],
			},
		]
	},
	"thrower_25": {
		"from_class": "thrower",
		"level": 25,
		"options": [
			{
				"key": "lumberjack",
				"name": "Lumberjack",
				"description": "Throws ENTIRE TREES that shatter into splinters",
				"color": Color.DARK_OLIVE_GREEN,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.6, "label": "+60% ATK Damage"},
					{"stat": StatSystem.StatType.AOE_RADIUS, "type": StatSystem.ModType.FLAT, "value": 40.0, "label": "+40 AoE Radius"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 3.0, "label": "+3 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.4, "label": "+40% Max HP"},
				],
				"passives": ["Splinter Storm: Tree impacts spawn splinter projectiles", "Timber: Trees pierce and hit everything in line"],
			},
			{
				"key": "catapult",
				"name": "Catapult",
				"description": "Human siege engine launching flaming boulders",
				"color": Color.DARK_RED,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.8, "label": "+80% ATK Damage"},
					{"stat": StatSystem.StatType.AOE_RADIUS, "type": StatSystem.ModType.FLAT, "value": 80.0, "label": "+80 AoE Radius"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.5, "label": "+50% Max HP"},
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": -0.3, "label": "-30% ATK Speed"},
				],
				"passives": ["Explosive Impact: 50% chance to explode for 75% AoE", "Scorched Earth: Impacts leave fire zones", "Always Ignites: All boulders apply burn DoT"],
			},
		]
	},
}

# Tier lookup: which tier does each evolution key grant?
const TIER_FOR_CLASS = {
	"archer": 2, "thrower": 2,
	"ranger": 3, "crossbow": 3, "lumberjack": 3, "catapult": 3,
}

var _choices_container: HBoxContainer = null

# Portrait textures for evolution choices
var _portraits: Dictionary = {}

func _load_portraits() -> void:
	_portraits = {
		"archer": load("res://art/heroes/archer/archer.png"),
		"thrower": load("res://art/portraits/thrower_portrait.png"),
		"ranger": load("res://art/portraits/ranger_portrait.png"),
		"crossbow": load("res://art/portraits/crossbow_portrait.png"),
		"lumberjack": load("res://art/portraits/lumberjack_portrait.png"),
		"catapult": load("res://art/portraits/catapult_portrait.png"),
	}

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the old single-option nodes — we build UI dynamically now
	info_label.visible = false
	confirm_btn.visible = false
	_load_portraits()

func has_evolution_point(point_key: String) -> bool:
	return EVOLUTION_POINTS.has(point_key)

func show_evolution(point_key: String) -> void:
	if not EVOLUTION_POINTS.has(point_key):
		return

	var point = EVOLUTION_POINTS[point_key]

	# Title
	title_label.text = "CHOOSE YOUR EVOLUTION!"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Clear previous dynamic UI
	if _choices_container and is_instance_valid(_choices_container):
		_choices_container.queue_free()
		_choices_container = null

	# Build side-by-side choice panels
	_choices_container = HBoxContainer.new()
	_choices_container.process_mode = Node.PROCESS_MODE_ALWAYS
	_choices_container.add_theme_constant_override("separation", 20)
	_choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	$Panel/VBoxContainer.add_child(_choices_container)

	for option in point.options:
		var choice_btn = _build_choice_panel(option)
		_choices_container.add_child(choice_btn)

	panel.visible = true
	GameManager.pause_game()
	AudioManager.play("item_legendary")

func _build_choice_panel(option: Dictionary) -> Button:
	var btn = Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.custom_minimum_size = Vector2(280, 380)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var color: Color = option.color

	# Normal style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color, 0.15)
	style.border_color = Color(color, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(16)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color, 0.35)
	hover_style.border_color = color
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(color, 0.5)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# Content VBox inside button
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)

	# Class name
	var name_lbl = Label.new()
	name_lbl.text = option.name
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Portrait image
	var portrait_key: String = option.key
	if _portraits.has(portrait_key):
		var portrait_rect = TextureRect.new()
		portrait_rect.texture = _portraits[portrait_key]
		portrait_rect.custom_minimum_size = Vector2(80, 80)
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(portrait_rect)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = option.description
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_lbl)

	# Separator
	var sep1 = HSeparator.new()
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep1)

	# Stat bonuses
	var stats_lbl = Label.new()
	var stats_text = ""
	for bonus in option.stat_bonuses:
		stats_text += bonus.label + "\n"
	stats_lbl.text = stats_text.strip_edges()
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_lbl)

	# Separator
	var sep2 = HSeparator.new()
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sep2)

	# Passives
	var passives_lbl = Label.new()
	var passives_text = ""
	for passive in option.passives:
		passives_text += passive + "\n"
	passives_lbl.text = passives_text.strip_edges()
	passives_lbl.add_theme_font_size_override("font_size", 12)
	passives_lbl.add_theme_color_override("font_color", Color(0.8, 0.7, 1.0))
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

	# Update max health / current health after HP bonus
	var new_max = hero.stats.get_stat(StatSystem.StatType.MAX_HEALTH)
	var ratio = hero.current_health / hero.max_health if hero.max_health > 0 else 1.0
	hero.max_health = new_max
	hero.current_health = new_max * ratio
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
		"archer":
			hero.add_special_ability("precision_surge", 1, [[10.0], [3.0]])
		"thrower":
			hero.add_special_ability("earthshaker", 1, [[80.0], [0.3]])
		"ranger":
			hero.add_special_ability("wolf_companion", 1, [[1.0], [3.0]])
			hero.add_special_ability("poison_coat", 1, [[1.0], [5.0]])
		"crossbow":
			hero.add_special_ability("explosive", 1, [[0.25], [0.5]])
			hero.add_special_ability("bullet_storm", 1, [[15.0], [3.0]])
		"lumberjack":
			hero.add_special_ability("splinter_storm", 1, [[5.0], [0.3]])
		"catapult":
			hero.add_special_ability("explosive", 1, [[0.5], [0.75]])
			hero.add_special_ability("scorched_earth", 1, [[3.0], [10.0]])

func _hide() -> void:
	panel.visible = false
	if _choices_container and is_instance_valid(_choices_container):
		_choices_container.queue_free()
		_choices_container = null
	GameManager.resume_game()
