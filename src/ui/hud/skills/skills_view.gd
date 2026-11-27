# TODO Double check this script
class_name SkillsView
extends Control

## View controller, bridge between UI and SkillsController

const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb")

@onready var _skills_container: Container = %SkillsContainer

var _skills: SkillsController


func _ready() -> void:
	hide()
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


func bind_skills(skills: SkillsController) -> void:
	# TODO Double check this
	# Clear previous bindings before subscribing to the new controller instance.
	_clear_all_slots()
	if is_instance_valid(_skills):
		_skills.skill_unlocked.disconnect(_on_skill_unlocked)
		_skills.resetted_skills.disconnect(_clear_all_slots)
	_skills = skills
	if _skills != null:
		_skills.skill_unlocked.connect(_on_skill_unlocked)
		_skills.resetted_skills.connect(_clear_all_slots)
		for definition: SkillDefinition in _skills.get_unlocked_skills():
			_bind_slot(_skills.get_skill(definition))
	_refresh_visibility()


func _on_skill_unlocked(definition: SkillDefinition) -> void:
	_bind_slot(_skills.get_skill(definition))
	_refresh_visibility()


func _bind_slot(skill: BaseSkill) -> void:
	if skill == null:
		return
	var slot_index: int = SKILL_CATALOGUE.get_order(skill.definition)
	if slot_index >= 0 and slot_index < _skills_container.get_child_count():
		var slot: HUDSkillSlot = _skills_container.get_child(slot_index)
		if slot != null:
			slot.setup(skill)


func _clear_all_slots() -> void:
	for slot: HUDSkillSlot in _skills_container.get_children():
		slot.cleanup()
	hide()


func _on_gameplay_mode_changed(_new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	visible = (
		is_instance_valid(_skills) and not _skills.get_unlocked_skills().is_empty()
		and not GameplayStateManager.is_in_mode(GameplayStateManager.GameplayMode.RACING)
	)
