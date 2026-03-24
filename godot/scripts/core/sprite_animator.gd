extends Node
## Procedural tween-based sprite animations. Autoload singleton.
## Call register() once per sprite, then use start_idle / start_walk / play_attack / play_hit / play_death.

enum AnimState { NONE, IDLE, WALK, ATTACK, HIT, DEATH }

# instance_id -> { sprite, base_scale, base_pos, tweens, state }
var _data: Dictionary = {}


func register(sprite: Sprite2D) -> void:
	var id = sprite.get_instance_id()
	_data[id] = {
		"sprite": sprite,
		"base_scale": sprite.scale,
		"base_pos": sprite.position,
		"tweens": [],
		"state": AnimState.NONE,
	}
	sprite.tree_exiting.connect(_on_sprite_exit.bind(id))


func _on_sprite_exit(id: int) -> void:
	_data.erase(id)


func _kill_tweens(id: int) -> void:
	var d = _data.get(id)
	if not d:
		return
	for tw in d["tweens"]:
		if tw and tw.is_valid():
			tw.kill()
	d["tweens"] = []


func _reset(sprite: Sprite2D, d: Dictionary) -> void:
	sprite.scale = d["base_scale"]
	sprite.position = d["base_pos"]
	sprite.rotation = 0.0


func _set_state(id: int, new_state: int) -> void:
	if id in _data:
		_data[id]["state"] = new_state


# ---- Idle: subtle Y-axis bob + inverse X breathing ----

func start_idle(sprite: Sprite2D) -> void:
	var id = sprite.get_instance_id()
	var d = _data.get(id)
	if not d or d["state"] == AnimState.IDLE:
		return
	if d["state"] in [AnimState.ATTACK, AnimState.HIT, AnimState.DEATH]:
		return
	_kill_tweens(id)
	_reset(sprite, d)
	d["state"] = AnimState.IDLE

	var bs: Vector2 = d["base_scale"]

	var tw_y = sprite.create_tween().set_loops()
	tw_y.tween_property(sprite, "scale:y", bs.y * 1.03, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw_y.tween_property(sprite, "scale:y", bs.y * 0.97, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var tw_x = sprite.create_tween().set_loops()
	tw_x.tween_property(sprite, "scale:x", bs.x * 0.98, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw_x.tween_property(sprite, "scale:x", bs.x * 1.02, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	d["tweens"] = [tw_y, tw_x]


# ---- Walk: side-to-side tilt + vertical bounce + squash-stretch ----

func start_walk(sprite: Sprite2D, speed_factor: float = 1.0) -> void:
	var id = sprite.get_instance_id()
	var d = _data.get(id)
	if not d or d["state"] == AnimState.WALK:
		return
	if d["state"] in [AnimState.ATTACK, AnimState.HIT, AnimState.DEATH]:
		return
	_kill_tweens(id)
	_reset(sprite, d)
	d["state"] = AnimState.WALK

	var bs: Vector2 = d["base_scale"]
	var bp: Vector2 = d["base_pos"]
	var cycle = maxf(0.08, 0.2 / maxf(speed_factor, 0.5))

	# Tilt ±5°
	var tw_rot = sprite.create_tween().set_loops()
	tw_rot.tween_property(sprite, "rotation", deg_to_rad(5.0), cycle) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw_rot.tween_property(sprite, "rotation", deg_to_rad(-5.0), cycle) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Vertical bounce -2px
	var tw_bounce = sprite.create_tween().set_loops()
	tw_bounce.tween_property(sprite, "position:y", bp.y - 2.0, cycle) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw_bounce.tween_property(sprite, "position:y", bp.y, cycle) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)

	# Squash-stretch alternating
	var tw_squash = sprite.create_tween().set_loops()
	tw_squash.tween_property(sprite, "scale", Vector2(bs.x * 1.05, bs.y * 0.95), cycle) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw_squash.tween_property(sprite, "scale", Vector2(bs.x * 0.95, bs.y * 1.05), cycle) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	d["tweens"] = [tw_rot, tw_bounce, tw_squash]


# ---- Attack: lunge + squash + white flash + snap back ----

func play_attack(sprite: Sprite2D, direction: Vector2) -> void:
	var id = sprite.get_instance_id()
	var d = _data.get(id)
	if not d or d["state"] == AnimState.DEATH:
		return
	_kill_tweens(id)
	_reset(sprite, d)
	d["state"] = AnimState.ATTACK

	var bs: Vector2 = d["base_scale"]
	var bp: Vector2 = d["base_pos"]
	var lunge_offset = direction.normalized() * 4.0

	var tw = sprite.create_tween()
	# Lunge toward target
	tw.tween_property(sprite, "position", bp + lunge_offset, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(sprite, "scale", Vector2(bs.x * 1.2, bs.y * 0.8), 0.08) \
		.set_ease(Tween.EASE_OUT)
	# White flash at impact (uses self_modulate to avoid conflicts with modulate)
	tw.tween_callback(func(): sprite.self_modulate = Color(5, 5, 5))
	tw.tween_interval(0.05)
	tw.tween_callback(func(): sprite.self_modulate = Color.WHITE)
	# Snap back with overshoot ease
	tw.tween_property(sprite, "position", bp, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(sprite, "scale", bs, 0.12) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_set_state.bind(id, AnimState.NONE))

	d["tweens"] = [tw]


# ---- Hit: red flash + shake + squash ----

func play_hit(sprite: Sprite2D, restore_color: Color = Color.WHITE) -> void:
	var id = sprite.get_instance_id()
	var d = _data.get(id)
	if not d or d["state"] == AnimState.DEATH:
		return
	_kill_tweens(id)
	_reset(sprite, d)
	d["state"] = AnimState.HIT

	var bs: Vector2 = d["base_scale"]
	var bp: Vector2 = d["base_pos"]

	# Red flash (set immediately, tween restores)
	sprite.modulate = Color.RED

	# Squash then bounce back
	var tw = sprite.create_tween()
	tw.tween_property(sprite, "scale", Vector2(bs.x * 1.15, bs.y * 0.85), 0.05) \
		.set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", bs, 0.1) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(_set_state.bind(id, AnimState.NONE))

	# Shake ±3px, 3 cycles
	var tw_shake = sprite.create_tween()
	for i in range(3):
		tw_shake.tween_property(sprite, "position:x", bp.x + 3.0, 0.025)
		tw_shake.tween_property(sprite, "position:x", bp.x - 3.0, 0.025)
	tw_shake.tween_property(sprite, "position:x", bp.x, 0.025)

	# Restore color from red
	var tw_color = sprite.create_tween()
	tw_color.tween_property(sprite, "modulate", restore_color, 0.1)

	d["tweens"] = [tw, tw_shake, tw_color]


# ---- Death: squash flat + spin + fade + queue_free ----

func play_death(sprite: Sprite2D, entity: Node) -> void:
	var id = sprite.get_instance_id()
	var d = _data.get(id)
	if not d:
		# Fallback: simple fade
		var tw = entity.create_tween()
		tw.tween_property(entity, "modulate:a", 0.0, 0.15)
		tw.tween_callback(entity.queue_free)
		return
	_kill_tweens(id)
	_reset(sprite, d)
	d["state"] = AnimState.DEATH

	var bs: Vector2 = d["base_scale"]

	var tw = entity.create_tween()
	# Squash flat (scale.y -> 0) + widen (scale.x -> 1.5× base)
	tw.tween_property(sprite, "scale", Vector2(bs.x * 1.5, 0.0), 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Spin 90° during squash
	tw.parallel().tween_property(sprite, "rotation", deg_to_rad(90.0), 0.2) \
		.set_ease(Tween.EASE_IN)
	# Then fade the entire entity
	tw.tween_property(entity, "modulate:a", 0.0, 0.15)
	tw.tween_callback(entity.queue_free)

	d["tweens"] = [tw]
