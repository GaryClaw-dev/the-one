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
var _use_animated: bool = false
var _is_attacking_anim: bool = false
var is_fodder: bool = false
var _spawn_cooldown: float = 0.0
var _spawned_minions: Array = []

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
	_is_attacking_anim = false

	_max_health = data.get_scaled_hp(wave)
	_health = _max_health

	# Determine scale
	var sprite_scale := Vector2(0.08, 0.08)
	if data.is_boss:
		sprite_scale = Vector2(0.16, 0.16)
	elif data.is_mini_boss:
		sprite_scale = Vector2(0.12, 0.12)

	# Check if this enemy has sprite sheets
	_use_animated = data.sprite_sheet_idle != ""
	if _use_animated:
		_setup_animated_sprite(sprite_scale)
	else:
		_setup_static_sprite(sprite_scale)

func _setup_static_sprite(sprite_scale: Vector2) -> void:
	var sprite = $Sprite2D as Sprite2D
	var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if anim_sprite:
		anim_sprite.visible = false
	if sprite:
		sprite.visible = true
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
			var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color.WHITE)
			sprite.texture = ImageTexture.create_from_image(img)
			sprite.modulate = data.color
			_base_sprite_color = data.color
		sprite.scale = sprite_scale

func _setup_animated_sprite(sprite_scale: Vector2) -> void:
	var sprite = $Sprite2D as Sprite2D
	var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if sprite:
		sprite.visible = false
	if not anim_sprite:
		return

	anim_sprite.visible = true
	# Scale animated sprites to match static sprite visual size
	# Static sprites are ~1024px, so scale factor = 1024 / frame_width
	var frame_w := data.sheet_frame_size.x if data.sheet_frame_size.x > 0 else 384.0
	var sheet_scale_factor := 1024.0 / frame_w
	anim_sprite.scale = sprite_scale * sheet_scale_factor
	anim_sprite.modulate = Color.WHITE
	_base_sprite_color = Color.WHITE

	var frames = SpriteFrames.new()
	# Remove default animation if present
	if frames.has_animation("default"):
		frames.remove_animation("default")

	_add_sheet_animation(frames, "idle", data.sprite_sheet_idle, data.sheet_frame_count, data.sheet_frame_size, 4.0, true)
	_add_sheet_animation(frames, "walk", data.sprite_sheet_walk, data.sheet_frame_count, data.sheet_frame_size, 8.0, true)
	_add_sheet_animation(frames, "attack", data.sprite_sheet_attack, data.sheet_frame_count, data.sheet_frame_size, 10.0, false)

	anim_sprite.sprite_frames = frames
	anim_sprite.play("idle")

func _add_sheet_animation(frames: SpriteFrames, anim_name: String, sheet_path: String, frame_count: int, frame_size: Vector2, fps: float, looping: bool) -> void:
	if sheet_path == "":
		return
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, looping)
	var sheet_tex = load(sheet_path) as Texture2D
	if not sheet_tex:
		return
	# Auto-detect frame size from texture if it's a horizontal strip
	var tex_w := sheet_tex.get_width()
	var tex_h := sheet_tex.get_height()
	var actual_frame_size := frame_size
	if frame_count > 0 and tex_w > tex_h:
		# Horizontal strip: frame width = total width / frame count, height = texture height
		actual_frame_size = Vector2(tex_w / frame_count, tex_h)
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet_tex
		atlas.region = Rect2(i * actual_frame_size.x, 0, actual_frame_size.x, actual_frame_size.y)
		frames.add_frame(anim_name, atlas)

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

	# Flip sprite toward hero and update animation
	var face_dir_x := 0.0
	if _hero and is_instance_valid(_hero):
		face_dir_x = _hero.global_position.x - global_position.x
	elif velocity.x != 0:
		face_dir_x = velocity.x

	if _use_animated:
		var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
		if anim_sprite:
			# Don't flip animated sprites — 3/4 perspective art looks wrong when mirrored
			pass
			if not _is_attacking_anim:
				if velocity.length_squared() > 25.0:
					if anim_sprite.animation != "walk":
						anim_sprite.play("walk")
				else:
					if anim_sprite.animation != "idle":
						anim_sprite.play("idle")
	else:
		var sprite = $Sprite2D as Sprite2D
		if sprite and abs(face_dir_x) > 1.0:
			sprite.flip_h = face_dir_x < 0

	# Rage visual feedback — red tint intensifies
	_update_rage_visual()

	# Tick cooldown once per frame (regardless of range)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	# Attack — contact for melee, projectile for ranged/spawner
	var post_dist = global_position.distance_to(_hero.global_position)
	if data.behavior == EnemyData.Behavior.RANGED:
		if post_dist <= data.attack_range * 3.0:
			_try_ranged_attack()
	elif data.behavior == EnemyData.Behavior.SPAWNER:
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
	var tint = _base_sprite_color.lerp(Color(1.4, 0.3, 0.3), rage_pct * 0.7)
	if _use_animated:
		var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
		if anim_sprite:
			anim_sprite.modulate = tint
	else:
		var sprite = $Sprite2D as Sprite2D
		if sprite:
			sprite.modulate = tint

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
	_play_attack_anim()

	if _hero.has_method("take_damage"):
		var scaled_damage = data.get_scaled_damage(_wave) * (1.0 + _get_rage_dmg_mult())
		_hero.take_damage(scaled_damage, false, self)

func _try_ranged_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = data.attack_cooldown
	_play_attack_anim()

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
	if _use_animated:
		var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
		if anim_sprite:
			anim_sprite.stop()
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
	# Keep distance from hero — stay at range
	var dist_to_hero = global_position.distance_to(_hero.global_position)
	if dist_to_hero > data.attack_range * 4.0:
		_move_toward_hero(speed, delta)
	elif dist_to_hero < data.attack_range * 2.0:
		# Back away
		var away = (global_position - _hero.global_position).normalized()
		velocity = away * speed * _get_slow_mult()
	else:
		velocity = Vector2.ZERO

	# Periodically summon skeleton minions
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_spawn_cooldown = data.attack_cooldown
		_summon_minions()

func _summon_minions() -> void:
	# Clean up dead minion refs
	_spawned_minions = _spawned_minions.filter(func(m): return is_instance_valid(m) and not m._dead)
	# Cap at 4 active minions
	if _spawned_minions.size() >= 4:
		return
	var skeleton_data = load("res://resources/enemies/skeleton.tres") as EnemyData
	if not skeleton_data:
		return
	var scene = preload("res://scenes/enemy.tscn")
	var count = 2
	for i in range(count):
		if _spawned_minions.size() >= 4:
			break
		var minion = scene.instantiate()
		get_tree().current_scene.add_child(minion)
		var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		minion.global_position = global_position + offset
		if minion.has_method("initialize"):
			minion.initialize(skeleton_data, _wave, _hero)
		minion.is_fodder = true
		_spawned_minions.append(minion)
	AudioManager.play("wave_start", -6.0)

func _drop_xp() -> void:
	if is_fodder and data.xp_value <= 0.0:
		return
	# Use object pool from WaveManager
	var wave_manager = get_tree().current_scene.get_node_or_null("WaveManager")
	var is_first = false
	if wave_manager and wave_manager.has_method("is_first_enemy_appearance"):
		is_first = wave_manager.is_first_enemy_appearance(data, _wave)

	var xp_scene = preload("res://scenes/xp_orb.tscn")
	var xp: Node2D = xp_scene.instantiate()
	xp.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	xp.initialize(data.get_scaled_xp(_wave, is_first))
	get_tree().current_scene.add_child.call_deferred(xp)

func _show_damage_flash() -> void:
	if _use_animated:
		var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
		if not anim_sprite:
			return
		anim_sprite.modulate = Color.RED
		var tween = create_tween()
		tween.tween_property(anim_sprite, "modulate", _base_sprite_color, 0.1)
	else:
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

func _play_attack_anim() -> void:
	if not _use_animated:
		return
	var anim_sprite = $AnimatedSprite2D as AnimatedSprite2D
	if not anim_sprite:
		return
	_is_attacking_anim = true
	if not anim_sprite.animation_finished.is_connected(_on_attack_anim_finished):
		anim_sprite.animation_finished.connect(_on_attack_anim_finished)
	anim_sprite.play("attack")

func _on_attack_anim_finished() -> void:
	_is_attacking_anim = false

func get_health_ratio() -> float:
	return _health / _max_health if _max_health > 0 else 0.0
