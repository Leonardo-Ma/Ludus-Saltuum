## Populates and refreshes all save file item slots on open
extends Control

@onready var _return_button: TextureButton = %ReturnButton
@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _slot_items: Array[Node] = %SaveSlotsContainer.get_children()


func _ready() -> void:
	_return_button.pressed.connect(_on_return_pressed)
	SaveManager.save_changed.connect(_on_save_changed)
	visibility_changed.connect(_on_visibility_changed)

	for item: Node in _slot_items:
		(item as SaveFileItem).item_focused.connect(_scroll.ensure_control_visible.bind(item as Control))


func _on_visibility_changed() -> void:
	if visible:
		_refresh_all()


func _refresh_all() -> void:
	for i: int in _slot_items.size():
		var item: SaveFileItem = _slot_items[i] as SaveFileItem
		assert(item != null, "SaveMenu: child %d is not SaveFileItem in %s" % [i, name])
		item.setup(i, SaveManager.get_slot_data(i))


func _on_save_changed(slot_index: int) -> void:
	if not visible or slot_index >= _slot_items.size():
		return
	var item: SaveFileItem = _slot_items[slot_index] as SaveFileItem
	item.setup(slot_index, SaveManager.get_slot_data(slot_index))


func _on_return_pressed() -> void:
	ApplicationStateManager.request_main_menu()
