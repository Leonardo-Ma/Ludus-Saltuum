class_name ConfirmationPopup
extends PopupTemplate

## Displays icon-based confirmation choices and emits selected result

signal choice_made(confirmed: bool)

@export var icon_view_scene: PackedScene

@onready var _icon_container: HBoxContainer = %IconContainer
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton

var _is_active: bool = false


func _ready() -> void:
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


func prepare_confirmation(icons: Array[CompressedTexture2D]) -> void:
	assert(not _is_active, "Confirmation already active in " + name)

	for index: int in range(_icon_container.get_child_count(), icons.size()):
		var icon_view: TextureRect = icon_view_scene.instantiate()
		_icon_container.add_child(icon_view)

	for index: int in _icon_container.get_child_count():
		var icon_view: TextureRect = _icon_container.get_child(index)
		icon_view.texture = icons[index] if index < icons.size() else null
		icon_view.visible = index < icons.size()

	_is_active = true


func hide_popup() -> void:
	_finish_confirmation(false)


func _finish_confirmation(confirmed: bool) -> void:
	if not _is_active:
		hide()
		return

	_is_active = false
	hide()
	choice_made.emit(confirmed)


func _on_yes_pressed() -> void:
	_finish_confirmation(true)


func _on_no_pressed() -> void:
	_finish_confirmation(false)
