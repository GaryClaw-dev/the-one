extends CharacterBody3D
## 3D hero base. Stationary capsule, auto-attacks nearest enemy.

@export var hero_data: HeroData

var stats: StatSystem = StatSystem.new()
var current_health: float
var max_health: float
var kill_streak: int = 0

var _attack_timer: float = 0.0
var _target: Node3D = null
var _target_timer: float = 0.0
var _kill_streak_timer: float = 0.0
const KILL_STREAK_WINDOW := 2.0
const TARGET_UPDATE_INTERVAL := 0.1
const SCALE_FACTOR: float = 0.1

const ObjectPool = preload("res://scripts/core/object_pool.gd")
var _projectile_pool: Node
var _material: StandardMaterial3D

func _ready() -> void:
	add_to_group("hero")
	if hero_data:
		hero_data.apply_base_stats(stats)

	max_health = stats.get_stat(StatSystem.StatType.MAX_HEALTH)
	current_health = max_health
	GameEvents.hero_health_changed.emit(current_health, max_health)

	stats.stat_changed.connect(_on_stat_changed)
	GameEvents.enemy_killed.connect(_on_enemy_killed)
	tree_exiting.connect(_disconnect_signals)

	# Set hero color (blue-white)
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.3, 0.5, 1.0)
	_material.emission_enabled = true
	_material.emission = Color(0.2, 0.3, 0.6)
	_material.emission_energy_multiplier = 0.5
	var mesh_inst = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst:
		mesh_inst.set_surface_override_material(0, _material)

	# Projectile pool
	var proj_scene = preload("res://scenes/projectile_3d.tscn")
	_projectile_pool = ObjectPool.new()
	_projectile_pool.setup(proj_scene, 80)
	add_child(_projectile_pool)

func _disconnect_signals() -> void:
	if stats and stats.stat_changed.is_connected(_on_stat_changed):
		stats.stat_changed.disconnect(_on_stat_changed)
	if GameEvents.enemy_killed.is_connected(_on_enemy_killed):
		GameEvents.enemy_killed.disconnect(_on_enemy_killed)

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	_update_targeting(delta)
	_update_attack(delta)
	_update_kill_streak(delta)
	_update_health_regen(delta)

func _update_targeting(delta: float) -> void:
	_target_timer -= delta
	if _target_timer > 0.0:
		return
	_target_timer = TARGET_UPDATE_INTERVAL
	_target = _find_nearest_enemy()

func _update_attack(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer > 0.0 or _target == null:
		return
	if not is_instance_valid(_target):
		_target = null
		return
	var attack_speed = minf(stats.get_stat(StatSystem.StatType.ATTACK_SPEED), 8.0)
	var interval = 1.0 / maxf(attack_speed, 0.1)
	_attack_timer = maxf(interval, 0.125)
	perform_attack(_target)

func _update_kill_streak(delta: float) -> void:
	if kill_streak <= 0:
		return
	_kill_streak_timer -= delta
	if _kill_streak_timer <= 0.0:
		kill_streak = 0
		GameEvents.kill_streak_changed.emit(0)

func _update_health_regen(delta: float) -> void:
	var regen = stats.get_stat(StatSystem.StatType.HEALTH_REGEN)
	if regen > 0.0:
		heal(regen * delta)

## Override in subclass
func perform_attack(_target_node: Node3D) -> void:
	pass

func fire_projectile(direction: Vector3, damage_mult: float = 1.0, target_node: Node3D = null) -> Node:
	var proj = _projectile_pool.acquire()
	proj.reset_for_reuse()
	proj._pool = _projectile_pool
	proj.global_position = global_position + Vector3(0, 1.0, 0)

	var damage = stats.get_stat(StatSystem.StatType.ATTACK_DAMAGE) * damage_mult
	var crit_chance = stats.get_stat(StatSystem.StatType.CRIT_CHANCE)
	var crit_mult = stats.get_stat(StatSystem.StatType.CRIT_MULTIPLIER)
	var speed = stats.get_stat(StatSystem.StatType.PROJECTILE_SPEED) * SCALE_FACTOR
	var pierce = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_PIERCE))
	var knockback = stats.get_stat(StatSystem.StatType.KNOCKBACK_FORCE) * SCALE_FACTOR
	var lifesteal = stats.get_stat(StatSystem.StatType.LIFESTEAL)

	proj.initialize(direction, speed, damage, crit_chance, crit_mult, pierce, true)
	proj._knockback = knockback
	proj._lifesteal = lifesteal

	if target_node:
		proj.enable_homing(target_node)

	return proj

func take_damage(amount: float, _is_crit: bool = false, _attacker: Node = null) -> float:
	var armor = stats.get_stat(StatSystem.StatType.ARMOR)
	var reduction = stats.get_stat(StatSystem.StatType.DAMAGE_REDUCTION)
	var final_dmg = amount / (1.0 + armor * 0.01) * (1.0 - reduction)
	current_health -= final_dmg
	GameEvents.hero_health_changed.emit(current_health, max_health)
	# Damage flash
	if _material:
		var old_color = _material.albedo_color
		_material.albedo_color = Color.RED
		var tween = create_tween()
		tween.tween_property(_material, "albedo_color", Color(0.3, 0.5, 1.0), 0.15)
	if current_health <= 0.0:
		_die()
	return final_dmg

func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	GameEvents.hero_health_changed.emit(current_health, max_health)

func _die() -> void:
	GameEvents.game_over.emit()

func _find_nearest_enemy() -> Node3D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node3D = null
	var nearest_dist = INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _on_stat_changed(stat_type: int, _new_value: float) -> void:
	if stat_type == StatSystem.StatType.MAX_HEALTH:
		max_health = stats.get_stat(StatSystem.StatType.MAX_HEALTH)
		current_health = minf(current_health, max_health)
		GameEvents.hero_health_changed.emit(current_health, max_health)

func _on_enemy_killed(_enemy: Node) -> void:
	kill_streak += 1
	_kill_streak_timer = KILL_STREAK_WINDOW
	GameEvents.kill_streak_changed.emit(kill_streak)
