extends Node2D
## Tornado vortex that pulls nearby enemies toward its center.

func _process(delta: float) -> void:
	var radius = get_meta("pull_radius", 60.0)
	var strength = get_meta("pull_strength", 60.0)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue
		var dir = global_position - enemy.global_position
		var dist = dir.length()
		if dist <= radius and dist > 5.0:
			var pull = dir.normalized() * strength * delta
			enemy.global_position += pull
