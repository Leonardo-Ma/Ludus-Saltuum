## Loads and applies settings on startup
## All read and write passes here
extends Node

signal gameplay_settings_changed
signal audio_settings_changed
signal hud_settings_changed
signal camera_settings_changed
signal video_settings_changed
signal accessibility_settings_changed

signal settings_reset

enum SettingsSection {
	NONE = 0,
	GAMEPLAY = 1,
	AUDIO = 2,
	HUD = 3,
	CAMERA = 4,
	VIDEO = 5,
	ACCESSIBILITY = 6,
	KEY_BINDINGS = 7,
}

const _SETTINGS_PATH: String = "user://settings.tres"

## Seconds without size change before a window resize counts as finished
const _WINDOW_RESIZE_SETTLE_TIME: float = 0.5

var settings: GameSettings = GameSettings.new()

## Not user-configurable, infrastructure the video settings are applied onto
var environment: Environment = preload("uid://dsshmu8vrps28")

var _resize_settle_timer: Timer


func _ready() -> void:
	# TODO Move timer to respective UI resize code?
	_resize_settle_timer = Timer.new()
	_resize_settle_timer.one_shot = true
	_resize_settle_timer.wait_time = _WINDOW_RESIZE_SETTLE_TIME
	_resize_settle_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_resize_settle_timer.timeout.connect(_on_window_resize_settled)
	add_child(_resize_settle_timer)

	get_window().size_changed.connect(_on_window_size_changed)

	_load()
	apply_all()

#region Apply and Reset
func apply_all() -> void:
	apply_gameplay()
	apply_audio()
	apply_hud()
	apply_camera()
	apply_window()
	apply_video()
	apply_accessibility()


func apply_gameplay() -> void:
	gameplay_settings_changed.emit()


func apply_audio() -> void:
	SoundManager.set_category_volume(SoundManager.SoundCategory.GLOBAL, linear_to_db(settings.audio.volume_global) + settings.audio.VOLUME_DB_MAX)
	SoundManager.set_category_volume(SoundManager.SoundCategory.MUSIC, linear_to_db(settings.audio.volume_music) + settings.audio.VOLUME_DB_MAX)
	SoundManager.set_category_volume(SoundManager.SoundCategory.SFX, linear_to_db(settings.audio.volume_effects) + settings.audio.VOLUME_DB_MAX)
	SoundManager.set_category_volume(SoundManager.SoundCategory.UI, linear_to_db(settings.audio.volume_ui) + settings.audio.VOLUME_DB_MAX)

	audio_settings_changed.emit()


func apply_hud() -> void:
	hud_settings_changed.emit()


func apply_camera() -> void:
	camera_settings_changed.emit()


## Window mode and size only. Kept separate from video so brightness/vsync/fps changes don't interfere resize or force a mode/size reset
func apply_window() -> void:
	var window: Window = get_window()
	DisplayServer.window_set_mode(settings.video.window_mode)

	if settings.video.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		window.borderless = false
		window.size = settings.video.windowed_size
	elif settings.video.window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		window.borderless = false

	video_settings_changed.emit()


func apply_video() -> void:
	environment.adjustment_brightness = settings.video.brightness
	#environment.adjustment_contrast = settings.video.contrast
	#environment.adjustment_saturation = settings.video.saturation
	DisplayServer.window_set_vsync_mode(settings.video.vsync_mode)

	Engine.max_fps = settings.video.fps_limit

	video_settings_changed.emit()


func apply_accessibility() -> void:
	accessibility_settings_changed.emit()


func reset_to_default(section: SettingsSection = SettingsSection.NONE) -> void:
	match section:
		SettingsSection.NONE:
			settings = GameSettings.new()
			apply_all()
		SettingsSection.GAMEPLAY:
			settings.gameplay = GameplaySettings.new()
			apply_gameplay()
		SettingsSection.AUDIO:
			settings.audio = AudioSettings.new()
			apply_audio()
		SettingsSection.HUD:
			settings.hud = HUDSettings.new()
			apply_hud()
		SettingsSection.CAMERA:
			settings.camera = CameraSettings.new()
			apply_camera()
		SettingsSection.VIDEO:
			settings.video = VideoSettings.new()
			apply_window()
			apply_video()
		SettingsSection.ACCESSIBILITY:
			settings.accessibility = AccessibilitySettings.new()
			apply_accessibility()
		SettingsSection.KEY_BINDINGS:
			settings.key_bindings = KeyBindingsSettings.new()

	settings_reset.emit()
	save()
#endregion

#region Video
func set_windowed_size(size: Vector2i) -> void:
	settings.video.windowed_size = size

	if settings.video.window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		get_window().size = size

	save()
	video_settings_changed.emit()


func get_windowed_resolutions() -> Array[Vector2i]:
	var screen_size: Vector2i = DisplayServer.screen_get_size(get_window().current_screen)
	var resolutions: Array[Vector2i] = []

	for resolution: Vector2i in VideoSettings.WINDOWED_RESOLUTIONS:
		if resolution.x <= screen_size.x and resolution.y <= screen_size.y:
			resolutions.append(resolution)

	var current_size: Vector2i = settings.video.windowed_size
	if current_size.x > 0 and current_size.y > 0:
		if current_size.x <= screen_size.x and current_size.y <= screen_size.y:
			if not resolutions.has(current_size):
				resolutions.append(current_size)

	return resolutions


func get_current_display_resolution() -> Vector2i:
	return DisplayServer.screen_get_size(get_window().current_screen)


func is_windowed_resolution_editable() -> bool:
	return settings.video.window_mode == DisplayServer.WINDOW_MODE_WINDOWED


func _on_window_size_changed() -> void:
	_resize_settle_timer.start()


# TODO BUG This fails if windowed but maximized. Also doesn't properly recognize screen resolution limits
## Commits and persists window size only once resizing stopped and window is actually windowed
func _on_window_resize_settled() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return

	var new_size: Vector2i = get_window().size
	if settings.video.windowed_size == new_size:
		return

	settings.video.windowed_size = new_size
	save()
	video_settings_changed.emit()
#endregion

#region Save and Load
func save() -> void:
	var error: Error = ResourceSaver.save(settings, _SETTINGS_PATH)
	assert(error == OK, "Failed to save settings in " + name)


func _load() -> void:
	if not ResourceLoader.exists(_SETTINGS_PATH):
		return

	var loaded_settings: Resource = ResourceLoader.load(_SETTINGS_PATH)
	assert(loaded_settings is GameSettings, "Invalid settings resource in " + name)

	settings = loaded_settings as GameSettings
#endregion
