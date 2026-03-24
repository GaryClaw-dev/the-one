extends Node
## Controls wave progression, enemy spawning, and difficulty scaling.

var enemy_datas: Array[EnemyData] = []
var boss_datas: Array[EnemyData] = []

@export_group("Spawning")
@export var base_spawn_interval: float = 0.5
@export var min_spawn_interval: float = 0.08
@export var base_enemies_per_wave: int = 3
@export var enemies_per_wave_scale: float = 1.2
@export var break_between_waves: float = 0.0

var current_wave: int = 0
var wave_timer: float = 0.0
var is_break: bool = false

var _enemies_spawned: int = 0
var _enemies_to_spawn: int = 0
var _enemies_alive: int = 0
var _spawn_timer: float = 0.0
var _active: bool = false
var _hero: Node2D
var _enemy_first_appearances: Dictionary = {}
var _war_drummer_data: EnemyData
var _pending_boss: bool = false

func _ready() -> void:
	_load_enemy_data()
	GameEvents.game_started.connect(_start_waves)
	GameEvents.enemy_killed.connect(_on_enemy_died)

func _load_enemy_data() -> void:
	# Preload instead of DirAccess — DirAccess can't list files in exported .pck
	var paths := [
		"res://resources/enemies/bat.tres",
		"res://resources/enemies/goblin.tres",
		"res://resources/enemies/skeleton.tres",
		"res://resources/enemies/dark_mage.tres",
		"res://resources/enemies/goblin_chief.tres",
		"res://resources/enemies/skeleton_king.tres",
		"res://resources/enemies/bat_queen.tres",
		"res://resources/enemies/troll_warlord.tres",
		"res://resources/enemies/necromancer.tres",
	]
	for path in paths:
		var data = load(path)
		if data is EnemyData:
			if data.is_boss:
				boss_datas.append(data)
			else:
				enemy_datas.append(data)
	_war_drummer_data = load("res://resources/enemies/war_drummer.tres")
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

	# Boss spawns last, after all regular enemies are out
	if _pending_boss and _enemies_spawned >= _enemies_to_spawn:
		_pending_boss = false
		_spawn_boss()

	if _enemies_spawned >= _enemies_to_spawn and not _pending_boss and _enemies_alive <= 0:
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
	_spawn_timer = 0.2

	GameEvents.wave_started.emit(current_wave)

	# War drummer spawns first thing, wave 15+
	if current_wave >= 15 and _war_drummer_data:
		_spawn_war_drummer()

	# Boss spawns after all regular enemies — flag it for later
	_pending_boss = current_wave % 10 == 0 and boss_datas.size() > 0

func _complete_wave() -> void:
	GameEvents.wave_completed.emit(current_wave)
	# Milestone fanfare at waves 25, 50, 75, 100, ...
	if current_wave > 0 and current_wave % 25 == 0:
		GameEvents.wave_milestone.emit(current_wave)
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
		enemy.initialize(data, current_wave, GameManager.active_hero)

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
	boss.global_position = _get_spawn_position_top_bottom()

	if boss.has_method("initialize"):
		boss.initialize(data, current_wave, GameManager.active_hero)

	_enemies_alive += 1
	GameEvents.boss_spawned.emit(boss)

func _pick_enemy_for_wave() -> EnemyData:
	if enemy_datas.is_empty():
		return null
	# Introduce new enemy types every 3 waves instead of 5
	var pool_size = mini(1 + current_wave / 3, enemy_datas.size())
	return enemy_datas[randi() % pool_size]

func is_first_enemy_appearance(enemy_data: EnemyData, wave: int) -> bool:
	var enemy_id = enemy_data.enemy_name
	if not _enemy_first_appearances.has(enemy_id):
		_enemy_first_appearances[enemy_id] = wave
		return true
	return false

func _get_enemy_count() -> int:
	# Two phases: linear early, accelerating late. Cap at 60.
	# ~50% more enemies than before, but XP per enemy is reduced to compensate.
	var count: int
	if current_wave <= 20:
		count = mini(roundi(base_enemies_per_wave + enemies_per_wave_scale * 1.5 * (current_wave - 1)), 38)
	else:
		var base_at_20 = roundi(base_enemies_per_wave + enemies_per_wave_scale * 1.5 * 19)
		count = mini(roundi(base_at_20 + 2.0 * (current_wave - 20)), 60)
	# Boss waves: halve adds to focus on the boss fight
	if current_wave % 10 == 0:
		count = count / 2
	return count

func _get_spawn_interval() -> float:
	# Slower early (time to react), faster late
	# After wave 30, tighten further with a lower floor
	if current_wave > 30:
		return maxf(0.08 - (current_wave - 30) * 0.002, 0.03)
	return maxf(base_spawn_interval - (current_wave * 0.02), min_spawn_interval)

func _get_spawn_position() -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var cam = get_viewport().get_camera_2d()
	var zoom = cam.zoom if cam else Vector2.ONE
	var margin = 40.0

	var half_w = viewport.x / (2.0 * zoom.x) + margin
	var half_h = viewport.y / (2.0 * zoom.y) + margin

	var cam_pos = cam.global_position if cam else Vector2.ZERO

	var edge = randi() % 4
	var pos: Vector2
	match edge:
		0: pos = Vector2(randf_range(-half_w, half_w), -half_h)
		1: pos = Vector2(randf_range(-half_w, half_w), half_h)
		2: pos = Vector2(-half_w, randf_range(-half_h, half_h))
		_: pos = Vector2(half_w, randf_range(-half_h, half_h))

	return cam_pos + pos

func _on_enemy_died(enemy: Node2D) -> void:
	if enemy.get("is_fodder"):
		return
	_enemies_alive = maxi(0, _enemies_alive - 1)

func _get_spawn_position_top_bottom() -> Vector2:
	var viewport = get_viewport().get_visible_rect().size
	var cam = get_viewport().get_camera_2d()
	var zoom = cam.zoom if cam else Vector2.ONE
	var margin = 40.0
	var half_w = viewport.x / (2.0 * zoom.x) + margin
	var half_h = viewport.y / (2.0 * zoom.y) + margin
	var cam_pos = cam.global_position if cam else Vector2.ZERO
	var top = randi() % 2 == 0
	var pos: Vector2
	if top:
		pos = Vector2(randf_range(-half_w, half_w), -half_h)
	else:
		pos = Vector2(randf_range(-half_w, half_w), half_h)
	return cam_pos + pos

func _spawn_war_drummer() -> void:
	var scene = load("res://scenes/war_drummer.tscn")
	for i in range(2):
		var drummer = scene.instantiate()
		get_tree().current_scene.add_child(drummer)
		drummer.global_position = _get_spawn_position_top_bottom()
		if drummer.has_method("initialize"):
			drummer.initialize(_war_drummer_data, current_wave, GameManager.active_hero)
		_enemies_alive += 1

func stop_waves() -> void:
	_active = false
