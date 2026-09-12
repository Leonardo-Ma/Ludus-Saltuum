## Manages unlocked skills and routes input actions to the correct skill
class_name SkillsController
extends Node

signal skill_unlocked(definition: SkillDefinition)
signal resetted_skills

var is_sliding: bool = false
var base_fov: float = 0.0

var _skills: Dictionary[SkillDefinition, BaseSkill] = { }

@onready var entity: PlayerEntity = owner
@onready var movement_controller: PlayerMovementController = %PlayerMovementController
@onready var camera: Camera3D = %Camera3D
@onready var _vfx_controller: VFXController = %VFXController


func _ready() -> void:
	base_fov = SettingsManager.camera_fov
	movement_controller.landed.connect(_on_landed)
	_initialize_from_entity()
	SettingsManager.camera_settings_changed.connect(_on_camera_settings_changed)


func _physics_process(_delta: float) -> void:
	for skill: BaseSkill in _skills.values():
		skill.process_input()


func reset() -> void:
	_skills.clear()
	resetted_skills.emit()


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


# TODO Reconsider where to place this
## Forwards ghost trail request to VFXController (used by dash/teleport skills).
func spawn_ghost_trail(duration: float = 0.5, color: Color = Color(0.8, 1.0, 1.5, 0.4)) -> void:
	_vfx_controller.spawn_ghost_trail(duration, color)


## Unlocks startup skills sorted by hud_order for consistent display order
func _initialize_from_entity() -> void:
	if entity.startup_skills.is_empty():
		return
	var skills: Array[SkillDefinition] = []
	for skill: SkillDefinition in entity.startup_skills:
		skills.append(skill)
	skills.sort_custom(
		func(a: SkillDefinition, b: SkillDefinition) -> bool:
			return a.hud_order < b.hud_order,
	)
	for skill: SkillDefinition in skills:
		unlock(skill)


func _on_landed() -> void:
	# TODO This should be a signal
	for skill: BaseSkill in _skills.values():
		skill.on_landed()


func _on_camera_settings_changed() -> void:
	# TODO Probably should be a signal
	base_fov = SettingsManager.camera_fov
