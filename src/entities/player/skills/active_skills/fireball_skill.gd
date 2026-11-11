class_name PlayerFireballSkill
extends BaseSkill

## Cooldown projectile skill, emits entity magic_cast to drive animation and projectile spawn

var _cooldown_timer: SceneTreeTimer = null

@onready var _definition: FireballSkillDefinition = definition as FireballSkillDefinition


func get_hud_mode() -> HUDMode:
	return HUDMode.COOLDOWN


func _ready() -> void:
	assert(_definition != null, "Definition must be FireballSkillDefinition in " + name)
	assert(_definition.projectile_scene != null, "Projectile scene missing in " + name)
	skills_controller.entity.magic_casted.connect(_on_magic_cast)


func process_input() -> void:
	if _is_on_cooldown() or skills_controller.is_sliding or not skills_controller.movement_controller.movement_enabled:
		return

	if Input.is_action_just_pressed(definition.input_action):
		_activate()


func _activate() -> void:
	_cooldown_timer = get_tree().create_timer(_definition.cooldown, false)
	_cooldown_timer.timeout.connect(cooldown_finished.emit)
	cooldown_started.emit(_definition.cooldown)
	skills_controller.entity.magic_casted.emit()


func _is_on_cooldown() -> bool:
	return _cooldown_timer != null and _cooldown_timer.time_left > 0.0


func _on_magic_cast() -> void:
	var entity: PlayerEntity = skills_controller.entity
	var direction: Vector3 = -skills_controller.camera.global_basis.z.normalized()
	var projectile: Projectile = _definition.projectile_scene.instantiate()
	assert(projectile != null, "Projectile scene root must be FireballProjectile in " + name)

	entity.get_parent().add_child(projectile)
	projectile.global_position = entity.global_position + Vector3.UP * _definition.spawn_height + direction * _definition.spawn_distance
	projectile.launch(entity.projectile_attack_component.projectile_attack, entity, direction)
