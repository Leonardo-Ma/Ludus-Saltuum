## Toggleable slow-fall
class_name PlayerFeatherFallSkill
extends BaseSkill

@export_range(0.01, 1.0, 0.01) var feather_fall_gravity_mult: float = 0.3

var _is_toggled: bool = false


func _ready() -> void:
	skills_controller.movement_controller.in_air.connect(_update_feather_particles)


func get_hud_mode() -> HUDMode:
	return HUDMode.TOGGLE


func on_landed() -> void:
	_update_feather_particles()


func process_input() -> void:
	if not Input.is_action_just_pressed(definition.input_action):
		return
	if _is_toggled:
		_set_toggled(false)
		return
	if skills_controller.is_sliding or not skills_controller.movement_controller.movement_enabled:
		return
	_set_toggled(true)


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
	_update_feather_particles()


func _update_feather_particles() -> void:
	var vfx: VFXController = skills_controller.vfx_controller
	assert(vfx != null, "VFXController missing in " + name)
	vfx.toggle_feather_fall(_is_toggled and not skills_controller.entity.is_on_floor(), skills_controller.entity)
