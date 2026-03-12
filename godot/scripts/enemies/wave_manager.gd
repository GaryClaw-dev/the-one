extends Node
## Controls wave progression, enemy spawning, and difficulty scaling.

var enemy_datas: Array[EnemyData] = []
var boss_datas: Array[EnemyData] = []

@export_group("Spawning")
@export var base_spawn_interval: float = 1.5
@export var min_spawn_interval: float = 0.2
@export var base_enemies_per_wave: int = 10
@export var enemies_per_wave_scale: float = 5.0
@export var break_between_waves: float = 3.0

var current_wave: int = 0
var wave_timer: float = 0.0
var is_break: bool = false
var _enemies_spawned: int = 0
var _enemies_to_spawn: int = 0
var _enemies_alive: int = 0
var _spawn_timer: float = 0.0
var _active: bool = false
var _hero: Node2D

func _ready() -> void:
	_load_enemy_data()
	GameEvents.game_started.connect(_start_waves)
	GameEvents.enemy_killed.connect(_on_enemy_died)

func _load_enemy_data() -> void:
	var dir = DirAccess.open("res://resources/enemies/")
	if not dir:
		push_warning("WaveManager: No enemies directory found")
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var data = load("res://resources/enemies/" + file_name)
			if data is EnemyData:
				if data.is_boss:
					boss_datas.append(data)
				else:
					enemy_datas.append(data)
		file_name = dir.get_next()
	print("WaveManager: Loaded %d enemies, %d bosses" % [enemy_datas.size(), boss_datas.size()])

func _process(delta: float) -> void:
	if not _active:
		return
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	if is_break:
		wave_timer -= delta
		if wave_timer <= 0.0:
			_start_next_wave()
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and _enemies_spawned < _enemies_to_spawn:
		_spawn_enemy()
		_spawn_timer = _get_spawn_interval()

	# Wave complete: all spawned and all dead
	if _enemies_spawned >= _enemies_to_spawn and _enemies_alive <= 0:
		_complete_wave()

func _start_waves() -> void:
	current_wave = 0
	_active = true
	_hero = get_tree().get_first_node_in_group("hero")
	_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	is_break = false
	_enemies_to_spawn = _get_enemy_count()
	_enemies_spawned = 0
	_enemies_alive = 0
	_spawn_timer = 0.5

	GameEvents.wave_started.emit(current_wave)

	# Boss every 10 waves
	if current_wave % 10 == 0 and boss_datas.size() > 0:
		_spawn_boss()

func _complete_wave() -> void:
	GameEvents.wave_completed.emit(current_wave)
	is_break = true
	wave_timer = break_between_waves

func _spawn_enemy() -> void:
	if enemy_datas.is_empty():
		return

	var data = _pick_enemy_for_wave()
	if not data:
		return

	var scene: PackedScene = data.scene if data.scene else preload("res://scenes/enemy.tscn")
	if not scene:
		return

	var enemy: Node2D = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _get_spawn_position()

	if enemy.has_method("initialize"):
		enemy.initialize(data, current_wave, _hero)

	_enemies_spawned += 1
	_enemies_alive += 1

func _spawn_boss() -> void:
	if boss_datas.is_empty():
		return

	var idx = mini((current_wave / 10) - 1, boss_datas.size() - 1)
	var data = boss_datas[idx]

	var scene: PackedScene = data.scene if data.scene else preload("res://scenes/enemy.tscn")
	if not scene:
		return

	var boss: Node2D = scene.instantiate()
	get_tree().current_scene.add_child(boss)
	boss.global_position = _get_spawn_position()

	if boss.has_method("initialize"):
		boss.initialize(data, current_wave, _hero)

	_enemies_alive += 1
	GameEvents.boss_spawned.emit(boss)

func _pick_enemy_for_wave() -> EnemyData:
	if enemy_datas.is_empty():
		return null
	# Later waves can access more enemy types
	var pool_size = mini(1 + current_wave / 5, enemy_datas.size())
	return enemy_datas[randi() % pool_size]

func _get_enemy_count() -> int:
	return roundi(base_enemies_per_wave + enemies_per_wave_scale * (current_wave - 1))

func _get_spawn_interval() -> float:
	var interval = base_spawn_interval - (current_wave * 0.05)
	return maxf(interval, min_spawn_interval)

func _get_spawn_position() -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var margin = 50.0
	var half_w = viewport.x / 2.0 + margin
	var half_h = viewport.y / 2.0 + margin

	var cam = get_viewport().get_camera_2d()
	var cam_pos = cam.global_position if cam else Vector2.ZERO

	# Pick a random screen edge
	var edge = randi() % 4
	var pos: Vector2
	match edge:
		0: pos = Vector2(randf_range(-half_w, half_w), -half_h)  # top
		1: pos = Vector2(randf_range(-half_w, half_w), half_h)   # bottom
		2: pos = Vector2(-half_w, randf_range(-half_h, half_h))  # left
		_: pos = Vector2(half_w, randf_range(-half_h, half_h))   # right

	return cam_pos + pos

func _on_enemy_died(_enemy: Node2D) -> void:
	_enemies_alive = maxi(0, _enemies_alive - 1)

func stop_waves() -> void:
	_active = false
