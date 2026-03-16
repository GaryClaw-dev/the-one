extends CanvasLayer
## Evolution UI shown at levels 15, 25, 35, and 50.
## Branching system: player picks between 2 evolution options.

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/Title
@onready var info_label: Label = $Panel/VBoxContainer/Info
@onready var confirm_btn: Button = $Panel/VBoxContainer/ConfirmBtn

# Branching evolution points keyed by "{current_class}_{level}"
const EVOLUTION_POINTS = {
	# ── Tier 2 (Lv 15): Slingshot → Archer or Crossbow ──────────────
	"slingshot_15": {
		"from_class": "slingshot",
		"level": 15,
		"options": [
			{
				"key": "archer",
				"name": "Archer",
				"description": "Precision marksman — fewer shots, harder hits, aimed crits",
				"color": Color.CYAN,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.12, "label": "+12% ATK Speed"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.08, "label": "+8% Crit Chance"},
					{"stat": StatSystem.StatType.PROJECTILE_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Proj Speed"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
				],
				"passives": ["Aimed Shot: Every 5th attack = crit + pierce", "Wind Guidance: Projectiles home toward enemies", "Precision Surge: Every 10s, 3 shots deal 3x damage"],
			},
			{
				"key": "crossbow",
				"name": "Crossbow",
				"description": "Mechanical bolts — accurate, hard-hitting, cone spread",
				"color": Color.STEEL_BLUE,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% ATK Damage"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Pierce"},
					{"stat": StatSystem.StatType.PROJECTILE_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Proj Speed"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.1, "label": "+10% Max HP"},
				],
				"passives": ["Bolt Spread: 30° cone fire pattern", "Heavy Bolts: Bolts deal bonus damage on first hit"],
			},
		]
	},
	# ── Tier 4 (Lv 25): Archer → Ranger or Windwalker ───────────────
	"archer_25": {
		"from_class": "archer",
		"level": 25,
		"options": [
			{
				"key": "ranger",
				"name": "Ranger",
				"description": "Nature's ally — poison arrows and wolf companion",
				"color": Color.FOREST_GREEN,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.10, "label": "+10% Crit Chance"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
					{"stat": StatSystem.StatType.HEALTH_REGEN, "type": StatSystem.ModType.FLAT, "value": 2.0, "label": "+2 HP Regen"},
				],
				"passives": ["Wolf Companion: Wolf hunts enemies for 60% damage", "Poison Coat: All shots apply poison DoT"],
			},
			{
				"key": "windwalker",
				"name": "Windwalker",
				"description": "Wind reader — homing arrows guided by the wind",
				"color": Color.LIGHT_SKY_BLUE,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.PROJECTILE_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Proj Speed"},
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.10, "label": "+10% ATK Speed"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.08, "label": "+8% Crit Chance"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
				],
				"passives": ["Tailwind: Arrows aggressively home toward enemies", "Slipstream: Periodic evasion dodge"],
			},
		]
	},
	# ── Tier 3 (Lv 25): Crossbow → Repeater or Stormcaller ──────────
	"crossbow_25": {
		"from_class": "crossbow",
		"level": 25,
		"options": [
			{
				"key": "repeater",
				"name": "Repeater",
				"description": "Rapid-fire barrage — many fast projectiles, suppressive volume",
				"color": Color.ORANGE_RED,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% ATK Speed"},
					{"stat": StatSystem.StatType.PROJECTILE_COUNT, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Projectile"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
				],
				"passives": ["Rapid Volley: Every 4th volley fires +50% bolts", "Suppressive Fire: Hits slow enemies slightly", "Explosive Bolts: 25% chance AoE on hit"],
			},
			{
				"key": "stormcaller",
				"name": "Stormcaller",
				"description": "Thunderstrike — lightning-infused bolts that chain between enemies",
				"color": Color.YELLOW,
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% ATK Speed"},
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% ATK Damage"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
				],
				"passives": ["Chain Lightning: All hits chain to 2 nearby enemies", "Static Charge: Every 10th hit triggers sky bolt (300% damage)"],
			},
		]
	},
	# ── Tier 5 (Lv 35): Ranger → Beastlord or Phantom ───────────────
	"ranger_35": {
		"from_class": "ranger",
		"level": 35,
		"options": [
			{
				"key": "beastlord",
				"name": "Beastlord",
				"description": "Alpha of the Wild — command a wolf army",
				"color": Color("8B6914"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.1, "label": "+10% ATK Damage"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.12, "label": "+12% Crit Chance"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 2.0, "label": "+2 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% Max HP"},
					{"stat": StatSystem.StatType.HEALTH_REGEN, "type": StatSystem.ModType.FLAT, "value": 3.0, "label": "+3 HP Regen"},
				],
				"passives": ["Pack Instinct: Start with 3 wolves", "Predator's Mark: Wolves deal 2x to marked targets", "Nature's Fury: Wolf kills trigger pack frenzy"],
			},
			{
				"key": "phantom",
				"name": "Phantom",
				"description": "The Unseen — vanish on kill, strike from shadows",
				"color": Color("4A0080"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.4, "label": "+40% ATK Damage"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.12, "label": "+12% Crit Chance"},
					{"stat": StatSystem.StatType.CRIT_MULTIPLIER, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.3, "label": "+30% Crit Damage"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Max HP"},
				],
				"passives": ["Shadow Strike: 2.4x damage + crit from stealth", "Toxin Mastery: Poison DoT doubled", "Vanish: Kills grant 1s invisibility"],
			},
		]
	},
	# ── Tier 5 (Lv 35): Windwalker → Tempest or Spirit Archer ───────
	"windwalker_35": {
		"from_class": "windwalker",
		"level": 35,
		"options": [
			{
				"key": "tempest",
				"name": "Tempest",
				"description": "Eye of the Storm — tornado attacks pull and shred enemies",
				"color": Color("00CED1"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% ATK Damage"},
					{"stat": StatSystem.StatType.AOE_RADIUS, "type": StatSystem.ModType.FLAT, "value": 30.0, "label": "+30 AoE Radius"},
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.12, "label": "+12% ATK Speed"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
				],
				"passives": ["Vortex: Impacts create pull zones", "Cyclone Shield: Tornado orbits hero", "Updraft: Pulled enemies take +50% damage"],
			},
			{
				"key": "spirit_archer",
				"name": "Spirit Archer",
				"description": "The Channeler — ghost arrows pierce everything, spirit hawks dive-bomb",
				"color": Color("E0E0FF"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% ATK Damage"},
					{"stat": StatSystem.StatType.PROJECTILE_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% Proj Speed"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
				],
				"passives": ["Ethereal Arrows: High pierce (80% damage each)", "Spirit Hawk: Every 5s, hawk deals 200% damage", "Resonance: Each enemy hit boosts next by 10%"],
			},
		]
	},
	# ── Tier 4 (Lv 35): Repeater → Gunslinger or Siege Master ───────
	"repeater_35": {
		"from_class": "repeater",
		"level": 35,
		"options": [
			{
				"key": "gunslinger",
				"name": "Gunslinger",
				"description": "Lead Rain — dual-fire bullet hell fills the screen",
				"color": Color("FFD700"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.45, "label": "+45% ATK Speed"},
					{"stat": StatSystem.StatType.PROJECTILE_COUNT, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Projectile"},
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": -0.3, "label": "-30% ATK Damage"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
				],
				"passives": ["Bullet Time: 50% chance to attack twice", "Spray and Pray: 20% chance to split on hit", "Hot Streak: Every 10th hit = guaranteed crit"],
			},
			{
				"key": "siege_master",
				"name": "Siege Master",
				"description": "Walking Artillery — explosive bolts leave fire zones",
				"color": Color("FF4500"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": -0.4, "label": "-40% ATK Speed"},
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.8, "label": "+80% ATK Damage"},
					{"stat": StatSystem.StatType.AOE_RADIUS, "type": StatSystem.ModType.FLAT, "value": 60.0, "label": "+60 AoE Radius"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% Max HP"},
				],
				"passives": ["Payload: All shots explode on impact", "Scorched Earth: Explosions leave 3s fire zones", "Concussive Force: Explosions push + 40% slow"],
			},
		]
	},
	# ── Tier 5 (Lv 35): Stormcaller → Thunderlord or Demon Hunter ───
	"stormcaller_35": {
		"from_class": "stormcaller",
		"level": 35,
		"options": [
			{
				"key": "thunderlord",
				"name": "Thunderlord",
				"description": "The Storm Caller — massive chain lightning and sky strikes",
				"color": Color("FFFF00"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% ATK Damage"},
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.25, "label": "+25% ATK Speed"},
					{"stat": StatSystem.StatType.PROJECTILE_PIERCE, "type": StatSystem.ModType.FLAT, "value": 1.0, "label": "+1 Pierce"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
				],
				"passives": ["Overcharge: Chains to 4 enemies (80% chain damage)", "Thunderstrike: Every 5th attack calls sky bolt (500%)", "Storm Surge: Kills boost chain damage 10% for 5s"],
			},
			{
				"key": "demon_hunter",
				"name": "Demon Hunter",
				"description": "The Cursed One — dark arrows curse enemies, power grows as HP drops",
				"color": Color("8B0000"),
				"stat_bonuses": [
					{"stat": StatSystem.StatType.ATTACK_DAMAGE, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.35, "label": "+35% ATK Damage"},
					{"stat": StatSystem.StatType.ATTACK_SPEED, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.15, "label": "+15% ATK Speed"},
					{"stat": StatSystem.StatType.CRIT_CHANCE, "type": StatSystem.ModType.FLAT, "value": 0.12, "label": "+12% Crit Chance"},
					{"stat": StatSystem.StatType.MAX_HEALTH, "type": StatSystem.ModType.PERCENT_ADD, "value": 0.2, "label": "+20% Max HP"},
					{"stat": StatSystem.StatType.LIFESTEAL, "type": StatSystem.ModType.FLAT, "value": 0.03, "label": "+3% Lifesteal"},
				],
				"passives": ["Curse: All hits make enemies take +30% damage", "Blood Price: 3% lifesteal on hit", "Desperation: Below 50% HP = +50% dmg, below 25% = +100% + crits"],
			},
		]
	},
}

# Tier lookup: which tier does each evolution key grant?
const TIER_FOR_CLASS = {
	"archer": 2, "crossbow": 2,
	"ranger": 3, "windwalker": 3, "repeater": 3, "stormcaller": 3,
	"beastlord": 4, "phantom": 4, "tempest": 4, "spirit_archer": 4,
	"gunslinger": 4, "siege_master": 4, "thunderlord": 4, "demon_hunter": 4,
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
	}

func _ready() -> void:
	panel.visible = false
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	# Hide the old single-option nodes — we build UI dynamically now
	info_label.visible = false
	confirm_btn.visible = false

	# Style the panel background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.95, 0.85, 0.4, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(16)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)

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
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Clear previous dynamic UI
	if _choices_container and is_instance_valid(_choices_container):
		_choices_container.queue_free()
		_choices_container = null

	# Build side-by-side choice panels
	_choices_container = HBoxContainer.new()
	_choices_container.process_mode = Node.PROCESS_MODE_ALWAYS
	_choices_container.add_theme_constant_override("separation", 16)
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
	btn.custom_minimum_size = Vector2(280, 400)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var color: Color = option.color

	# Normal style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color, 0.1)
	style.border_color = Color(color, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(14)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(color, 0.25)
	hover_style.border_color = color
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(color, 0.4)
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
		portrait_rect.custom_minimum_size = Vector2(72, 72)
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		portrait_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(portrait_rect)

	# Class name
	var name_lbl = Label.new()
	name_lbl.text = option.name
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", color)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = option.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.7))
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
	stats_lbl.add_theme_font_size_override("font_size", 12)
	stats_lbl.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
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
	passives_lbl.add_theme_font_size_override("font_size", 11)
	passives_lbl.add_theme_color_override("font_color", Color(0.7, 0.6, 0.9))
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
	_dimmer.color = Color(0, 0, 0, 0.7)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dimmer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_dimmer)
	move_child(_dimmer, 0)

func _hide_dimmer() -> void:
	if _dimmer:
		_dimmer.queue_free()
		_dimmer = null
