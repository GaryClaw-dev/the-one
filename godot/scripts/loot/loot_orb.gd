extends Area2D
## Loot orb that triggers the Gamba system when collected.

var _lifetime: float = 10.0
var _base_pos: Vector2

func _ready() -> void:
	add_to_group("loot_orb")
	_base_pos = position

func _process(delta: float) -> void:
	_lifetime -= delta

	# Bob up and down
	var bob = sin(Time.get_ticks_msec() * 0.003) * 5.0
	position.y = _base_pos.y + bob

	# Pulse glow
	var pulse = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.005)
	modulate = Color(1.0, 0.9, 0.3, pulse)

	# Blink when about to expire
	if _lifetime < 3.0:
		var blink = 1.0 if sin(Time.get_ticks_msec() * 0.02) > 0 else 0.3
		modulate.a *= blink

	if _lifetime <= 0.0:
		queue_free()

func collect() -> void:
	GameEvents.loot_orb_picked_up.emit()
	queue_free()
