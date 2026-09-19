## Toggleable slow-fall
class_name PlayerFeatherFallSkill
extends BaseSkill

@export var feather_fall_gravity_mult: float = 0.3

var _is_toggled: bool = false


func get_hud_mode() -> HUDMode:
	return HUDMode.TOGGLE


func on_landed() -> void:
	if _is_toggled:
		_is_toggled = false
		toggled.emit(false)
		_update_feather_particles(false)


func process_input() -> void:
	var body: CharacterBody3D = skills_controller.entity
	if not Input.is_action_just_pressed(definition.input_action):
		return
	if skills_controller.is_sliding:
		return
	if not skills_controller.movement_controller.movement_enabled:
		return
	if body.is_on_floor():
		return

	_is_toggled = not _is_toggled
	toggled.emit(_is_toggled)
	_update_feather_particles(_is_toggled)


func _physics_process(delta: float) -> void:
	if not _is_toggled:
		return
	var body: CharacterBody3D = skills_controller.entity
	if not body.is_on_floor() and body.velocity.y < 0.0:
		body.velocity.y += (skills_controller.movement_controller.gravity * delta) * (1.0 - feather_fall_gravity_mult)


func _update_feather_particles(active: bool) -> void:
	var vfx: VFXController = skills_controller.vfx_controller
	assert(vfx != null, "VFXController missing in " + name)
	vfx.toggle_feather_fall(active, skills_controller.entity)
