## Confirmation popup for skipping the current level chunk
extends Control

@onready var _yes_button: TextureButton = %YesButton
@onready var _no_button: TextureButton = %NoButton


func _ready() -> void:
	hide()
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		return
	if not event.is_action_pressed("skip_level") or not ApplicationStateManager.is_gameplay_active():
		return
	_show_popup()
	get_viewport().set_input_as_handled()


func _on_yes_pressed() -> void:
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS)
	assert(player != null, "SkipLevelConfirm: no player found in " + name)
	LevelChunkManager.skip_current_chunk(player)
	_hide_popup()


func _on_no_pressed() -> void:
	_hide_popup()


func _show_popup() -> void:
	show()
	PauseManager.request_pause("skip_level_popup")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_popup() -> void:
	hide()
	PauseManager.release_pause("skip_level_popup")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
