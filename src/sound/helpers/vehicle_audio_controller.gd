## Drives engine and skid loops for a vehicle from speed and wheel slip
class_name VehicleAudioController
extends Node3D

const SKID_INTENSITY_THRESHOLD: float = 0.15
const SKID_RETRIGGER_COOLDOWN: float = 0.3
const SUSPENSION_SETTLE_FRAMES: int = 30

## Max speed used to normalize engine loop intensity
@export var max_reference_speed: float = 25.0
## Lateral slip before skid intensity starts ramping
@export var lateral_slip_threshold: float = 1.2
## Lateral slip where skid intensity reaches full volume
@export var lateral_slip_max: float = 5.0
## How fast skid loop fades in/out (intensity per second)
@export var skid_fade_speed: float = 5.0

var _was_skidding: bool = false
var _skid_cooldown: float = 0.0
var _settle_frames_remaining: int = 0

@onready var _engine_loop: LoopingAudioEmitter = %EngineLoop
@onready var _skid_loop: LoopingAudioEmitter = %SkidLoop

@onready var _vehicle: PlayerCar = owner as PlayerCar


func _ready() -> void:
	assert(_vehicle != null, "VehicleAudioController owner must be PlayerCar in " + name)
	_skid_loop.fade_speed = skid_fade_speed
	_vehicle.teleported.connect(_on_teleported)


func _physics_process(delta: float) -> void:
	if not _vehicle.is_driven:
		_silence()
		return

	if _skid_cooldown > 0.0:
		_skid_cooldown -= delta

	if _settle_frames_remaining > 0:
		_settle_frames_remaining -= 1
		_silence()
		_was_skidding = false
		return

	var throttle: float = absf(_vehicle.speed_ratio)
	var speed: float = clampf(_vehicle.linear_velocity.length() / max_reference_speed, 0.0, 1.0)
	var engine_intensity: float = maxf(throttle, speed * 0.3)
	_engine_loop.update_intensity(engine_intensity)

	var skid_intensity: float = 0.0

	for wheel: VehicleWheel3D in [_vehicle.front_left_wheel, _vehicle.front_right_wheel, _vehicle.back_left_wheel, _vehicle.back_right_wheel]:
		if wheel.is_in_contact():
			skid_intensity = max(skid_intensity, 1.0 - wheel.get_skidinfo())

	_skid_loop.update_intensity(clampf(skid_intensity, 0.0, 1.0))

	var is_skidding: bool = skid_intensity > SKID_INTENSITY_THRESHOLD
	if is_skidding and not _was_skidding and _skid_cooldown <= 0.0:
		_skid_cooldown = SKID_RETRIGGER_COOLDOWN
	_was_skidding = is_skidding


func _on_teleported() -> void:
	_settle_frames_remaining = SUSPENSION_SETTLE_FRAMES
	_skid_cooldown = SKID_RETRIGGER_COOLDOWN


func _silence() -> void:
	_engine_loop.update_intensity(0.0)
	_skid_loop.update_intensity(0.0)
