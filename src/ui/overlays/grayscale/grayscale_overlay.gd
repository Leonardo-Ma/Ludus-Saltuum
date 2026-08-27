## Full-screen grayscale toggle, affects world and UI
extends CanvasLayer

@onready var _overlay_rect: ColorRect = %GrayscaleRect


func _ready() -> void:
	_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	SettingsManager.accessibility_settings_changed.connect(_on_accessibility_settings_changed)
	@warning_ignore("missing_await")
	_precompile_shader()
	_on_accessibility_settings_changed()


func _on_accessibility_settings_changed() -> void:
	visible = SettingsManager.grayscale_enabled


# TODO Move this to shader warmup script in main scene
## Force the shader to compile at startup instead of on first toggle to avoid stutter
func _precompile_shader() -> void:
	visible = true
	_overlay_rect.modulate.a = 0.0
	await RenderingServer.frame_post_draw
	_overlay_rect.modulate.a = 1.0
	visible = SettingsManager.grayscale_enabled
