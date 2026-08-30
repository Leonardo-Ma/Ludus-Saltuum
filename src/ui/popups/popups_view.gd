## Coordinates open popups; single arbitration point for cancel input
class_name PopupsView
extends Control


func _ready() -> void:
	for popup: PopupTemplate in get_children():
		assert(popup)


func has_open_popup() -> bool:
	for popup: PopupTemplate in get_children():
		if popup.visible:
			return true
	return false


func close_open_popup() -> void:
	for popup: PopupTemplate in get_children():
		if popup.visible:
			popup.hide_popup()
			return
