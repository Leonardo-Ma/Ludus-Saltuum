extends TextureRect

@onready var anonymous_feedback_toggle: CheckButton = %AnonymousFeedbackToggle


func _ready() -> void:
	if SteamWorks.steam_enabled:
		SteamWorks.avatar_loaded.connect(_on_loaded_avatar)
		SteamWorks.request_small_avatar()
		visible = true
		anonymous_feedback_toggle.toggled.connect(_on_anonymous_feedback)


func _on_anonymous_feedback(toggled: bool) -> void:
	visible = !toggled


func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	print("Avatar for user: %s" % user_id)
	print("Size: %s" % avatar_size)

	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)

	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)

	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)

	# Set the texture to a Sprite, TextureRect, etc.
	texture = avatar_texture
