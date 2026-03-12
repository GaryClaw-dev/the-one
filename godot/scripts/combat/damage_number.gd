extends Node2D
## Floating damage number that pops up on hits.

var _velocity: Vector2
var _lifetime: float
var _timer: float

func show_damage(amount: float, is_crit: bool, pos: Vector2) -> void:
	global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))

	var label = Label.new()
	add_child(label)

	if is_crit:
		label.text = "%d!" % roundi(amount)
		label.add_theme_font_size_override("font_size", 24)
		label.modulate = Color(1.0, 0.9, 0.2) # gold
		_lifetime = 1.0
	else:
		label.text = str(roundi(amount))
		label.add_theme_font_size_override("font_size", 16)
		label.modulate = Color.WHITE
		_lifetime = 0.7

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer = _lifetime
	_velocity = Vector2(randf_range(-20, 20), -80)

func _process(delta: float) -> void:
	_timer -= delta
	position += _velocity * delta
	_velocity.y += 100 * delta # gravity

	modulate.a = clampf(_timer / (_lifetime * 0.5), 0.0, 1.0)

	if _timer <= 0.0:
		queue_free()
