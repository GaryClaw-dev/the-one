extends Node2D
## Floating damage number that pops up on hits. Supports object pooling.

var _velocity: Vector2
var _lifetime: float
var _timer: float
var _label: Label
var _pool: Node  # Reference to ObjectPool for self-return

const TYPE_COLORS = {
	"normal": Color.WHITE,
	"poison": Color(0.3, 0.9, 0.3),
	"burn": Color(1.0, 0.6, 0.1),
	"bleed": Color(0.9, 0.2, 0.2),
	"frost": Color(0.4, 0.7, 1.0),
	"lightning": Color(0.3, 0.9, 1.0),
	"curse": Color(0.7, 0.3, 0.9),
	"explosion": Color(1.0, 0.5, 0.1),
}

func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)

func show_damage(amount: float, is_crit: bool, pos: Vector2, damage_type: String = "normal") -> void:
	global_position = pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
	modulate.a = 1.0

	var color: Color = TYPE_COLORS.get(damage_type, Color.WHITE)

	if is_crit:
		_label.text = "%d!" % roundi(amount)
		_label.add_theme_font_size_override("font_size", 24)
		_label.modulate = Color(1.0, 0.9, 0.2)
		_lifetime = 1.0
	else:
		_label.text = str(roundi(amount))
		_label.add_theme_font_size_override("font_size", 16)
		_label.modulate = color
		_lifetime = 0.7

	_timer = _lifetime
	_velocity = Vector2(randf_range(-20, 20), -80)

func _process(delta: float) -> void:
	_timer -= delta
	position += _velocity * delta
	_velocity.y += 100 * delta

	modulate.a = clampf(_timer / (_lifetime * 0.5), 0.0, 1.0)

	if _timer <= 0.0:
		if _pool and _pool.has_method("release"):
			_pool.release(self)
		else:
			queue_free()
