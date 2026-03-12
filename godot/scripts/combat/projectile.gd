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
var _aoe_radius: float = 0.0
var _lifetime: float = 5.0
var _hit_targets: Array = []

# Homing (Wind Guidance)
var _homing: bool = false
var _homing_strength: float = 3.0
var _homing_target: Node2D = null

# Ricochet (Gunner ability)
var _bounces_remaining: int = 0
var _bounce_range: float = 150.0
var _bounce_damage_bonus: float = 0.0

func initialize(direction: Vector2, speed: float, damage: float,
		crit_chance: float, crit_multiplier: float, pierce: int,
		knockback: float, lifesteal: float, hero_projectile: bool,
		aoe_radius: float = 0.0) -> void:
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	_crit_chance = crit_chance
	_crit_multiplier = crit_multiplier
	_pierce_remaining = pierce
	_knockback = knockback
	_lifesteal = lifesteal
	_is_hero_projectile = hero_projectile
	_aoe_radius = aoe_radius

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
	# Homing: gently steer toward target
	if _homing and _homing_target and is_instance_valid(_homing_target):
		var to_target = (_homing_target.global_position - global_position).normalized()
		_direction = _direction.lerp(to_target, _homing_strength * delta).normalized()
		rotation = _direction.angle()

	position += _direction * _speed * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func enable_homing(target: Node2D, strength: float = 3.0) -> void:
	_homing = true
	_homing_target = target
	_homing_strength = strength

func enable_bounce(count: int, range_dist: float = 150.0, damage_bonus: float = 0.0) -> void:
	_bounces_remaining = count
	_bounce_range = range_dist
	_bounce_damage_bonus = damage_bonus

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

	# Headshot: bonus crit damage
	if is_crit and has_meta("headshot_bonus"):
		final_damage *= (1.0 + get_meta("headshot_bonus"))

	# Execute threshold (Headshot level 5): instant kill below HP %
	if has_meta("execute_threshold"):
		var threshold = get_meta("execute_threshold")
		if threshold > 0 and target.has_method("get_health_ratio"):
			if target.get_health_ratio() <= threshold:
				final_damage = 99999.0

	# Incendiary: apply burn DoT on hit
	if has_meta("incendiary_chance") and has_meta("incendiary_dps"):
		if randf() < get_meta("incendiary_chance"):
			var dps = get_meta("incendiary_dps")
			var duration = get_meta("incendiary_duration") if has_meta("incendiary_duration") else 3.0
			if target.has_method("apply_burn"):
				target.apply_burn(dps, duration)

	# Poison: apply poison DoT on hit (Ranger)
	if has_meta("poison_dps"):
		var p_dps = get_meta("poison_dps")
		var p_dur = get_meta("poison_duration") if has_meta("poison_duration") else 4.0
		if target.has_method("apply_poison"):
			target.apply_poison(p_dps, p_dur)

	# Frostbite: chance to slow
	if has_meta("frostbite_chance"):
		if randf() < get_meta("frostbite_chance"):
			var slow_pct = get_meta("frostbite_slow") if has_meta("frostbite_slow") else 0.3
			var slow_dur = get_meta("frostbite_duration") if has_meta("frostbite_duration") else 3.0
			if target.has_method("apply_slow"):
				target.apply_slow(slow_pct, slow_dur)

	# Bleed: chance to apply bleed DoT
	if has_meta("bleed_chance"):
		if randf() < get_meta("bleed_chance"):
			var bleed_pct = get_meta("bleed_damage_pct") if has_meta("bleed_damage_pct") else 0.1
			var bleed_dps = final_damage * bleed_pct
			if target.has_method("apply_bleed"):
				target.apply_bleed(bleed_dps, 3.0)

	# Shatter Shot: chance to shred armor
	if has_meta("shatter_chance"):
		if randf() < get_meta("shatter_chance"):
			var shred_pct = get_meta("shatter_armor_pct") if has_meta("shatter_armor_pct") else 0.15
			if target.has_method("apply_armor_shred"):
				target.apply_armor_shred(shred_pct, 5.0)

	# Unstable Rounds: chance for bonus damage multiplier
	if has_meta("unstable_chance"):
		if randf() < get_meta("unstable_chance"):
			var bonus_mult = get_meta("unstable_multiplier") if has_meta("unstable_multiplier") else 1.5
			final_damage *= bonus_mult

	var dealt: float = target.take_damage(final_damage, is_crit, self)

	GameEvents.damage_dealt.emit(target, dealt, is_crit)

	# Lifesteal
	if _lifesteal > 0.0 and _is_hero_projectile:
		var hero = get_tree().get_first_node_in_group("hero")
		if hero and hero.has_method("heal"):
			hero.heal(dealt * _lifesteal)

	# Vampiric Strikes: chance to heal % of damage dealt
	if has_meta("vampiric_chance") and _is_hero_projectile:
		if randf() < get_meta("vampiric_chance"):
			var heal_pct = get_meta("vampiric_heal_pct") if has_meta("vampiric_heal_pct") else 0.05
			var hero = get_tree().get_first_node_in_group("hero")
			if hero and hero.has_method("heal"):
				hero.heal(dealt * heal_pct)

	# Chain Lightning: chance to chain to nearby enemies
	if has_meta("chain_chance") and _is_hero_projectile:
		if randf() < get_meta("chain_chance"):
			var chain_count = int(get_meta("chain_targets")) if has_meta("chain_targets") else 2
			var chain_dmg = dealt * 0.5
			_apply_chain_lightning(target, chain_count, chain_dmg)

	# Knockback
	if _knockback > 0.0 and target is CharacterBody2D:
		var knock_dir = (target.global_position - global_position).normalized()
		target.velocity += knock_dir * _knockback

	# AoE splash damage
	if _aoe_radius > 0.0 and _is_hero_projectile:
		_apply_aoe_splash(target)
		# Splinter Storm (Lumberjack): spawn sub-projectiles on AoE impact
		if has_meta("splinter") and has_meta("splinter_count"):
			_spawn_splinters()
		# Scorched Earth (Catapult): leave fire zone on impact
		if has_meta("scorched_earth_duration"):
			_spawn_fire_zone()
		queue_free()
		return

	_pierce_remaining -= 1
	if _pierce_remaining < 0:
		# Try to bounce (ricochet) before dying
		if _bounces_remaining > 0:
			var next_target = _find_bounce_target()
			if next_target:
				_bounces_remaining -= 1
				_damage *= (1.0 + _bounce_damage_bonus)
				_direction = (next_target.global_position - global_position).normalized()
				rotation = _direction.angle()
				_pierce_remaining = 0  # Reset pierce for the bounce
				return
		queue_free()

func _find_bounce_target() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist = _bounce_range
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy in _hit_targets:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _apply_aoe_splash(primary_target: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == primary_target:
			continue
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy in _hit_targets:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= _aoe_radius:
			if enemy.has_method("take_damage"):
				var is_crit = randf() < _crit_chance
				var splash_dmg = _damage * _crit_multiplier if is_crit else _damage
				var dealt: float = enemy.take_damage(splash_dmg, is_crit, self)
				GameEvents.damage_dealt.emit(enemy, dealt, is_crit)
				if _lifesteal > 0.0:
					var hero = get_tree().get_first_node_in_group("hero")
					if hero and hero.has_method("heal"):
						hero.heal(dealt * _lifesteal)

func _spawn_splinters() -> void:
	var count = int(get_meta("splinter_count"))
	var dmg_mult = get_meta("splinter_damage_mult") if has_meta("splinter_damage_mult") else 0.3
	var projectile_scene = preload("res://scenes/projectile.tscn")
	var splinter_dmg = _damage * dmg_mult
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2.from_angle(angle)
		var proj: Node2D = projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		proj.initialize(dir, _speed * 0.8, splinter_dmg, _crit_chance, _crit_multiplier, 0, _knockback * 0.5, _lifesteal, true)
		# Tint splinters green-brown
		var sprite = proj.get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprite.modulate = Color(0.5, 0.6, 0.3)
			sprite.scale *= 0.6

func _spawn_fire_zone() -> void:
	var duration = get_meta("scorched_earth_duration")
	var dps = get_meta("scorched_earth_dps")
	var zone_pos = global_position
	var scene_root = get_tree().current_scene
	# Create a simple Area2D fire zone
	var zone = Area2D.new()
	zone.global_position = zone_pos
	zone.collision_layer = 0
	zone.collision_mask = 2  # Enemy layer
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = _aoe_radius
	shape.shape = circle
	zone.add_child(shape)
	scene_root.add_child(zone)
	# Tick damage via timer
	var timer_elapsed = 0.0
	var tick_func: Callable
	tick_func = func(delta: float) -> void:
		timer_elapsed += delta
		if timer_elapsed >= duration:
			zone.queue_free()
			return
		var bodies = zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("apply_burn"):
				body.apply_burn(dps, 0.5)
	zone.set_physics_process(true)
	zone.set_script(null)  # No script — use a scene tree timer instead
	# Simpler approach: just apply burn to all enemies in radius periodically
	var t = scene_root.get_tree().create_timer(duration)
	var tick_timer = Timer.new()
	tick_timer.wait_time = 0.5
	tick_timer.autostart = true
	zone.add_child(tick_timer)
	tick_timer.timeout.connect(func():
		if not is_instance_valid(zone):
			return
		var bodies = zone.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies") and body.has_method("apply_burn"):
				body.apply_burn(dps, 1.0)
	)
	t.timeout.connect(func():
		if is_instance_valid(zone):
			zone.queue_free()
	)

func _apply_chain_lightning(origin: Node2D, count: int, chain_dmg: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit: Array = [origin]
	var current = origin
	for _i in range(count):
		var nearest: Node2D = null
		var nearest_dist = 150.0
		for enemy in enemies:
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			if enemy in hit:
				continue
			if enemy.has_method("is_dead") and enemy.is_dead():
				continue
			var dist = current.global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
		if nearest and nearest.has_method("take_damage"):
			var dealt: float = nearest.take_damage(chain_dmg, false, self)
			GameEvents.damage_dealt.emit(nearest, dealt, false)
			hit.append(nearest)
			current = nearest
		else:
			break
