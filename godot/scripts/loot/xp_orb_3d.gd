extends Area3D
## 3D XP orb. Auto-flies to hero.

var _xp_value: float = 10.0
var _collected: bool = false
var _fly_speed: float = 0.0
var _delay: float = 0.0
var _bob_time: float = 0.0

func _ready() -> void:
	add_to_group("xp_orb")

func initialize(xp_value: float) -> void:
	_xp_value = xp_value
	_collected = false
	_fly_speed = 0.0
	_delay = randf_range(0.1, 0.3)
	_bob_time = randf() * TAU

func _physics_process(delta: float) -> void:
	if _collected:
		return

	# Gentle bob animation
	_bob_time += delta * 3.0
	var mesh = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		mesh.position.y = 0.3 + sin(_bob_time) * 0.15

	var hero = get_tree().get_first_node_in_group("hero")
	if not hero or not hero is Node3D:
		return

	if _delay > 0.0:
		_delay -= delta
		return

	_fly_speed += 80.0 * delta
	_fly_speed = minf(_fly_speed, 60.0)

	var hero_pos = (hero as Node3D).global_position
	var dir = (hero_pos - global_position)
	dir.y = 0
	var dist = dir.length()

	if dist > 0.1:
		position += dir.normalized() * _fly_speed * delta

	if dist < 1.5:
		collect(hero)

func collect(hero: Node = null) -> void:
	if _collected:
		return
	_collected = true
	var xp_mult = 1.0
	# Check if hero has stats for XP multiplier
	if hero and hero.get("stats"):
		xp_mult = maxf(hero.stats.get_stat(StatSystem.StatType.XP_MULTIPLIER), 1.0)
	GameEvents.xp_gained.emit(_xp_value * xp_mult)
	queue_free()
