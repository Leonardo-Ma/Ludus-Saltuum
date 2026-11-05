@icon("uid://dj6mk6ic8le0p") # save.png
@abstract class_name SaveController
extends Node

## Hooks one save section into SaveManager save and reset lifecycle


func _ready() -> void:
	_child_ready()
	SaveManager.save_requested.connect(_on_save_requested)
	SaveManager.reset_requested.connect(initialize_new_save_data)
	# NOTE Loading may be done in another place, so not connected here


## Children override this instead of _ready()
@abstract func _child_ready() -> void


## Write own section into [param data]
@abstract func _on_save_requested(data: SaveData) -> void


## Restore defaults for new game
@abstract func initialize_new_save_data() -> void
