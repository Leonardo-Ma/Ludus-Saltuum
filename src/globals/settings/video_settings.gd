class_name VideoSettings
extends Resource

## Stores video preferences and supported windowed display sizes

const FPS_PRESETS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0] # 0 = Unlimited

const WINDOWED_RESOLUTIONS: Array[Vector2i] = [
	# 16:9
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
	# 16:10
	Vector2i(1280, 800),
	Vector2i(1920, 1200),
	Vector2i(2560, 1600),
	# Ultrawide 21:9
	Vector2i(2560, 1080),
	Vector2i(3440, 1440),
	# Super ultrawide 32:9
	Vector2i(3840, 1080),
	Vector2i(5120, 1440),
]

## Persisted only while window_mode is WINDOWED, switching to fullscreen doesn't overwrite
@export var windowed_size: Vector2i = Vector2i(1920, 1080)

@export var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN

@export var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_DISABLED

@export var fps_limit: int = 90

@export var brightness: float = 1.0
#@export var contrast: float = 1.0
#@export var saturation: float = 1.0
