## Stretches background texture to viewport while preserving parallax origin
extends Sprite2D


func _ready() -> void:
	get_viewport().size_changed.connect(_resize_background)
	_resize_background()


func _resize_background() -> void:
	assert(texture != null, "Missing texture in " + name)

	var viewport_size: Vector2 = get_viewport_rect().size
	var texture_size: Vector2 = texture.get_size()

	scale = viewport_size / texture_size

	var parallax: Parallax2D = get_parent() as Parallax2D
	assert(parallax != null, "Missing Parallax2D parent in " + name)
	parallax.repeat_size = Vector2(texture.get_width() * scale.x, 0)
