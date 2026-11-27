class_name PlayerFireballSkill
extends BaseSkill

## Cooldown projectile skill, emits entity magic_cast to drive animation and projectile spawn

var _cooldown_timer: SceneTreeTimer = null
var _attack_component: ProjectileAttackComponent


func get_hud_mode() -> HUDMode:
	return HUDMode.COOLDOWN


func _ready() -> void:
	_attack_component = skills_controller.projectile_attack
	assert(_attack_component != null and _attack_component.projectile_attack != null, "ProjectileAttack missing in " + name)
	skills_controller.entity.magic_casted.connect(_on_magic_cast)


func process_input() -> void:
	if _is_on_cooldown() or skills_controller.is_sliding or not skills_controller.movement_controller.movement_enabled:
		return

	if Input.is_action_just_pressed(definition.input_action):
		_activate()


func _activate() -> void:
	var cooldown: float = _attack_component.projectile_attack.rate
	_cooldown_timer = get_tree().create_timer(cooldown, false)
	_cooldown_timer.timeout.connect(cooldown_finished.emit)
	cooldown_started.emit(cooldown)
	skills_controller.entity.magic_casted.emit()


func _is_on_cooldown() -> bool:
	return _cooldown_timer != null and _cooldown_timer.time_left > 0.0


func _on_magic_cast() -> void:
	_attack_component.fire_direction(-skills_controller.camera.global_basis.z.normalized(), skills_controller.entity)
