extends Area3D
## 3D projectile. Flies in a direction on XZ plane, deals damage on contact.

var _direction: Vector3
var _speed: float
var _damage: float
var _crit_chance: float
var _crit_multiplier: float
var _pierce_remaining: int
var _knockback: float = 0.0
var _lifesteal: float = 0.0
var _is_hero_projectile: bool
var _lifetime: float = 5.0
var _hit_targets: Array = []
var _pool: Node

# Homing
var _homing: bool = false
var _homing_strength: float = 3.0
var _homing_target: Node3D = null

func reset_for_reuse() -> void:
	_hit_targets.clear()
	_homing = false
	_homing_target = null
	_homing_strength = 3.0
	_lifetime = 5.0
	_knockback = 0.0
	_lifesteal = 0.0

func _return_to_pool() -> void:
	if _pool and _pool.has_method("release"):
		_pool.release(self)
	else:
		queue_free()

func initialize(direction: Vector3, speed: float, damage: float,
		crit_chance: float, crit_multiplier: float, pierce: int,
		hero_projectile: bool) -> void:
	_direction = direction.normalized()
	_direction.y = 0
	if _direction.length_squared() < 0.01:
		_direction = Vector3.FORWARD
	_direction = _direction.normalized()
	_speed = speed
	_damage = damage
	_crit_chance = crit_chance
	_crit_multiplier = crit_multiplier
	_pierce_remaining = pierce
	_is_hero_projectile = hero_projectile

	# Face movement direction
	if _direction.length_squared() > 0.01:
		look_at(global_position + _direction, Vector3.UP)

	if _is_hero_projectile:
		collision_layer = 4
		collision_mask = 2
	else:
		collision_layer = 8
		collision_mask = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _homing and _homing_target and is_instance_valid(_homing_target):
		var to_target = (_homing_target.global_position - global_position).normalized()
		to_target.y = 0
		_direction = _direction.lerp(to_target, _homing_strength * delta).normalized()
		if _direction.length_squared() > 0.01:
			look_at(global_position + _direction, Vector3.UP)

	position += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		_return_to_pool()

func enable_homing(target: Node3D, strength: float = 3.0) -> void:
	_homing = true
	_homing_target = target
	_homing_strength = strength

func _on_body_entered(body: Node3D) -> void:
	if _is_hero_projectile and body.is_in_group("enemies"):
		_deal_damage(body)
	elif not _is_hero_projectile and body.is_in_group("hero"):
		_deal_damage(body)
		_return_to_pool()

func _deal_damage(target: Node3D) -> void:
	if not target.has_method("take_damage"):
		return
	if target in _hit_targets:
		return
	_hit_targets.append(target)

	var is_crit = randf() < _crit_chance
	var final_damage = _damage * _crit_multiplier if is_crit else _damage
	var dealt: float = target.take_damage(final_damage, is_crit, self)

	GameEvents.damage_dealt.emit(target, dealt, is_crit, "normal")

	# Lifesteal
	if _lifesteal > 0.0 and _is_hero_projectile:
		var hero = get_tree().get_first_node_in_group("hero")
		if hero and hero.has_method("heal"):
			hero.heal(dealt * _lifesteal)

	# Knockback
	if _knockback > 0.0 and target.has_method("apply_knockback"):
		var knock_dir = (target.global_position - global_position).normalized()
		knock_dir.y = 0
		target.apply_knockback(knock_dir * _knockback)

	_pierce_remaining -= 1
	if _pierce_remaining < 0:
		_return_to_pool()
