## Manages unlocked skills and routes input actions to the correct skill
class_name SkillsController
extends Node

signal skill_unlocked(definition: SkillDefinition)
signal resetted_skills
signal dash_started(velocity: Vector3, duration: float)

@export_category("Skills")
@export var startup_skills: Array[SkillDefinition] = []

var is_sliding: bool = false
var base_fov: float = 0.0

var _skills: Dictionary[SkillDefinition, BaseSkill] = { }

@onready var entity: PlayerEntity = owner
@onready var movement_controller: PlayerMovementComponent = %PlayerMovementComponent
@onready var camera: Camera3D = %Camera3D
@onready var vfx_controller: VFXController = %VFXController
@onready var projectile_attack: ProjectileAttackComponent = %ProjectileAttackComponent


#region Initialization and input
func initialize() -> void:
	assert(entity and movement_controller and camera and vfx_controller and projectile_attack, "Skill dependencies missing in " + name)
	base_fov = SettingsManager.settings.camera.camera_fov
	movement_controller.landed.connect(_on_landed)
	_unlock_editor_defined_startup_skills()
	SettingsManager.camera_settings_changed.connect(_on_camera_settings_changed)


func _physics_process(_delta: float) -> void:
	assert(entity, "PlayerEntity missing in " + name)
	for skill: BaseSkill in _skills.values():
		skill.process_input()
#endregion


#region Skill management
func reset() -> void:
	for skill: BaseSkill in _skills.values():
		skill.queue_free()

	_skills.clear()
	resetted_skills.emit()

	_unlock_editor_defined_startup_skills()


## Replaces any existing skill
func unlock(definition: SkillDefinition) -> void:
	assert(definition.input_action != &"", "SkillsController: " + definition.resource_name + "is missing input_action in " + name)

	if _skills.has(definition):
		_skills[definition].queue_free()

	var skill: BaseSkill = definition.skill_script.new()
	skill.definition = definition
	skill.skills_controller = self
	add_child(skill)
	_skills[definition] = skill
	skill_unlocked.emit(definition)


func get_skill(definition: SkillDefinition) -> BaseSkill:
	return _skills.get(definition) as BaseSkill


func get_unlocked_skills() -> Array[SkillDefinition]:
	var skills: Array[SkillDefinition] = []
	for skill: SkillDefinition in _skills:
		skills.append(skill)
	return skills


func set_unlocked_skills(skills: Array[SkillDefinition]) -> void:
	reset()

	for skill: SkillDefinition in skills:
		unlock(skill)
#endregion


# TODO Reconsider where to place this
## Forwards ghost trail request to VFXController (used by dash/teleport skills).
func spawn_ghost_trail(duration: float = 0.5, color: Color = Color(0.8, 1.0, 1.5, 0.4)) -> void:
	vfx_controller.spawn_ghost_trail(duration, color)


func _unlock_editor_defined_startup_skills() -> void:
	for definition: SkillDefinition in startup_skills:
		unlock(definition)


func _on_landed() -> void:
	# TODO This should be a signal
	for skill: BaseSkill in _skills.values():
		skill.on_landed()


func _on_camera_settings_changed() -> void:
	# TODO Probably should be a signal
	base_fov = SettingsManager.settings.camera.camera_fov
