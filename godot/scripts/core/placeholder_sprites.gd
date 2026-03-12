class_name PlaceholderSprites
extends RefCounted
## Generates placeholder circle/square textures at runtime.
## Attach to nodes that need a visual but don't have a sprite yet.

static func create_circle(radius: int = 16, color: Color = Color.WHITE) -> ImageTexture:
	var size = radius * 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)

	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha = clampf(1.0 - (dist - radius + 1.5) / 1.5, 0.0, 1.0)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))

	return ImageTexture.create_from_image(image)

static func create_square(size: int = 24, color: Color = Color.WHITE) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)

static func create_diamond(size: int = 16, color: Color = Color.WHITE) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2

	for x in range(size):
		for y in range(size):
			var dist = absi(x - center) + absi(y - center)
			if dist <= center:
				image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)
