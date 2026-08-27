## Coordinates open popups; single arbitration point for cancel input
class_name PopupsView
extends Control


func has_open_popup() -> bool:
	for popup: Control in get_children():
		if popup.visible:
			return true
	return false


func close_open_popup() -> void:
	for popup: Control in get_children():
		if popup.visible and popup.has_method("hide_popup"):
			popup.hide_popup()
			return
