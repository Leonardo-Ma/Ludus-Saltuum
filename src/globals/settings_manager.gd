## Loads and applies settings on startup
## All read and write passes here
extends Node

signal display_settings_changed
signal camera_settings_changed
signal audio_settings_changed

signal settings_reset

enum SettingsSection {
	NONE,
	AUDIO,
	HUD,
	CAMERA,
	VIDEO,
	ACCESSIBILITY,
	KEY_BINDINGS,
}

const _CONFIG_PATH: String = "user://settings.cfg"

const _SECTION_VIDEO: String = "video"
const _SECTION_AUDIO: String = "audio"
const _SECTION_UI: String = "ui"
const _SECTION_CAMERA: String = "camera"
const _SECTION_ACCESSIBILITY: String = "accessibility"
const _KEY_BINDINGS: String = "key_bindings"

const FPS_PRESETS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0]  # 0 = Unlimited

## Hardcoded project defaults, grouped by SettingsSection, used by reset_to_default()
## Each inner key must mirror an existing var declaration above
const _DEFAULTS: Dictionary = {
	SettingsSection.AUDIO:
	{
		&"volume_global": 1.0,
		&"volume_music": 1.0,
		&"volume_effects": 1.0,
		&"volume_ui": 1.0,
	},
	SettingsSection.HUD:
	{
		&"hud_visible": true,
	},
	SettingsSection.CAMERA:
	{
		&"camera_fov": 75.0,
		&"camera_distance": 3.0,
		&"mouse_sensitivity_horizontal": 0.2,
		&"mouse_sensitivity_vertical": 0.2,
		&"gamepad_sensitivity": 120.0,
		&"gamepad_invert_y": false,
	},
	SettingsSection.VIDEO:
	{
		&"brightness": 1.0,
		&"contrast": 1.0,
		&"saturation": 1.0,
		&"vsync_mode": DisplayServer.VSYNC_DISABLED,
		&"fps_limit": 90,
		&"window_mode": DisplayServer.WINDOW_MODE_FULLSCREEN,
	},
	SettingsSection.ACCESSIBILITY:
	{
		&"grayscale_enabled": false,
	},
	SettingsSection.KEY_BINDINGS:
	# TODO This is necessary for tab management, but about defaults, need to check if
	# godot saves default inputs
	{},
}

var volume_global: float = 1.0
var volume_music: float = 1.0
var volume_effects: float = 1.0
var volume_ui: float = 1.0

var hud_visible: bool = true

var resolution: Vector2i = Vector2i(1920, 1080)

var environment: Environment = preload("uid://dsshmu8vrps28")
var brightness: float = 1.0
var contrast: float = 1.0
var saturation: float = 1.0
var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_DISABLED
var fps_limit: int = 90
var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED

var grayscale_enabled: bool = false

## Camera FOV, in degrees
var camera_fov: float = 75.0
## SpringArm3D spring_length, in meters
var camera_distance: float = 3.0
var mouse_sensitivity_horizontal: float = 0.2
var mouse_sensitivity_vertical: float = 0.2
var gamepad_sensitivity: float = 120.0
var gamepad_invert_y: bool = false

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	get_window().size_changed.connect(_on_window_size_changed)

	_load()
	apply_all()


func apply_all() -> void:
	apply_display()
	apply_audio()
	apply_camera()


func apply_display() -> void:
	DisplayServer.window_set_mode(window_mode)

	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		get_window().size = resolution

	environment.adjustment_brightness = brightness
	environment.adjustment_contrast = contrast
	environment.adjustment_saturation = saturation

	DisplayServer.window_set_vsync_mode(vsync_mode)

	Engine.max_fps = fps_limit

	display_settings_changed.emit()


func apply_audio() -> void:
	SoundManager.set_category_volume(SoundManager.SoundCategory.GLOBAL, linear_to_db(volume_global))
	SoundManager.set_category_volume(SoundManager.SoundCategory.MUSIC, linear_to_db(volume_music))
	SoundManager.set_category_volume(SoundManager.SoundCategory.SFX, linear_to_db(volume_effects))
	SoundManager.set_category_volume(SoundManager.SoundCategory.UI, linear_to_db(volume_ui))

	audio_settings_changed.emit()


func apply_camera() -> void:
	camera_settings_changed.emit()


func save() -> void:
	_config.set_value(_SECTION_VIDEO, "resolution", resolution)
	_config.set_value(_SECTION_VIDEO, "window_mode", window_mode)

	_config.set_value(_SECTION_AUDIO, "volume_global", volume_global)
	_config.set_value(_SECTION_AUDIO, "volume_music", volume_music)
	_config.set_value(_SECTION_AUDIO, "volume_effects", volume_effects)
	_config.set_value(_SECTION_AUDIO, "volume_ui", volume_ui)

	_config.set_value(_SECTION_UI, "hud_visible", hud_visible)

	_config.set_value(_SECTION_VIDEO, "brightness", brightness)
	_config.set_value(_SECTION_VIDEO, "contrast", contrast)
	_config.set_value(_SECTION_VIDEO, "saturation", saturation)
	_config.set_value(_SECTION_VIDEO, "vsync_mode", vsync_mode)
	_config.set_value(_SECTION_VIDEO, "fps_limit", fps_limit)

	_config.set_value(_SECTION_VIDEO, "grayscale_enabled", grayscale_enabled)

	_config.set_value(_SECTION_CAMERA, "camera_fov", camera_fov)
	_config.set_value(_SECTION_CAMERA, "camera_distance", camera_distance)
	_config.set_value(_SECTION_CAMERA, "mouse_sensitivity_horizontal", mouse_sensitivity_horizontal)
	_config.set_value(_SECTION_CAMERA, "mouse_sensitivity_vertical", mouse_sensitivity_vertical)
	_config.set_value(_SECTION_CAMERA, "gamepad_sensitivity", gamepad_sensitivity)
	_config.set_value(_SECTION_CAMERA, "gamepad_invert_y", gamepad_invert_y)

	_config.save(_CONFIG_PATH)


# TODO Should all these get_values get the _DEFAULTS or be null? Don't remember the source of it
func _load() -> void:
	if _config.load(_CONFIG_PATH) != OK:
		resolution = get_window().size
		return

	resolution = _config.get_value(_SECTION_VIDEO, "resolution", get_window().size)
	window_mode = _config.get_value(_SECTION_VIDEO, "window_mode", DisplayServer.WINDOW_MODE_WINDOWED)

	volume_global = _config.get_value(_SECTION_AUDIO, "volume_global", 1.0)
	volume_music = _config.get_value(_SECTION_AUDIO, "volume_music", 1.0)
	volume_effects = _config.get_value(_SECTION_AUDIO, "volume_effects", 1.0)
	volume_ui = _config.get_value(_SECTION_AUDIO, "volume_ui", 1.0)

	hud_visible = _config.get_value(_SECTION_UI, "hud_visible", true)

	brightness = _config.get_value(_SECTION_VIDEO, "brightness", 1.0)
	contrast = _config.get_value(_SECTION_VIDEO, "contrast", 1.0)
	saturation = _config.get_value(_SECTION_VIDEO, "saturation", 1.0)
	vsync_mode = _config.get_value(_SECTION_VIDEO, "vsync_mode", DisplayServer.VSYNC_DISABLED)
	fps_limit = _config.get_value(_SECTION_VIDEO, "fps_limit", 90)
	grayscale_enabled = _config.get_value(_SECTION_VIDEO, "grayscale_enabled", false)

	camera_fov = _config.get_value(_SECTION_CAMERA, "camera_fov", 75.0)
	camera_distance = _config.get_value(_SECTION_CAMERA, "camera_distance", 3.0)
	mouse_sensitivity_horizontal = _config.get_value(_SECTION_CAMERA, "mouse_sensitivity_horizontal", 0.2)
	mouse_sensitivity_vertical = _config.get_value(_SECTION_CAMERA, "mouse_sensitivity_vertical", 0.2)
	gamepad_sensitivity = _config.get_value(_SECTION_CAMERA, "gamepad_sensitivity", 120.0)
	gamepad_invert_y = _config.get_value(_SECTION_CAMERA, "gamepad_invert_y", false)


## Resets settings for [param section] to hardcoded default
## Resets every section if section is [constant SettingsSection.NONE]
func reset_to_default(section: SettingsSection = SettingsSection.NONE) -> void:
	var sections_to_reset: Array = _DEFAULTS.keys() if section == SettingsSection.NONE else [section]
	for target_section: SettingsSection in sections_to_reset:
		assert(_DEFAULTS.has(target_section), "SettingsManager: no defaults for section " + str(target_section))
		for key: StringName in _DEFAULTS[target_section]:
			set(key, _DEFAULTS[target_section][key])
	apply_all()
	save()
	settings_reset.emit()


# TODO BUG This fails if windowed but maximized. Also doesn't properly recognize screen resolution limits
func _on_window_size_changed() -> void:
	if window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		return

	var new_resolution: Vector2i = get_window().size

	if resolution == new_resolution:
		return

	resolution = new_resolution
	display_settings_changed.emit()
