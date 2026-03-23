extends CharacterBody2D
## Base enemy. Moves toward hero, deals contact damage, drops XP on death.

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

# Burn DoT
var _burn_dps: float = 0.0
var _burn_timer: float = 0.0

# Poison DoT
var _poison_dps: float = 0.0
var _poison_timer: float = 0.0

# Slow
var _slow_pct: float = 0.0
var _slow_timer: float = 0.0

# Bleed DoT
var _bleed_dps: float = 0.0
var _bleed_timer: float = 0.0

# Armor shred (increases damage taken)
var _armor_shred_pct: float = 0.0
var _armor_shred_timer: float = 0.0

# Curse (separate from armor shred — Demon Hunter)
var _curse_dmg_pct: float = 0.0
var _curse_timer: float = 0.0

# Rage / heat-up (enemies get stronger the longer they survive)
var _alive_time: float = 0.0
const RAGE_THRESHOLD: float = 3.0   # Seconds before rage kicks in
const RAGE_DMG_PER_SEC: float = 0.05  # +5% damage per second past threshold
const RAGE_SPD_PER_SEC: float = 0.03  # +3% speed per second past threshold
const RAGE_CAP: float = 1.5           # Max +150% bonus

var _knockback_velocity: Vector2 = Vector2.ZERO

var _base_sprite_color: Color = Color.WHITE
var is_fodder: bool = false

# DoT damage number accumulators (emit every 0.5s to avoid spam)
var _dot_display_timer: float = 0.0
var _burn_accum: float = 0.0
var _poison_accum: float = 0.0
var _bleed_accum: float = 0.0
const DOT_DISPLAY_INTERVAL: float = 0.5

func _ready() -> void:
	add_to_group("enemies")

func initialize(enemy_data: EnemyData, wave: int, hero: Node2D) -> void:
	data = enemy_data
	_wave = wave
	_hero = hero
	_dead = false
	_attack_cooldown = 0.0
	_alive_time = 0.0

	_max_health = data.get_scaled_hp(wave)
	_health = _max_health

	# Apply visuals
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		# Load sprite texture if path is set
		if data.sprite_path and data.sprite_path != "":
			var tex = load(data.sprite_path)
			if tex:
				sprite.texture = tex
				sprite.modulate = Color.WHITE
				_base_sprite_color = Color.WHITE
			else:
				sprite.modulate = data.color
				_base_sprite_color = data.color
		else:
			# No sprite path — generate a placeholder white square
			var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color.WHITE)
			sprite.texture = ImageTexture.create_from_image(img)
			sprite.modulate = data.color
			_base_sprite_color = data.color
		# Scale for bosses
		if data.is_boss:
			sprite.scale = Vector2(0.08, 0.08)
		elif data.is_mini_boss:
			sprite.scale = Vector2(0.06, 0.06)
		else:
			sprite.scale = Vector2(0.04, 0.04)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	if not _hero or not is_instance_valid(_hero):
		_hero = GameManager.active_hero
		if not _hero:
			return

	# Track alive time for rage mechanic
	_alive_time += delta

	var dist_to_hero = global_position.distance_to(_hero.global_position)
	var speed = data.get_scaled_speed(_wave) * (1.0 + _get_rage_speed_mult())

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
		EnemyData.Behavior.SPAWNER:
			_spawner_update(speed, delta)
		_:
			_move_toward_hero(speed, delta)

	# Burn DoT tick
	if _burn_timer > 0.0:
		_burn_timer -= delta
		var burn_dmg = _burn_dps * delta
		_health -= burn_dmg
		_burn_accum += burn_dmg
		if _health <= 0.0 and not _dead:
			_die()

	# Poison DoT tick
	if _poison_timer > 0.0:
		_poison_timer -= delta
		var poison_dmg = _poison_dps * delta
		_health -= poison_dmg
		_poison_accum += poison_dmg
		if _health <= 0.0 and not _dead:
			_die()

	# Bleed DoT tick
	if _bleed_timer > 0.0:
		_bleed_timer -= delta
		var bleed_dmg = _bleed_dps * delta
		_health -= bleed_dmg
		_bleed_accum += bleed_dmg
		if _health <= 0.0 and not _dead:
			_die()
		if _bleed_timer <= 0.0:
			_bleed_dps = 0.0

	# Emit accumulated DoT damage numbers periodically
	_dot_display_timer -= delta
	if _dot_display_timer <= 0.0:
		_dot_display_timer = DOT_DISPLAY_INTERVAL
		if _burn_accum > 0.0:
			GameEvents.damage_dealt.emit(self, _burn_accum, false, "burn")
			_burn_accum = 0.0
		if _poison_accum > 0.0:
			GameEvents.damage_dealt.emit(self, _poison_accum, false, "poison")
			_poison_accum = 0.0
		if _bleed_accum > 0.0:
			GameEvents.damage_dealt.emit(self, _bleed_accum, false, "bleed")
			_bleed_accum = 0.0

	# Slow decay
	if _slow_timer > 0.0:
		_slow_timer -= delta
		if _slow_timer <= 0.0:
			_slow_pct = 0.0

	# Armor shred decay
	if _armor_shred_timer > 0.0:
		_armor_shred_timer -= delta
		if _armor_shred_timer <= 0.0:
			_armor_shred_pct = 0.0

	# Curse decay (separate from shred)
	if _curse_timer > 0.0:
		_curse_timer -= delta
		if _curse_timer <= 0.0:
			_curse_dmg_pct = 0.0

	# Apply knockback
	if _knockback_velocity.length_squared() > 1.0:
		velocity += _knockback_velocity
		_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, 10.0 * delta)
	else:
		_knockback_velocity = Vector2.ZERO

	move_and_slide()

	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	# Rage visual feedback — red tint intensifies
	_update_rage_visual()

	# Tick cooldown once per frame (regardless of range)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	# Attack — contact for melee, projectile for ranged
	var post_dist = global_position.distance_to(_hero.global_position)
	if data.behavior == EnemyData.Behavior.RANGED:
		if post_dist <= data.attack_range * 3.0:
			_try_ranged_attack()
	elif post_dist <= data.attack_range:
		_try_attack()

# ---- Rage / Heat-up ----

func _get_rage_dmg_mult() -> float:
	if data and data.is_boss:
		return 0.0
	if _alive_time <= RAGE_THRESHOLD:
		return 0.0
	return minf((_alive_time - RAGE_THRESHOLD) * RAGE_DMG_PER_SEC, RAGE_CAP)

func _get_rage_speed_mult() -> float:
	if data and data.is_boss:
		return 0.0
	if _alive_time <= RAGE_THRESHOLD:
		return 0.0
	return minf((_alive_time - RAGE_THRESHOLD) * RAGE_SPD_PER_SEC, RAGE_CAP)

func _update_rage_visual() -> void:
	if _alive_time <= RAGE_THRESHOLD:
		return
	var rage_pct = _get_rage_dmg_mult()
	if rage_pct <= 0.0:
		return
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.modulate = _base_sprite_color.lerp(Color(1.4, 0.3, 0.3), rage_pct * 0.7)

# ---- Movement ----

func _get_slow_mult() -> float:
	return 1.0 - _slow_pct if _slow_timer > 0.0 else 1.0

func _move_toward_hero(speed: float, _delta: float) -> void:
	var dir = (_hero.global_position - global_position).normalized()
	velocity = dir * speed * _get_slow_mult()

func _move_erratic(speed: float, delta: float) -> void:
	_erratic_timer -= delta
	if _erratic_timer <= 0.0:
		_erratic_timer = randf_range(0.3, 0.8)
		_erratic_offset = randf_range(-60.0, 60.0)

	var dir = (_hero.global_position - global_position).normalized()
	dir = dir.rotated(deg_to_rad(_erratic_offset))
	velocity = dir * speed * _get_slow_mult()

# ---- Combat ----

func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown

	if _hero.has_method("take_damage"):
		var scaled_damage = data.get_scaled_damage(_wave) * (1.0 + _get_rage_dmg_mult())
		_hero.take_damage(scaled_damage, false, self)

func _try_ranged_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown

	var projectile_scene = preload("res://scenes/projectile.tscn")
	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	var dir = (_hero.global_position - global_position).normalized()
	var scaled_damage = data.get_scaled_damage(_wave) * (1.0 + _get_rage_dmg_mult())
	proj.initialize(dir, 200.0, scaled_damage, 0.0, 1.0, 0, 0.0, 0.0, false)

func take_damage(amount: float, is_crit: bool = false, _attacker: Node2D = null) -> float:
	if _dead:
		return 0.0

	# Armor shred + curse increase damage taken (separate debuffs)
	var final_amount = amount * (1.0 + _armor_shred_pct + _curse_dmg_pct)
	_health -= final_amount
	_show_damage_flash()

	if _health <= 0.0:
		_die()

	return final_amount

func is_dead() -> bool:
	return _dead

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	GameEvents.enemy_killed.emit(self)

	# Notify boss defeat
	if data and data.is_boss:
		GameEvents.boss_defeated.emit(self)

	# Drop XP
	_drop_xp()

	# Death animation then remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _spawner_update(speed: float, delta: float) -> void:
	_move_toward_hero(speed, delta)

func _drop_xp() -> void:
	if is_fodder and data.xp_value <= 0.0:
		return
	# Use object pool from WaveManager
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	var is_first = false
	if wave_manager and wave_manager.has_method("is_first_enemy_appearance"):
		is_first = wave_manager.is_first_enemy_appearance(data, _wave)

	var xp: Node2D
	if wave_manager and wave_manager.xp_orb_pool:
		xp = wave_manager.xp_orb_pool.acquire()
		xp._pool = wave_manager.xp_orb_pool
	else:
		var xp_scene = preload("res://scenes/xp_orb.tscn")
		xp = xp_scene.instantiate()
		get_tree().current_scene.add_child.call_deferred(xp)

	xp.activate_at(global_position)
	xp.initialize(data.get_scaled_xp(_wave, is_first))

func _show_damage_flash() -> void:
	var sprite = $Sprite2D as Sprite2D
	if not sprite:
		return
	sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", _base_sprite_color, 0.1)

func apply_burn(dps: float, duration: float) -> void:
	# Stack: take the higher DPS, refresh duration
	_burn_dps = maxf(_burn_dps, dps)
	_burn_timer = maxf(_burn_timer, duration)

func apply_poison(dps: float, duration: float) -> void:
	_poison_dps = maxf(_poison_dps, dps)
	_poison_timer = maxf(_poison_timer, duration)

func apply_slow(pct: float, duration: float) -> void:
	_slow_pct = maxf(_slow_pct, clampf(pct, 0.0, 0.9))
	_slow_timer = maxf(_slow_timer, duration)

func apply_bleed(dps: float, duration: float) -> void:
	_bleed_dps = minf(_bleed_dps + dps, _max_health * 0.1)  # Cap at 10% max HP/sec
	_bleed_timer = maxf(_bleed_timer, duration)

func apply_armor_shred(pct: float, duration: float) -> void:
	_armor_shred_pct = clampf(maxf(_armor_shred_pct, pct), 0.0, 0.5)
	_armor_shred_timer = maxf(_armor_shred_timer, duration)

func apply_knockback(force: Vector2) -> void:
	_knockback_velocity += force

func apply_curse(pct: float, duration: float) -> void:
	_curse_dmg_pct = maxf(_curse_dmg_pct, pct)
	_curse_timer = maxf(_curse_timer, duration)

func get_health_ratio() -> float:
	return _health / _max_health if _max_health > 0 else 0.0
