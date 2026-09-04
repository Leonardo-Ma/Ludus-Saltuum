class_name PlayerMultiJumpSkill
extends BaseSkill

signal multi_jump_executed

const MULTI_JUMP_SOUNDS: Array[AudioStream] = [
	preload("uid://i61p6tvxnhor"), # jump.wav
	preload("uid://bb1w0acj8f3i1"), # jump_short.wav
]

## Used for air jumps
var jump_velocity_multiplier: float = 1.5
var jump_fov_increase: float = 8.0
var jump_fov_duration: float = 0.2

var _jumps_remaining: int
var _frame_of_last_jump: int = -1


func get_hud_mode() -> HUDMode:
	return HUDMode.CHARGES


func _ready() -> void:
	# Listen only for the first ground jump signal
	skills_controller.movement_controller.jumped.connect(_on_jumped)
	# Grant multi jump when falling without jumping
	skills_controller.movement_controller.in_air.connect(_on_in_air)


func on_landed() -> void:
	_jumps_remaining = 0
	charges_updated.emit(definition.max_charges)


func process_input() -> void:
	if _can_extra_jump():
		_execute_extra_jump()


func _can_extra_jump() -> bool:
	if not Input.is_action_just_pressed("jump"):
		return false
	if _jumps_remaining <= 0:
		return false
	# TODO Double check this or find better approach
	# One jump per physics frame (prevents double‑process of same press)
	if Engine.get_physics_frames() == _frame_of_last_jump:
		return false
	if not skills_controller.movement_controller.movement_enabled:
		return false
	return true


func _execute_extra_jump() -> void:
	_jumps_remaining -= 1
	charges_updated.emit(_jumps_remaining)

	var jump_vel: float = skills_controller.entity.movement.jump_velocity * jump_velocity_multiplier
	skills_controller.movement_controller.jump(jump_vel, skills_controller.entity)
	_frame_of_last_jump = Engine.get_physics_frames()

	_play_jump_feedback()


func _on_jumped() -> void:
	# Called when the first ground jump signal fires, reset available air jumps
	_jumps_remaining = definition.max_charges
	charges_updated.emit(_jumps_remaining)
	_frame_of_last_jump = Engine.get_physics_frames()


## Grant charges on any air entry (jump or fall)
func _on_in_air() -> void:
	_jumps_remaining = definition.max_charges
	charges_updated.emit(_jumps_remaining)

#region Visual and sound effects
func _play_jump_feedback() -> void:
	multi_jump_executed.emit()
	SoundManager.play_sound(MULTI_JUMP_SOUNDS.pick_random(), SoundManager.SoundCategory.SFX)
	skills_controller.spawn_ghost_trail(0.6)
	_animate_jump_fov()


func _animate_jump_fov() -> void:
	var tween: Tween = skills_controller.create_tween()
	var target_fov: float = skills_controller.base_fov + jump_fov_increase

	# Quick FOV pop upward
	tween.tween_property(skills_controller.camera, "fov", target_fov, jump_fov_duration * 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Smooth return to base FOV (automatically queued)
	tween.tween_property(skills_controller.camera, "fov", skills_controller.base_fov, jump_fov_duration * 0.7).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
#endregion
