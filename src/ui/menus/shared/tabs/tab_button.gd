class_name TabButton
extends UIButton

## Toggle button revealing its panel when pressed, managed by TabController

signal tab_activated(tab: TabButton)

@export var panel: Control


func _button_ready() -> void:
	assert(toggle_mode == true, "Enable toggle mode for " + name)


func _button_pressed() -> void:
	tab_activated.emit(self)
