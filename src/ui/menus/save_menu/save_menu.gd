## Populates and refreshes all save file item slots on open
class_name SaveMenu
extends Control

@onready var _slot_items: Array[Node] = %SaveSlotsContainer.get_children()


func _ready() -> void:
	for slot: SaveFileItem in _slot_items:
		slot.play_requested.connect(_on_save_file_item_play_requested)
	for slot: SaveFileItem in _slot_items:
		slot.delete_requested.connect(_on_save_file_item_delete_requested)
	SaveManager.save_changed.connect(_on_save_changed)
	visibility_changed.connect(_on_visibility_changed)


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


func _on_save_file_item_play_requested(slot_index: int) -> void:
	if SaveManager.has_save(slot_index):
		SaveManager.load_from_slot(slot_index)
	else:
		SaveManager.reset_save(slot_index)

	ApplicationStateManager.request_play_from_save()


func _on_save_file_item_delete_requested(slot_index: int) -> void:
	# TODO Add confirmation popup
	SaveManager.delete_slot(slot_index)
