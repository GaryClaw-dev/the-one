extends CharacterBody2D
## Base enemy. Moves toward hero, deals contact damage, drops loot on death.

@export var data: EnemyData

var _health: float
var _max_health: float
var _wave: int
var _hero: Node2D
var _attack_cooldown: float = 0.0
var _dead: bool = false

# Erratic movement
var _erratic_timer: float = 0.0
var _erratic_offset: float = 0.0

func _ready() -> void:
	add_to_group("enemies")

func initialize(enemy_data: EnemyData, wave: int, hero: Node2D) -> void:
	data = enemy_data
	_wave = wave
	_hero = hero
	_dead = false
	_attack_cooldown = 0.0

	_max_health = data.get_scaled_hp(wave)
	_health = _max_health

	# Apply visuals
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.modulate = data.color
		# Scale for bosses
		if data.is_boss:
			scale = Vector2(2.0, 2.0)
		elif data.is_mini_boss:
			scale = Vector2(1.5, 1.5)
		else:
			scale = Vector2.ONE

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if not _hero or not is_instance_valid(_hero):
		return

	var dist_to_hero = global_position.distance_to(_hero.global_position)
	var speed = data.get_scaled_speed(_wave)

	match data.behavior:
		EnemyData.Behavior.RUSH:
			_move_toward_hero(speed, delta)
		EnemyData.Behavior.ERRATIC:
			_move_erratic(speed, delta)
		EnemyData.Behavior.RANGED:
			if dist_to_hero > data.attack_range * 3.0:
				_move_toward_hero(speed, delta)
			else:
				velocity = Vector2.ZERO
		EnemyData.Behavior.CHARGE:
			_move_toward_hero(speed * 1.5, delta)
		_:
			_move_toward_hero(speed, delta)

	move_and_slide()

	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	# Contact damage
	if dist_to_hero <= data.attack_range:
		_try_attack(delta)

func _move_toward_hero(speed: float, _delta: float) -> void:
	var dir = (_hero.global_position - global_position).normalized()
	velocity = dir * speed

func _move_erratic(speed: float, delta: float) -> void:
	_erratic_timer -= delta
	if _erratic_timer <= 0.0:
		_erratic_timer = randf_range(0.3, 0.8)
		_erratic_offset = randf_range(-60.0, 60.0)

	var dir = (_hero.global_position - global_position).normalized()
	dir = dir.rotated(deg_to_rad(_erratic_offset))
	velocity = dir * speed

func _try_attack(delta: float) -> void:
	_attack_cooldown -= delta
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown

	if _hero.has_method("take_damage"):
		_hero.take_damage(data.damage, false, self)

func take_damage(amount: float, is_crit: bool = false, _attacker: Node2D = null) -> float:
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
	velocity = Vector2.ZERO
	GameEvents.enemy_killed.emit(self)

	# Drop XP
	_drop_xp()

	# Chance to drop loot
	var luck = 0.0
	if _hero and _hero.has_method("get_stat_value"):
		luck = _hero.stats.get_stat(StatSystem.StatType.LUCK)
	var drop_chance = data.loot_drop_chance + luck * 0.01
	if randf() < drop_chance:
		_drop_loot_orb()

	# Death animation then remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _drop_xp() -> void:
	var xp_scene = preload("res://scenes/xp_orb.tscn")
	var xp: Node2D = xp_scene.instantiate()
	get_tree().current_scene.add_child(xp)
	xp.global_position = global_position
	xp.initialize(data.xp_value)

func _drop_loot_orb() -> void:
	var loot_scene = preload("res://scenes/loot_orb.tscn")
	var orb: Node2D = loot_scene.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position

func _show_damage_flash() -> void:
	var sprite = $Sprite2D as Sprite2D
	if not sprite:
		return
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", data.color, 0.1)

func get_health_ratio() -> float:
	return _health / _max_health if _max_health > 0 else 0.0
