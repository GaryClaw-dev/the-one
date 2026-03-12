extends HeroBase
## Wizard: AoE arcane bolts, Arcane Overflow passive (damage scales with consecutive casts)

@export var spread_angle: float = 15.0

const OVERFLOW_WINDOW: float = 3.0
const OVERFLOW_BONUS_PER_CAST: float = 0.10
const OVERFLOW_MAX_BONUS: float = 1.0
const BOLT_COLOR: Color = Color(0.6, 0.3, 0.9)

var _cast_count: int = 0
var _cast_timer: float = 0.0
var _overflow_mod: Dictionary = {}

func _ready() -> void:
	super._ready()
	# Wizard has base AoE splash radius
	stats.set_base(StatSystem.StatType.AOE_RADIUS, 40.0)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	_update_arcane_overflow(delta)

func perform_attack(target_node: Node2D) -> void:
	# Arcane Overflow: increment cast counter
	_cast_count += 1
	_cast_timer = OVERFLOW_WINDOW
	_apply_overflow_bonus()

	var dir = (target_node.global_position - global_position).normalized()
	var aoe = stats.get_stat(StatSystem.StatType.AOE_RADIUS)
	var proj_count = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_COUNT))

	if proj_count <= 1:
		var proj = fire_projectile(dir, 0.0, aoe)
		if proj:
			proj.modulate = BOLT_COLOR
	else:
		var total_spread = spread_angle * (proj_count - 1)
		var start_angle = -total_spread / 2.0
		for i in range(proj_count):
			var proj = fire_projectile(dir, start_angle + spread_angle * i, aoe)
			if proj:
				proj.modulate = BOLT_COLOR

	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0

func _apply_overflow_bonus() -> void:
	if _overflow_mod:
		stats.remove_modifier(_overflow_mod)
		_overflow_mod = {}

	var bonus = minf((_cast_count - 1) * OVERFLOW_BONUS_PER_CAST, OVERFLOW_MAX_BONUS)
	if bonus > 0.0:
		_overflow_mod = stats.add_modifier(
			StatSystem.StatType.ATTACK_DAMAGE,
			StatSystem.ModType.PERCENT_ADD,
			bonus,
			self
		)

func _update_arcane_overflow(delta: float) -> void:
	if _cast_count <= 0:
		return
	_cast_timer -= delta
	if _cast_timer <= 0.0:
		_cast_count = 0
		if _overflow_mod:
			stats.remove_modifier(_overflow_mod)
			_overflow_mod = {}
