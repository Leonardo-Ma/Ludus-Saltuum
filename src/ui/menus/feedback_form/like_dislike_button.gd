extends Control

@onready var like_button: Button = %LikeButton
@onready var dislike_button: Button = %DislikeButton


func _ready() -> void:
	like_button.toggled.connect(_on_like_toggled)
	dislike_button.toggled.connect(_on_dislike_toggled)


func _on_like_toggled(pressed: bool) -> void:
	like_button.theme_type_variation = "PrimaryIconButton" if pressed else ""


func _on_dislike_toggled(pressed: bool) -> void:
	dislike_button.theme_type_variation = "DangerIconButton" if pressed else ""
