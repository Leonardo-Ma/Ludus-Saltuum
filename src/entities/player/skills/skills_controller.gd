## Manages unlocked skills and routes input actions to the correct skill by id
class_name SkillsController
extends Node

# TODO Refactor this to remove hud order, to be any order?
signal skill_unlocked(hud_order: int, definition: SkillDefinition)
signal resetted_skills

var is_sliding: bool = false
var base_fov: float = 0.0

var _skills: Dictionary = {}

@onready var entity: PlayerEntity = owner
@onready var movement_controller: MovementController = %MovementController
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


# TODO BUG Double check this, something clearly wrong with this :(
## Replaces any existing skill with the same id
func unlock(definition: SkillDefinition) -> void:
	assert(definition.input_action != &"" or definition.id == &"dash", "SkillsController: '%s' has no input_action in %s" % [definition.id, name])

	if _skills.has(definition.id):
		(_skills[definition.id] as BaseSkill).queue_free()

	var skill: BaseSkill = definition.skill_script.new()
	skill.name = definition.id
	skill.definition = definition
	skill.skills_controller = self
	add_child(skill)
	_skills[definition.id] = skill
	skill_unlocked.emit(definition.hud_order, definition)


func get_skills_ordered() -> Array[BaseSkill]:
	var result: Array[BaseSkill] = []
	for skill: BaseSkill in _skills.values():
		result.append(skill)
	result.sort_custom(func(a: BaseSkill, b: BaseSkill) -> bool: return a.definition.hud_order < b.definition.hud_order)
	return result


func get_skill(skill_id: StringName) -> BaseSkill:
	return _skills.get(skill_id) as BaseSkill


func get_unlocked_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _skills:
		ids.append(id)
	return ids


func set_unlocked_ids(ids: Array[StringName]) -> void:
	reset()

	for id: StringName in ids:
		var definition: SkillDefinition = SkillRegistry.get_definition(id)
		assert(definition != null, "Skill definition missing for " + str(id) + " in " + name)
		unlock(definition)


# TODO Reconsider where to place this
## Forwards ghost trail request to VFXController (used by dash/teleport skills).
func spawn_ghost_trail(duration: float = 0.5, color: Color = Color(0.8, 1.0, 1.5, 0.4)) -> void:
	_vfx_controller.spawn_ghost_trail(duration, color)


## Unlocks startup skills sorted by hud_order for consistent display order
func _initialize_from_entity() -> void:
	if entity.startup_skill_ids.is_empty():
		return
	var definitions: Array[SkillDefinition] = []
	for id: StringName in entity.startup_skill_ids:
		definitions.append(SkillRegistry.get_definition(id))
	definitions.sort_custom(func(a: SkillDefinition, b: SkillDefinition) -> bool: return a.hud_order < b.hud_order)
	for definition: SkillDefinition in definitions:
		unlock(definition)


func _on_landed() -> void:
	# TODO This should be a signal
	for skill: BaseSkill in _skills.values():
		skill.on_landed()


func _on_camera_settings_changed() -> void:
	# TODO Probably should be a signal
	base_fov = SettingsManager.camera_fov
