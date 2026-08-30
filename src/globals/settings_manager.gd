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

const _SECTION_NAMES: Dictionary[SettingsSection, String] = {
	SettingsSection.NONE: "",
	SettingsSection.GAMEPLAY: "gameplay",
	SettingsSection.AUDIO: "audio",
	SettingsSection.HUD: "hud",
	SettingsSection.CAMERA: "camera",
	SettingsSection.VIDEO: "video",
	SettingsSection.ACCESSIBILITY: "accessibility",
	SettingsSection.KEY_BINDINGS: "key_bindings",
}

const _CONFIG_PATH: String = "user://settings.cfg"

const FPS_PRESETS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0]  # 0 = Unlimited

## Hardcoded project defaults, grouped by SettingsSection, used by reset_to_default()
## Each inner key must mirror an existing var declaration above
const _DEFAULTS: Dictionary = {
	SettingsSection.GAMEPLAY:
	# To be added options here
	{},
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
		&"resolution": null,  # Can't properly know what is the resolution
		&"window_mode": DisplayServer.WINDOW_MODE_WINDOWED,
		&"vsync_mode": DisplayServer.VSYNC_DISABLED,
		&"fps_limit": 90,
		&"brightness": 1.0,
		#&"contrast": 1.0,
		#&"saturation": 1.0,
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
#var contrast: float = 1.0
#var saturation: float = 1.0
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

var _section_to_apply_function: Dictionary[SettingsSection, Callable] = {
	SettingsSection.GAMEPLAY: apply_gameplay,
	SettingsSection.AUDIO: apply_audio,
	SettingsSection.HUD: apply_hud,
	SettingsSection.CAMERA: apply_camera,
	SettingsSection.VIDEO: apply_video,
	SettingsSection.ACCESSIBILITY: apply_accessibility,
}


func _ready() -> void:
	get_window().size_changed.connect(_on_window_size_changed)

	_load()
	apply_all()


func apply_all() -> void:
	apply_gameplay()
	apply_audio()
	apply_hud()
	apply_camera()
	apply_video()
	apply_accessibility()


func apply_gameplay() -> void:
	gameplay_settings_changed.emit()


func apply_audio() -> void:
	SoundManager.set_category_volume(SoundManager.SoundCategory.GLOBAL, linear_to_db(volume_global))
	SoundManager.set_category_volume(SoundManager.SoundCategory.MUSIC, linear_to_db(volume_music))
	SoundManager.set_category_volume(SoundManager.SoundCategory.SFX, linear_to_db(volume_effects))
	SoundManager.set_category_volume(SoundManager.SoundCategory.UI, linear_to_db(volume_ui))

	audio_settings_changed.emit()


func apply_hud() -> void:
	hud_settings_changed.emit()


func apply_camera() -> void:
	camera_settings_changed.emit()


func apply_video() -> void:
	DisplayServer.window_set_mode(window_mode)

	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		get_window().size = resolution

	environment.adjustment_brightness = brightness
	#environment.adjustment_contrast = contrast
	#environment.adjustment_saturation = saturation

	DisplayServer.window_set_vsync_mode(vsync_mode)

	Engine.max_fps = fps_limit

	video_settings_changed.emit()


func apply_accessibility() -> void:
	accessibility_settings_changed.emit()


func save() -> void:
	for section: SettingsSection in _DEFAULTS:
		for key: StringName in _DEFAULTS[section]:
			_config.set_value(_SECTION_NAMES[section], key, get(key))

	_config.save(_CONFIG_PATH)


func _load() -> void:
	if _config.load(_CONFIG_PATH) != OK:
		resolution = get_window().size
		return

	for section: SettingsSection in _DEFAULTS:
		for key: StringName in _DEFAULTS[section]:
			set(
				key,
				(
					_config
					. get_value(
						_SECTION_NAMES[section],
						key,
						_DEFAULTS[section][key],
					)
				),
			)


## Resets settings for [param section] to hardcoded default
## Resets every section if section is [constant SettingsSection.NONE]
func reset_to_default(section: SettingsSection = SettingsSection.NONE) -> void:
	var sections_to_reset: Array = _DEFAULTS.keys() if section == SettingsSection.NONE else [section]
	for target_section: SettingsSection in sections_to_reset:
		assert(_DEFAULTS.has(target_section), "SettingsManager: no defaults for section " + str(target_section))
		for key: StringName in _DEFAULTS[target_section]:
			set(key, _DEFAULTS[target_section][key])
	for target_section: SettingsSection in sections_to_reset:
		_apply_section(target_section)
	settings_reset.emit()
	save()


func _apply_section(section: SettingsSection) -> void:
	var func_ref: Callable = _section_to_apply_function.get(section, Callable())
	if func_ref.is_valid():
		func_ref.call()


# TODO BUG This fails if windowed but maximized. Also doesn't properly recognize screen resolution limits
func _on_window_size_changed() -> void:
	if window_mode != DisplayServer.WINDOW_MODE_WINDOWED:
		return

	var new_resolution: Vector2i = get_window().size

	if resolution == new_resolution:
		return

	resolution = new_resolution
	video_settings_changed.emit()
