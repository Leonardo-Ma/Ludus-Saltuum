## Toggleable slow-fall
class_name PlayerFeatherFallSkill
extends BaseSkill

@export_range(0.01, 1.0, 0.01) var feather_fall_gravity_mult: float = 0.3

var _is_toggled: bool = false


func get_hud_mode() -> HUDMode:
	return HUDMode.TOGGLE


func on_landed() -> void:
	_set_toggled(false)


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

	_set_toggled(not _is_toggled)


func _exit_tree() -> void:
	_set_toggled(false)


func _set_toggled(active: bool) -> void:
	if _is_toggled == active:
		return

	_is_toggled = active
	var movement: Movement = skills_controller.entity.movement
	if active:
		movement.fall_gravity_multiplier *= feather_fall_gravity_mult
	else:
		movement.fall_gravity_multiplier /= feather_fall_gravity_mult

	toggled.emit(active)
	_update_feather_particles(active)


func _update_feather_particles(active: bool) -> void:
	var vfx: VFXController = skills_controller.vfx_controller
	assert(vfx != null, "VFXController missing in " + name)
	vfx.toggle_feather_fall(active, skills_controller.entity)
