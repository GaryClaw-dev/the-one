extends Node
## 3D wave manager. Spawns 3D enemies around the play area.

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
var _hero: Node
var _enemy_first_appearances: Dictionary = {}
var _pending_boss: bool = false

const SPAWN_RADIUS: float = 35.0

func _ready() -> void:
	_load_enemy_data()
	GameEvents.game_started.connect(_start_waves)
	GameEvents.enemy_killed.connect(_on_enemy_died)

func _load_enemy_data() -> void:
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
	print("WaveManager3D: Loaded %d enemies, %d bosses" % [enemy_datas.size(), boss_datas.size()])

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

	if _pending_boss and _enemies_spawned >= _enemies_to_spawn:
		_pending_boss = false
		_spawn_boss()

	if _enemies_spawned >= _enemies_to_spawn and not _pending_boss and _enemies_alive <= 0:
		_complete_wave()

func _start_waves() -> void:
	current_wave = 0
	_active = true
	_hero = GameManager.active_hero
	_start_next_wave()

func _start_next_wave() -> void:
	current_wave += 1
	is_break = false
	_enemies_to_spawn = _get_enemy_count()
	_enemies_spawned = 0
	_enemies_alive = 0
	_spawn_timer = 0.2
	GameEvents.wave_started.emit(current_wave)
	_pending_boss = current_wave % 10 == 0 and boss_datas.size() > 0

func _complete_wave() -> void:
	GameEvents.wave_completed.emit(current_wave)
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
	var scene = preload("res://scenes/enemy_3d.tscn")
	var enemy = scene.instantiate()
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
	var scene = preload("res://scenes/enemy_3d.tscn")
	var boss = scene.instantiate()
	get_tree().current_scene.add_child(boss)
	boss.global_position = _get_spawn_position()
	if boss.has_method("initialize"):
		boss.initialize(data, current_wave, GameManager.active_hero)
	_enemies_alive += 1
	GameEvents.boss_spawned.emit(boss)

func _pick_enemy_for_wave() -> EnemyData:
	if enemy_datas.is_empty():
		return null
	var pool_size = mini(1 + current_wave / 3, enemy_datas.size())
	return enemy_datas[randi() % pool_size]

func is_first_enemy_appearance(enemy_data: EnemyData, wave: int) -> bool:
	var enemy_id = enemy_data.enemy_name
	if not _enemy_first_appearances.has(enemy_id):
		_enemy_first_appearances[enemy_id] = wave
		return true
	return false

func _get_enemy_count() -> int:
	var count: int
	if current_wave <= 20:
		count = mini(roundi(base_enemies_per_wave + enemies_per_wave_scale * 1.5 * (current_wave - 1)), 38)
	else:
		var base_at_20 = roundi(base_enemies_per_wave + enemies_per_wave_scale * 1.5 * 19)
		count = mini(roundi(base_at_20 + 2.0 * (current_wave - 20)), 60)
	if current_wave % 10 == 0:
		count = count / 2
	return count

func _get_spawn_interval() -> float:
	if current_wave > 30:
		return maxf(0.08 - (current_wave - 30) * 0.002, 0.03)
	return maxf(base_spawn_interval - (current_wave * 0.02), min_spawn_interval)

func _get_spawn_position() -> Vector3:
	# Spawn at random point on a circle around origin
	var angle = randf() * TAU
	var radius = SPAWN_RADIUS + randf_range(0, 5)
	return Vector3(cos(angle) * radius, 0, sin(angle) * radius)

func _on_enemy_died(enemy: Node) -> void:
	if enemy.get("is_fodder"):
		return
	_enemies_alive = maxi(0, _enemies_alive - 1)

func stop_waves() -> void:
	_active = false
