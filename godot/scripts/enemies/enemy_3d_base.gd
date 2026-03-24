extends CharacterBody3D
## 3D enemy base. Colored capsule that moves toward hero on XZ plane.

@export var data: EnemyData

const SCALE_FACTOR: float = 0.1  # 2D pixels to 3D units

var _health: float
var _max_health: float
var _wave: int
var _hero: Node
var _attack_cooldown: float = 0.0
var _dead: bool = false
var _base_color: Color = Color.WHITE
var is_fodder: bool = false
var _alive_time: float = 0.0
var _material: StandardMaterial3D

func _ready() -> void:
	add_to_group("enemies")

func initialize(enemy_data: EnemyData, wave: int, hero: Node) -> void:
	data = enemy_data
	_wave = wave
	_hero = hero
	_dead = false
	_attack_cooldown = 0.0
	_alive_time = 0.0

	_max_health = data.get_scaled_hp(wave)
	_health = _max_health

	# Set color from enemy data
	_base_color = data.color
	_material = StandardMaterial3D.new()
	_material.albedo_color = data.color
	var mesh_inst = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_inst:
		mesh_inst.set_surface_override_material(0, _material)

	# Scale based on type
	if data.is_boss:
		scale = Vector3(2.0, 2.0, 2.0)
	elif data.is_mini_boss:
		scale = Vector3(1.5, 1.5, 1.5)
	else:
		scale = Vector3(1.0, 1.0, 1.0)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if not _hero or not is_instance_valid(_hero):
		_hero = GameManager.active_hero
		if not _hero:
			return

	_alive_time += delta
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	var hero_pos: Vector3
	if _hero is Node3D:
		hero_pos = (_hero as Node3D).global_position
	else:
		return

	var speed = data.get_scaled_speed(_wave) * SCALE_FACTOR
	var dir = hero_pos - global_position
	dir.y = 0
	var dist = dir.length()

	match data.behavior:
		EnemyData.Behavior.RUSH, EnemyData.Behavior.CHARGE:
			var spd_mult = 1.5 if data.behavior == EnemyData.Behavior.CHARGE else 1.0
			if dist > 0.1:
				velocity = dir.normalized() * speed * spd_mult
			else:
				velocity = Vector3.ZERO
		EnemyData.Behavior.RANGED:
			if dist > data.attack_range * SCALE_FACTOR * 3.0:
				velocity = dir.normalized() * speed
			else:
				velocity = Vector3.ZERO
		EnemyData.Behavior.SPAWNER:
			if dist > data.attack_range * SCALE_FACTOR * 4.0:
				velocity = dir.normalized() * speed
			elif dist < data.attack_range * SCALE_FACTOR * 2.0:
				velocity = -dir.normalized() * speed
			else:
				velocity = Vector3.ZERO
		_:
			if dist > 0.1:
				velocity = dir.normalized() * speed
			else:
				velocity = Vector3.ZERO

	move_and_slide()

	# Face toward hero
	if dist > 0.1:
		var look_target = global_position + dir.normalized()
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)

	# Attack
	var post_dist = (hero_pos - global_position).length()
	var attack_range_3d = data.attack_range * SCALE_FACTOR
	if data.behavior == EnemyData.Behavior.RANGED or data.behavior == EnemyData.Behavior.SPAWNER:
		if post_dist <= attack_range_3d * 3.0:
			_try_ranged_attack(hero_pos)
	elif post_dist <= attack_range_3d:
		_try_attack()

func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown
	if _hero.has_method("take_damage"):
		var scaled_damage = data.get_scaled_damage(_wave)
		_hero.take_damage(scaled_damage, false, self)

func _try_ranged_attack(hero_pos: Vector3) -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown

	var projectile_scene = preload("res://scenes/projectile_3d.tscn")
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0, 1, 0)

	var dir = (hero_pos - global_position).normalized()
	var scaled_damage = data.get_scaled_damage(_wave)
	proj.initialize(dir, 20.0, scaled_damage, 0.0, 1.0, 0, false)

func take_damage(amount: float, _is_crit: bool = false, _attacker: Node = null) -> float:
	if _dead:
		return 0.0
	_health -= amount
	_show_damage_flash()
	if _health <= 0.0:
		_die()
	return amount

func is_dead() -> bool:
	return _dead

func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	GameEvents.enemy_killed.emit(self)
	if data and data.is_boss:
		GameEvents.boss_defeated.emit(self)
	_drop_xp()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(queue_free)

func _drop_xp() -> void:
	if is_fodder and data.xp_value <= 0.0:
		return
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager3D")
	var is_first = false
	if wave_manager and wave_manager.has_method("is_first_enemy_appearance"):
		is_first = wave_manager.is_first_enemy_appearance(data, _wave)
	var xp_scene = preload("res://scenes/xp_orb_3d.tscn")
	var xp = xp_scene.instantiate()
	xp.global_position = global_position + Vector3(randf_range(-2, 2), 0.5, randf_range(-2, 2))
	xp.initialize(data.get_scaled_xp(_wave, is_first))
	get_tree().current_scene.add_child.call_deferred(xp)

func _show_damage_flash() -> void:
	if _material:
		_material.albedo_color = Color.RED
		var tween = create_tween()
		tween.tween_property(_material, "albedo_color", _base_color, 0.1)

func get_health_ratio() -> float:
	return _health / _max_health if _max_health > 0 else 0.0

# Status effect stubs for compatibility with projectile ability system
func apply_burn(_dps: float, _duration: float) -> void: pass
func apply_poison(_dps: float, _duration: float) -> void: pass
func apply_slow(_pct: float, _duration: float) -> void: pass
func apply_bleed(_dps: float, _duration: float) -> void: pass
func apply_armor_shred(_pct: float, _duration: float) -> void: pass
func apply_knockback(_force: Vector3) -> void: pass
func apply_curse(_pct: float, _duration: float) -> void: pass
