# TODO Double check this script
## View controller, bridge between UI and SkillsController
extends Control

@onready var _skills_container: GridContainer = %SkillsContainer


func _ready() -> void:
	hide()
	for skill_slot: Control in _skills_container.get_children():
		assert(skill_slot is HUDSkillSlot, "Skill slot %s is not HUDSkillSlot in %s" % [skill_slot.name, name])

	GameEvents.player_finished_spawning.connect(_on_player_spawned)

	# Player may already exist if HUD is loaded after the player (e.g. respawn).
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0] as PlayerEntity)


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

	# Populate slots that are already unlocked (startup skills initialized
	# before this HUD connected, or player respawned with skills retained)
	for skill: BaseSkill in controller.get_skills_ordered():
		_bind_slot(skill)


func _on_skill_unlocked(_hud_order: int, definition: SkillDefinition) -> void:
	# Re-fetch the live skill node from the controller that emitted the signal
	# The signal source is always the active SkillsController on the player
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if players.is_empty():
		return
	var controller: SkillsController = (players[0] as PlayerEntity).skills_controller
	var skill: BaseSkill = controller.get_skill(definition.id)
	_bind_slot(skill)
	show()


func _bind_slot(skill: BaseSkill) -> void:
	var slots: Array[Node] = _skills_container.get_children()
	var hud_order: int = skill.definition.hud_order
	assert(hud_order < slots.size(), "HUD: hud_order %d out of range (%d slots) in %s" % [hud_order, slots.size(), name])
	(slots[hud_order] as HUDSkillSlot).setup(skill)


func _clear_all_slots() -> void:
	for slot: Control in _skills_container.get_children():
		(slot as HUDSkillSlot).cleanup()
