extends CanvasLayer
## Main gameplay HUD — health, XP, wave, kills, streak, stats, items.
## Laid out for portrait (720x1280) mobile screen.

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var wave_label: Label = $WaveLabel
@onready var kill_label: Label = $KillLabel
@onready var streak_label: Label = $StreakLabel
@onready var wave_timer_label: Label = $WaveTimerLabel

var _kill_count: int = 0
var _stat_labels: Dictionary = {}
var _items_grid: GridContainer = null
var _item_counts: Dictionary = {}  # item_name -> { "count": int, "label": Label, "rarity": int }
var _hero_ref: HeroBase = null
var _class_label: Label = null

const STATS_TO_SHOW = [
	[StatSystem.StatType.ARMOR, "ARM"],
	[StatSystem.StatType.ATTACK_DAMAGE, "ATK"],
	[StatSystem.StatType.COOLDOWN_REDUCTION, "CDR"],
	[StatSystem.StatType.CRIT_CHANCE, "CRIT%"],
	[StatSystem.StatType.CRIT_MULTIPLIER, "CRITx"],
	[StatSystem.StatType.DAMAGE_REDUCTION, "DMG RED"],
	[StatSystem.StatType.KNOCKBACK_FORCE, "KNOCKBK"],
	[StatSystem.StatType.LIFESTEAL, "STEAL"],
	[StatSystem.StatType.LUCK, "LUCK"],
	[StatSystem.StatType.PROJECTILE_SPEED, "P.SPD"],
	[StatSystem.StatType.PROJECTILE_PIERCE, "PIERCE"],
	[StatSystem.StatType.PROJECTILE_COUNT, "PROJ"],
	[StatSystem.StatType.HEALTH_REGEN, "REGEN"],
	[StatSystem.StatType.ATTACK_SPEED, "SPD"],
	[StatSystem.StatType.THORNS, "THORNS"],
	[StatSystem.StatType.XP_MULTIPLIER, "XP MULT"],
]

func _ready() -> void:
	GameEvents.hero_health_changed.connect(_update_health)
	GameEvents.xp_changed.connect(_update_xp)
	GameEvents.level_up.connect(_update_level)
	GameEvents.wave_started.connect(_update_wave)
	GameEvents.enemy_killed.connect(func(_e): _kill_count += 1; kill_label.text = "Kills: %d" % _kill_count)
	GameEvents.kill_streak_changed.connect(_update_streak)
	GameEvents.game_started.connect(_reset)
	GameEvents.item_acquired.connect(_on_item_acquired)
	GameEvents.hero_evolved.connect(_on_hero_evolved)
	GameEvents.class_selected.connect(_on_class_selected)
	GameEvents.wave_milestone.connect(_show_milestone)

	# Style top HUD labels
	level_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_LEVEL)
	level_label.add_theme_color_override("font_color", UIConst.GOLD)
	wave_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_WAVE)
	wave_label.add_theme_color_override("font_color", UIConst.TEXT_PRIMARY)
	kill_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_KILL)
	kill_label.add_theme_color_override("font_color", UIConst.TEXT_TERTIARY)
	wave_timer_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_WAVE)
	wave_timer_label.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))

	_build_class_label()
	_build_stats_panel()
	_build_items_panel()

func _reset() -> void:
	_kill_count = 0
	kill_label.text = "Kills: 0"
	streak_label.visible = false
	wave_timer_label.visible = false
	_hero_ref = null
	if _class_label:
		_class_label.text = ""
	# Clear items list
	_item_counts.clear()
	if _items_grid:
		for child in _items_grid.get_children():
			child.queue_free()

func _process(_delta: float) -> void:
	var wave_mgr = get_tree().current_scene.get_node_or_null("WaveManager")
	if wave_mgr and wave_mgr.is_break:
		wave_timer_label.visible = true
		wave_timer_label.text = "Next wave in %.1fs" % wave_mgr.wave_timer
	else:
		wave_timer_label.visible = false

	# Bind to hero stats once available (or rebind if hero was swapped)
	if _hero_ref == null or not is_instance_valid(_hero_ref):
		_hero_ref = null
		var hero = get_tree().get_first_node_in_group("hero")
		if hero and hero is HeroBase:
			_hero_ref = hero
			if not _hero_ref.stats.stat_changed.is_connected(_on_stat_changed):
				_hero_ref.stats.stat_changed.connect(_on_stat_changed)
			_refresh_all_stats()
			_update_class_display()

func _update_health(current: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = "%d/%d" % [ceili(current), ceili(max_hp)]

	var ratio = current / max_hp if max_hp > 0 else 0.0
	if ratio > 0.6:
		health_bar.modulate = Color(0.2, 0.8, 0.2)
	elif ratio > 0.3:
		health_bar.modulate = Color(0.9, 0.8, 0.1)
	else:
		health_bar.modulate = Color(0.9, 0.2, 0.2)

func _update_xp(current: float, required: float) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func _update_level(new_level: int) -> void:
	level_label.text = "Lv.%d" % new_level

func _update_wave(wave: int) -> void:
	wave_label.text = "Wave %d" % wave

func _update_streak(streak: int) -> void:
	if streak >= 5:
		streak_label.visible = true
		streak_label.text = "x%d STREAK!" % streak
		streak_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_STREAK)
		var t = clampf(float(streak - 5) / 25.0, 0.0, 1.0)
		streak_label.modulate = Color.YELLOW.lerp(Color.RED, t)
	else:
		streak_label.visible = false

# ---- Class Label ----

func _build_class_label() -> void:
	_class_label = Label.new()
	_class_label.text = ""
	_class_label.add_theme_font_size_override("font_size", UIConst.FONT_HUD_CLASS)
	_class_label.add_theme_color_override("font_color", UIConst.GOLD)
	_class_label.position = Vector2(10, 45)
	add_child(_class_label)

func _update_class_display() -> void:
	if not _class_label:
		return
	if not _hero_ref:
		_class_label.text = ""
		return
	var class_name_str: String = _hero_ref.get_meta("hero_class", "")
	var tier: int = _hero_ref.get_meta("hero_evolution_tier", 1)
	var display_name = class_name_str.capitalize() if class_name_str != "" else "Hero"
	var tier_colors = {
		1: Color(0.7, 0.7, 0.7),   # Starter — grey
		2: Color(0.3, 0.75, 1.0),  # Tier 2 — blue
		3: Color(1.0, 0.6, 0.2),   # Tier 3 — orange
		4: Color(0.85, 0.5, 1.0),  # Tier 4 — purple
	}
	_class_label.text = display_name
	_class_label.add_theme_color_override("font_color", tier_colors.get(tier, Color.WHITE))

func _on_hero_evolved(new_class: String) -> void:
	_rebind_hero()
	_update_class_display()

func _on_class_selected(_class_key: String, _class_info: Dictionary) -> void:
	# Hero node was swapped — force rebind on next frame
	_hero_ref = null

func _rebind_hero() -> void:
	var hero = GameManager.active_hero as HeroBase
	if hero and hero != _hero_ref:
		_hero_ref = hero
		if not _hero_ref.stats.stat_changed.is_connected(_on_stat_changed):
			_hero_ref.stats.stat_changed.connect(_on_stat_changed)
		_refresh_all_stats()
		_update_class_display()

# ---- Stats Panel ----

func _build_stats_panel() -> void:
	var stats_panel = PanelContainer.new()
	stats_panel.position = Vector2(10, 1030)
	stats_panel.custom_minimum_size = Vector2(340, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = UIConst.BG_ELEVATED
	style.border_color = UIConst.GOLD_DIM
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	stats_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var title = Label.new()
	title.text = "STATS"
	title.add_theme_font_size_override("font_size", UIConst.FONT_HUD_PANEL_TITLE)
	title.add_theme_color_override("font_color", UIConst.GOLD)
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)

	for entry in STATS_TO_SHOW:
		var name_lbl = Label.new()
		name_lbl.text = entry[1]
		name_lbl.add_theme_font_size_override("font_size", UIConst.FONT_HUD_STAT_NAME)
		name_lbl.add_theme_color_override("font_color", UIConst.TEXT_TERTIARY)
		grid.add_child(name_lbl)

		var val_lbl = Label.new()
		val_lbl.text = "-"
		val_lbl.add_theme_font_size_override("font_size", UIConst.FONT_HUD_STAT_VAL)
		val_lbl.add_theme_color_override("font_color", UIConst.TEXT_PRIMARY)
		val_lbl.custom_minimum_size.x = 48
		grid.add_child(val_lbl)
		_stat_labels[entry[0]] = val_lbl

	vbox.add_child(grid)
	stats_panel.add_child(vbox)
	add_child(stats_panel)

func _refresh_all_stats() -> void:
	if not _hero_ref:
		return
	for entry in STATS_TO_SHOW:
		var stat_type: int = entry[0]
		var value = _hero_ref.stats.get_stat(stat_type)
		_update_stat_label(stat_type, value)

func _on_stat_changed(stat_type: int, new_value: float) -> void:
	_update_stat_label(stat_type, new_value)

func _update_stat_label(stat_type: int, value: float) -> void:
	if not _stat_labels.has(stat_type):
		return
	var lbl: Label = _stat_labels[stat_type]
	match stat_type:
		StatSystem.StatType.CRIT_CHANCE:
			lbl.text = "%.0f%%" % (value * 100.0)
		StatSystem.StatType.CRIT_MULTIPLIER:
			lbl.text = "%.1fx" % value
		StatSystem.StatType.ATTACK_SPEED:
			lbl.text = "%.2f" % value
		StatSystem.StatType.HEALTH_REGEN:
			lbl.text = "%.1f" % value
		StatSystem.StatType.LIFESTEAL:
			lbl.text = "%.0f%%" % (value * 100.0)
		StatSystem.StatType.COOLDOWN_REDUCTION:
			lbl.text = "%.0f%%" % (value * 100.0)
		StatSystem.StatType.DAMAGE_REDUCTION:
			lbl.text = "%.0f%%" % (value * 100.0)
		StatSystem.StatType.LUCK:
			lbl.text = "%.0f" % value
		StatSystem.StatType.XP_MULTIPLIER:
			lbl.text = "%.1fx" % value
		_:
			lbl.text = "%.0f" % value

# ---- Items Panel (2-column with counts) ----

func _build_items_panel() -> void:
	var items_panel = PanelContainer.new()
	items_panel.position = Vector2(370, 1030)
	items_panel.custom_minimum_size = Vector2(340, 0)

	var style = StyleBoxFlat.new()
	style.bg_color = UIConst.BG_ELEVATED
	style.border_color = UIConst.GOLD_DIM
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	items_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var title = Label.new()
	title.text = "ITEMS"
	title.add_theme_font_size_override("font_size", UIConst.FONT_HUD_PANEL_TITLE)
	title.add_theme_color_override("font_color", UIConst.GOLD)
	vbox.add_child(title)

	_items_grid = GridContainer.new()
	_items_grid.columns = 2
	_items_grid.add_theme_constant_override("h_separation", 8)
	_items_grid.add_theme_constant_override("v_separation", 2)
	vbox.add_child(_items_grid)

	items_panel.add_child(vbox)
	add_child(items_panel)

func _on_item_acquired(item: Resource) -> void:
	if not _items_grid:
		return
	var iname: String = item.item_name if item.get("item_name") else "Item"
	var irarity: int = item.rarity if item.get("rarity") != null else 0

	if _item_counts.has(iname):
		# Increment count and update label
		_item_counts[iname]["count"] += 1
		var lbl: Label = _item_counts[iname]["label"]
		var count: int = _item_counts[iname]["count"]
		lbl.text = "%s x%d" % [iname, count]
	else:
		# New item entry — HBox with optional small icon + label
		var rarity_color = Rarity.get_color(irarity)
		var entry_hbox = HBoxContainer.new()
		entry_hbox.add_theme_constant_override("separation", 4)
		entry_hbox.custom_minimum_size.x = 155

		if item.get("icon") and item.icon:
			var icon_tex = TextureRect.new()
			icon_tex.texture = item.icon
			icon_tex.custom_minimum_size = Vector2(16, 16)
			icon_tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			entry_hbox.add_child(icon_tex)

		var lbl = Label.new()
		lbl.text = iname
		lbl.add_theme_font_size_override("font_size", UIConst.FONT_HUD_ITEM)
		lbl.add_theme_color_override("font_color", rarity_color)
		lbl.clip_text = true
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry_hbox.add_child(lbl)

		_items_grid.add_child(entry_hbox)
		_item_counts[iname] = { "count": 1, "label": lbl, "rarity": irarity }

# ---- Wave Milestone Banner ----

func _show_milestone(wave: int) -> void:
	var banner = Label.new()
	banner.text = "WAVE %d" % wave
	banner.add_theme_font_size_override("font_size", 48)
	banner.add_theme_color_override("font_color", UIConst.GOLD)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 200
	banner.modulate = Color(1, 1, 1, 0)
	add_child(banner)

	var tween = banner.create_tween()
	# Fade in + scale up
	banner.scale = Vector2(0.5, 0.5)
	banner.pivot_offset = banner.size * 0.5
	tween.set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.3)
	tween.tween_property(banner, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	# Hold
	tween.tween_interval(1.5)
	# Fade out
	tween.tween_property(banner, "modulate:a", 0.0, 0.5)
	tween.tween_callback(banner.queue_free)
