class_name VideoSettings
extends Resource

const FPS_PRESETS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0] # 0 = Unlimited

## Persisted only while window_mode is WINDOWED, switching to fullscreen doesn't overwrite
@export var windowed_size: Vector2i = Vector2i(1920, 1080)

@export var window_mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN

@export var vsync_mode: DisplayServer.VSyncMode = DisplayServer.VSYNC_DISABLED

@export var fps_limit: int = 90

@export var brightness: float = 1.0
#@export var contrast: float = 1.0
#@export var saturation: float = 1.0
