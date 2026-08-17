## Toggles HUD and HUD preview visibility
extends CheckButton

@export var preview_hud: Control


func _ready() -> void:
	assert(preview_hud != null, "HUDVisibilityToggle: preview_hud not assigned in " + name)
	button_pressed = UIManager.hud_visible
	preview_hud.visible = UIManager.hud_visible
	toggled.connect(_on_toggled)


func _on_toggled(toggled_on: bool) -> void:
	UIManager.set_hud_visible(toggled_on)
	preview_hud.visible = toggled_on
