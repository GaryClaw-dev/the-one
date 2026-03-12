extends Area2D
## Projectile that flies in a direction and deals damage on contact.

var _direction: Vector2
var _speed: float
var _damage: float
var _crit_chance: float
var _crit_multiplier: float
var _pierce_remaining: int
var _knockback: float
var _lifesteal: float
var _is_hero_projectile: bool
var _lifetime: float = 5.0
var _hit_targets: Array = []

func initialize(direction: Vector2, speed: float, damage: float,
		crit_chance: float, crit_multiplier: float, pierce: int,
		knockback: float, lifesteal: float, hero_projectile: bool) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	_crit_chance = crit_chance
	_crit_multiplier = crit_multiplier
	_pierce_remaining = pierce
	_knockback = knockback
	_lifesteal = lifesteal
	_is_hero_projectile = hero_projectile

	rotation = _direction.angle()

	# Set collision masks based on who fired
	if _is_hero_projectile:
		collision_layer = 4  # HeroProjectile layer
		collision_mask = 2   # Enemy layer
	else:
		collision_layer = 8  # EnemyProjectile layer
		collision_mask = 1   # Hero layer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _is_hero_projectile and body.is_in_group("enemies"):
		_deal_damage(body)
	elif not _is_hero_projectile and body.is_in_group("hero"):
		_deal_damage(body)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	if not body or not body is Node2D:
		return
	if _is_hero_projectile and body.is_in_group("enemies"):
		_deal_damage(body)
	elif not _is_hero_projectile and body.is_in_group("hero"):
		_deal_damage(body)
		queue_free()

func _deal_damage(target: Node2D) -> void:
	if not target.has_method("take_damage"):
		return
	if target in _hit_targets:
		return
	_hit_targets.append(target)

	var is_crit = randf() < _crit_chance
	var final_damage = _damage * _crit_multiplier if is_crit else _damage
	var dealt: float = target.take_damage(final_damage, is_crit, self)

	GameEvents.damage_dealt.emit(target, dealt, is_crit)

	# Lifesteal
	if _lifesteal > 0.0 and _is_hero_projectile:
		var hero = get_tree().get_first_node_in_group("hero")
		if hero and hero.has_method("heal"):
			hero.heal(dealt * _lifesteal)

	# Knockback
	if _knockback > 0.0 and target is CharacterBody2D:
		var knock_dir = (target.global_position - global_position).normalized()
		target.velocity += knock_dir * _knockback

	_pierce_remaining -= 1
	if _pierce_remaining < 0:
		queue_free()
