extends HeroBase
## The Noob: Throws rocks. Weak but everyone starts here.

func perform_attack(target_node: Node2D) -> void:
	var dir = (target_node.global_position - global_position).normalized()
	fire_projectile(dir)
	var sprite = $Sprite2D as Sprite2D
	if sprite:
		sprite.flip_h = dir.x < 0
