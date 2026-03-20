extends HeroBase
## The Noob: Throws rocks. Weak but everyone starts here.

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	var proj_count = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_COUNT))
	if proj_count <= 1:
		fire_projectile(dir, 0.0, 0.0, 1.0, target_node)
	else:
		for i in range(proj_count):
			var side = 1.0 if i % 2 == 1 else -1.0
			var offset = ceili(i / 2.0) * 10.0 * side
			fire_projectile(dir, offset, 0.0, 1.0, target_node)
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0
