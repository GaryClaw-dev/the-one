extends "res://scripts/enemies/enemy_base.gd"
## War Drummer — tanky summoner that stops at range and spawns fodder warriors.
## Plays a looping dembow drum rhythm. Fodder spawn on the big beat.
## Fodder die when the drummer dies. Fodder grant no XP.

var _fodder: Array = []
var _in_position: bool = false
var _fodder_data: EnemyData

const STOP_RANGE := 400.0
const MAX_FODDER := 10
const FODDER_PER_BEAT := 5

# Dembow rhythm pattern — [time, sound, is_spawn_beat]
# ~100 BPM, 3.5s cycle. kick-hat-hat-snare bounce.
const RHYTHM := [
	# Measure 1
	[0.00, "drum_kick", false],
	[0.15, "drum_hat", false],
	[0.30, "drum_hat", false],
	[0.48, "drum_snare", false],
	[0.60, "drum_kick", false],
	[0.75, "drum_hat", false],
	[0.90, "drum_hat", false],
	[1.08, "drum_snare", false],
	# Measure 2
	[1.20, "drum_kick", false],
	[1.35, "drum_hat", false],
	[1.50, "drum_hat", false],
	[1.68, "drum_snare", false],
	[1.80, "drum_kick", false],
	[1.95, "drum_hat", false],
	[2.10, "drum_hat", false],
	[2.28, "drum_snare", false],
	# Measure 3 — BIG BEAT drops here, spawn fodder
	[2.40, "drum_kick", true],
	[2.55, "drum_hat", false],
	[2.70, "drum_hat", false],
	[2.88, "drum_snare", false],
	[3.00, "drum_kick", false],
	[3.15, "drum_hat", false],
	[3.30, "drum_hat", false],
]
const DRUM_INTERVAL := 3.5

var _rhythm_idx: int = 0
var _cycle_time: float = 0.0
var _drumming: bool = false

func initialize(enemy_data: EnemyData, wave: int, hero: Node2D) -> void:
	super.initialize(enemy_data, wave, hero)
	_fodder_data = load("res://resources/enemies/fodder_warrior.tres")
	_in_position = false
	_fodder.clear()
	_drumming = false
	_rhythm_idx = 0
	_cycle_time = 0.0

func _spawner_update(speed: float, _delta: float) -> void:
	if not _hero or not is_instance_valid(_hero):
		return

	var dist = global_position.distance_to(_hero.global_position)

	if not _in_position:
		# Stop when within visible screen area (with margin)
		var viewport = get_viewport().get_visible_rect().size
		var cam = get_viewport().get_camera_2d()
		var zoom = cam.zoom if cam else Vector2.ONE
		var half_w = viewport.x / (2.0 * zoom.x) - 60.0
		var half_h = viewport.y / (2.0 * zoom.y) - 60.0
		var cam_pos = cam.global_position if cam else Vector2.ZERO
		var rel = global_position - cam_pos
		var on_screen = absf(rel.x) < half_w and absf(rel.y) < half_h

		if on_screen and dist <= STOP_RANGE:
			_in_position = true
			velocity = Vector2.ZERO
			_drumming = true
			_cycle_time = 0.0
			_rhythm_idx = 0
		else:
			_move_toward_hero(speed, _delta)
	else:
		velocity = Vector2.ZERO
		if _drumming:
			_update_rhythm(_delta)

func _update_rhythm(delta: float) -> void:
	_cycle_time += delta

	while _rhythm_idx < RHYTHM.size():
		var beat_time: float = RHYTHM[_rhythm_idx][0]
		var sound: String = RHYTHM[_rhythm_idx][1]
		var is_spawn: bool = RHYTHM[_rhythm_idx][2]

		if _cycle_time >= beat_time:
			_play_beat(sound, is_spawn)
			_rhythm_idx += 1
		else:
			break

	# Cycle complete — loop
	if _cycle_time >= DRUM_INTERVAL:
		_cycle_time -= DRUM_INTERVAL
		_rhythm_idx = 0

func _play_beat(sound: String, is_spawn: bool) -> void:
	var sprite = $Sprite2D as Sprite2D

	if is_spawn:
		# BIG beat — loud kick + big pulse + spawn
		AudioManager.play(sound, 2.0)
		if sprite:
			var base_scale = sprite.scale
			var tween = create_tween()
			tween.tween_property(sprite, "scale", base_scale * 1.3, 0.1)
			tween.tween_property(sprite, "scale", base_scale, 0.2)
		_spawn_fodder()
	elif sound == "drum_kick":
		# Regular kick — medium volume + subtle pulse
		AudioManager.play(sound, -2.0)
		if sprite:
			var base_scale = sprite.scale
			var tween = create_tween()
			tween.tween_property(sprite, "scale", base_scale * 1.1, 0.05)
			tween.tween_property(sprite, "scale", base_scale, 0.1)
	elif sound == "drum_snare":
		AudioManager.play(sound, -4.0)
	else:
		# Hi-hat — quiet
		AudioManager.play(sound, -8.0)

func _spawn_fodder() -> void:
	_fodder = _fodder.filter(func(f): return is_instance_valid(f) and not f.is_dead())

	var to_spawn = mini(FODDER_PER_BEAT, MAX_FODDER - _fodder.size())
	if to_spawn <= 0:
		return

	var dir_to_hero = (_hero.global_position - global_position).normalized()
	var spawn_center = global_position + dir_to_hero * 80.0

	for i in range(to_spawn):
		var scene = preload("res://scenes/enemy.tscn")
		var fodder = scene.instantiate()
		get_tree().current_scene.add_child(fodder)

		var offset = Vector2(randf_range(-90, 90), randf_range(-90, 90))
		fodder.global_position = spawn_center + offset

		if fodder.has_method("initialize"):
			fodder.initialize(_fodder_data, _wave, _hero)
		fodder.is_fodder = true

		_fodder.append(fodder)
		fodder.tree_exiting.connect(_on_fodder_removed.bind(fodder))

func _on_fodder_removed(fodder: Node2D) -> void:
	_fodder.erase(fodder)

func _die() -> void:
	_drumming = false
	for f in _fodder.duplicate():
		if is_instance_valid(f) and not f.is_dead():
			f._die()
	_fodder.clear()
	super._die()
