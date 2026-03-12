extends CanvasLayer
## Main gameplay HUD — health, XP, wave, kills, streak.

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var wave_label: Label = $WaveLabel
@onready var kill_label: Label = $KillLabel
@onready var streak_label: Label = $StreakLabel
@onready var wave_timer_label: Label = $WaveTimerLabel

var _kill_count: int = 0

func _ready() -> void:
	GameEvents.hero_health_changed.connect(_update_health)
	GameEvents.xp_changed.connect(_update_xp)
	GameEvents.level_up.connect(_update_level)
	GameEvents.wave_started.connect(_update_wave)
	GameEvents.enemy_killed.connect(func(_e): _kill_count += 1; kill_label.text = str(_kill_count))
	GameEvents.kill_streak_changed.connect(_update_streak)
	GameEvents.game_started.connect(_reset)

func _reset() -> void:
	_kill_count = 0
	kill_label.text = "0"
	streak_label.visible = false
	wave_timer_label.visible = false

func _process(_delta: float) -> void:
	var wave_mgr = get_tree().current_scene.get_node_or_null("WaveManager")
	if wave_mgr and wave_mgr.is_break:
		wave_timer_label.visible = true
		wave_timer_label.text = "Next wave in %.1fs" % wave_mgr.wave_timer
	else:
		wave_timer_label.visible = false

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
		var t = clampf(float(streak - 5) / 25.0, 0.0, 1.0)
		streak_label.modulate = Color.YELLOW.lerp(Color.RED, t)
	else:
		streak_label.visible = false
