extends Area2D
## XP orb dropped by enemies. Auto-flies to hero since hero is stationary.

var _xp_value: float = 10.0
var _collected: bool = false
var _fly_speed: float = 0.0
var _delay: float = 0.0

func _ready() -> void:
	add_to_group("xp_orb")

func initialize(xp_value: float) -> void:
	_xp_value = xp_value
	_collected = false
	_fly_speed = 0.0
	_delay = randf_range(0.1, 0.3)
	modulate.a = 1.0

func _physics_process(delta: float) -> void:
	if _collected:
		return

	var hero = get_tree().get_first_node_in_group("hero")
	if not hero:
		return

	if _delay > 0.0:
		_delay -= delta
		return

	_fly_speed += 800.0 * delta
	_fly_speed = minf(_fly_speed, 600.0)

	var dir = (hero.global_position - global_position).normalized()
	position += dir * _fly_speed * delta

	var dist = global_position.distance_to(hero.global_position)
	if dist < 15.0:
		collect(hero)

func collect(hero: Node2D = null) -> void:
	if _collected:
		return
	_collected = true
	var xp_mult = 1.0
	if hero and hero is HeroBase:
		xp_mult = maxf(hero.stats.get_stat(StatSystem.StatType.XP_MULTIPLIER), 1.0)
	GameEvents.xp_gained.emit(_xp_value * xp_mult)
	queue_free()
