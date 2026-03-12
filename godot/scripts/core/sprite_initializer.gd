extends Node
## Attach to any scene root. On _ready, assigns placeholder sprites
## to any Sprite2D child that doesn't have a texture.

@export var shape: String = "circle" # "circle", "square", "diamond"
@export var sprite_size: int = 16
@export var sprite_color: Color = Color.WHITE

func _ready() -> void:
	_assign_sprites(get_parent())

func _assign_sprites(node: Node) -> void:
	if node is Sprite2D:
		var sprite = node as Sprite2D
		if sprite.texture == null:
			match shape:
				"circle":
					sprite.texture = PlaceholderSprites.create_circle(sprite_size, sprite_color)
				"square":
					sprite.texture = PlaceholderSprites.create_square(sprite_size, sprite_color)
				"diamond":
					sprite.texture = PlaceholderSprites.create_diamond(sprite_size, sprite_color)

	for child in node.get_children():
		_assign_sprites(child)
