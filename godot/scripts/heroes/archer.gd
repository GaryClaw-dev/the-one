extends HeroBase
## Archer: Rapid arrows, Eagle Eye passive (crit scales with kill streak)

@export var crit_bonus_per_kill: float = 0.02
@export var max_crit_bonus: float = 0.5
@export var spread_angle: float = 10.0

var _streak_crit_mod: Dictionary = {}

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	var proj_count = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_COUNT))

	if proj_count <= 1:
		fire_projectile(dir)
	else:
		var total_spread = spread_angle * (proj_count - 1)
		var start_angle = -total_spread / 2.0
		for i in range(proj_count):
			fire_projectile(dir, start_angle + spread_angle * i)

	# Flip sprite
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0

func on_kill_streak_increased(new_streak: int) -> void:
	# Eagle Eye: crit scales with kill streak
	if _streak_crit_mod:
		stats.remove_modifier(_streak_crit_mod)

	var bonus = minf(new_streak * crit_bonus_per_kill, max_crit_bonus)
	_streak_crit_mod = stats.add_modifier(
		StatSystem.StatType.CRIT_CHANCE,
		StatSystem.ModType.FLAT,
		bonus,
		self
	)

func on_kill_streak_reset() -> void:
	if _streak_crit_mod:
		stats.remove_modifier(_streak_crit_mod)
		_streak_crit_mod = {}
