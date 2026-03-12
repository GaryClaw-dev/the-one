extends Area2D
## XP orb dropped by enemies. Magnetizes toward hero within pickup range.

var _xp_value: float = 10.0
var _magnetized: bool = false
var _bounce_timer: float = 0.15
var _bounce_dir: Vector2

func _ready() -> void:
	add_to_group("xp_orb")
	_bounce_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 100.0

func initialize(xp_value: float) -> void:
	_xp_value = xp_value

func _physics_process(delta: float) -> void:
	var hero = get_tree().get_first_node_in_group("hero")
	if not hero:
		return

	# Brief bounce on spawn
	if _bounce_timer > 0.0:
		_bounce_timer -= delta
		position += _bounce_dir * delta
		return

	var dist = global_position.distance_to(hero.global_position)
	var pickup_range = 80.0
	if hero is HeroBase:
		pickup_range = hero.stats.get_stat(StatSystem.StatType.PICKUP_RANGE)

	if dist < pickup_range:
		_magnetized = true

	if _magnetized:
		var dir = (hero.global_position - global_position).normalized()
		var speed = 400.0 * (1.0 + (pickup_range - dist) / pickup_range)
		position += dir * speed * delta

		if dist < 15.0:
			collect(hero)

func collect(hero: Node2D = null) -> void:
	var xp_mult = 1.0
	if hero and hero is HeroBase:
		xp_mult = maxf(hero.stats.get_stat(StatSystem.StatType.XP_MULTIPLIER), 1.0)
	GameEvents.xp_gained.emit(_xp_value * xp_mult)
	queue_free()
