extends "res://scripts/heroes/hero_3d_base.gd"
## 3D Noob: Throws projectiles at nearest enemy.

func perform_attack(target_node: Node3D) -> void:
	var dir = (target_node.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	var proj_count = roundi(stats.get_stat(StatSystem.StatType.PROJECTILE_COUNT))
	if proj_count <= 1:
		fire_projectile(dir, 1.0, target_node)
	else:
		for i in range(proj_count):
			var side = 1.0 if i % 2 == 1 else -1.0
			var angle = ceili(i / 2.0) * 0.15 * side
			var rotated_dir = dir.rotated(Vector3.UP, angle)
			fire_projectile(rotated_dir, 1.0, target_node)
