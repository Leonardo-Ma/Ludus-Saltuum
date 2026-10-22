## Displays icon-based confirmation choices and emits selected result
class_name ConfirmationPopup
extends PopupTemplate

signal choice_made(confirmed: bool)

@export var icon_view_scene: PackedScene

@onready var _icon_container: HBoxContainer = %IconContainer
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton

var _is_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


func prepare_confirmation(icons: Array[CompressedTexture2D]) -> void:
	assert(not _is_active, "Confirmation already active in " + name)

	for child: Node in _icon_container.get_children():
		_icon_container.remove_child(child)
		child.queue_free()

	for icon_texture: CompressedTexture2D in icons:
		var icon_view: ConfirmationIcon = icon_view_scene.instantiate() as ConfirmationIcon
		assert(icon_view != null, "Invalid icon view scene in " + name)
		icon_view.texture = icon_texture
		_icon_container.add_child(icon_view)

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
