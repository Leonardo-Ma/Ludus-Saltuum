## Continuous 3D audio loop with intensity driven volume and pitch [br]
## Attach as child of Node3D (VehicleAudioController script) [br]
## call update_intensity() every physics frame
class_name LoopingAudioEmitter
extends AudioStreamPlayer3D

## Pitch at zero intensity
@export var min_pitch: float = 0.8
## Pitch at full intensity
@export var max_pitch: float = 1.8
## Volume at zero intensity
@export_range(-80, -30, 1) var min_volume_db: float = -80.0
## Volume at full intensity
@export_range(-20, 6, 1) var max_volume_db: float = 0.0
## Intensity change per second
@export var fade_speed: float = 4.0

var _target_intensity: float = 0.0
var _current_intensity: float = 0.0


func _ready() -> void:
	assert(stream != null, "LoopingAudioEmitter: stream not assigned in " + name)
	assert(volume_db == 0.0, "LoopingAudioEmitter drives volume_db internally, do not set it in " + name)
	assert(min_pitch > 0.0, "min_pitch should be 0.0 for  " + name)
	assert(max_pitch >= min_pitch, "max_pitch should be >= min_pitch for  " + name)
	assert(max_volume_db >= min_volume_db, "max_volume_db should be >= min_volume_db for  " + name)
	assert(fade_speed > 0.0, "fade_speed should be 0.0 for " + name)

	stream.loop = true
	volume_db = min_volume_db
	pitch_scale = min_pitch
	play()


func _process(delta: float) -> void:
	_current_intensity = move_toward(_current_intensity, _target_intensity, fade_speed * delta)

	volume_db = lerp(min_volume_db, max_volume_db, _current_intensity)
	pitch_scale = lerp(min_pitch, max_pitch, _current_intensity)


## Clamp intensity
func update_intensity(intensity: float) -> void:
	_target_intensity = clampf(intensity, 0.0, 1.0)
