# TODO Double check this script
## View controller, bridge between UI and SkillsController
class_name SkillsView
extends Control

const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb")

@onready var _skills_container: Container = %SkillsContainer


func _ready() -> void:
	hide()
	for skill_slot: Control in _skills_container.get_children():
		assert(skill_slot is HUDSkillSlot, "Skill slot %s is not HUDSkillSlot in %s" % [skill_slot.name, name])

	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)

	# Player may already exist if HUD is loaded after the player (e.g. respawn).
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0] as PlayerEntity)

	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


func _on_player_spawned(player: PlayerEntity) -> void:
	var controller: SkillsController = player.skills_controller

	# TODO Double check this
	# Clear previous bindings before subscribing to the new controller instance.
	_clear_all_slots()
	if controller.skill_unlocked.is_connected(_on_skill_unlocked):
		controller.skill_unlocked.disconnect(_on_skill_unlocked)
	controller.skill_unlocked.connect(_on_skill_unlocked)
	if controller.resetted_skills.is_connected(_clear_all_slots):
		controller.resetted_skills.disconnect(_clear_all_slots)
	controller.resetted_skills.connect(_clear_all_slots)

	for definition: SkillDefinition in controller.get_unlocked_skills():
		_bind_slot(controller.get_skill(definition))


func _on_skill_unlocked(definition: SkillDefinition) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if players.is_empty():
		return

	var controller: SkillsController = (players[0] as PlayerEntity).skills_controller
	_bind_slot(controller.get_skill(definition))
	show()


func _bind_slot(skill: BaseSkill) -> void:
	var slots: Array[Node] = _skills_container.get_children()
	var slot_index: int = SKILL_CATALOGUE.get_order(skill.definition)
	assert(slot_index < slots.size(), "HUD: skill order %d out of range (%d slots) in %s" % [slot_index, slots.size(), name])
	(slots[slot_index] as HUDSkillSlot).setup(skill)


func _clear_all_slots() -> void:
	for slot: Control in _skills_container.get_children():
		(slot as HUDSkillSlot).cleanup()


# TODO Check better approach than ignores
@warning_ignore("unused_parameter") # gdlint-ignore-next-line unused-argument
func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, previous_mode: GameplayStateManager.GameplayMode) -> void:
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		visible = false
	else:
		visible = true
