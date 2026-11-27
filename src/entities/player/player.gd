class_name PlayerEntity
extends AggressiveEntity

enum PlayerState {
	INACTIVE = 0, ## Not playing (menus)
	ACTIVE = 1,
	IN_VEHICLE = 2,
}

var state: PlayerState:
	get:
		return _player_state_controller.state

var is_respawning: bool:
	get:
		return _player_respawn_controller.is_respawning()

@onready var starting_transform: Transform3D = global_transform

@onready var _movement: PlayerMovementComponent = %PlayerMovementComponent
@onready var _player_combat_controller: PlayerCombatController = %PlayerCombatController
@onready var _player_state_controller: PlayerStateController = %PlayerStateController
@onready var _player_respawn_controller: PlayerRespawnController = %PlayerRespawnController


func _child_ready() -> void:
	add_to_group(Groups.PLAYERS)
	var player_save_controller: PlayerSaveController = %PlayerSaveController
	assert(player_save_controller, "Player save controller missing for " + name)
	var appearance: PlayerAppearance = %PlayerAppearance
	assert(appearance, "Appearance skills missing for " + name)
	var skills: SkillsController = %SkillsController
	assert(skills, "Skills missing for " + name)

	ControlledEntityEvents.player_spawning.emit(self)

	_player_combat_controller.initialize()
	_player_respawn_controller.initialize()
	appearance.initialize()
	skills.initialize()
	_player_state_controller.initialize()

	ControlledEntityEvents.player_finished_spawning.emit(self)


func _physics_process(delta: float) -> void:
	assert(_movement, "PlayerMovementComponent missing in " + name)
	_movement.move(delta)
	velocity += _movement.consume_external_force()
	move_and_slide()
	var push_force: float = _movement.get_speed() * 0.1
	for index: int in get_slide_collision_count():
		_push_rigid_body(get_slide_collision(index), push_force)


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	_player_respawn_controller.respawn(delay, target_transform, is_death)


func try_melee_attack() -> bool:
	if state != PlayerState.ACTIVE or is_respawning:
		return false
	_animation.set_airborne(not is_on_floor())
	return super.try_melee_attack()


## Called by jump chop animation keys
func set_jump_chop_window_enabled(enabled: bool) -> void:
	_player_combat_controller.set_jump_chop_window_enabled(enabled)


# TODO Maybe change this to a signal based to decouple?
## Re-applies when unchanged, respawn relies on it to undo disable_entity()
func set_state(new_state: PlayerState) -> void:
	_player_state_controller.set_state(new_state)


func refresh_state() -> void:
	_player_state_controller.refresh_state()


func finish_load() -> void:
	_player_respawn_controller.finish_load()


func _on_death_complete() -> void:
	_player_respawn_controller.on_death_complete()


func _on_dying() -> void:
	refresh_state()
