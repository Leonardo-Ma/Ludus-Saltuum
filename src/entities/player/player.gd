class_name PlayerEntity
extends AggressiveEntity

enum PlayerState {
	INACTIVE = 0, ## Not playing (menus)
	ACTIVE = 1,
	IN_VEHICLE = 2,
}

@export_category("Skills")
@export var startup_skills: Array[SkillDefinition] = []

var state: PlayerState:
	get:
		return _player_state_controller.state

@onready var visual: CharacterVisual = %Visual

@onready var camera_controller: CameraController = %CamRoot
@onready var player_movement_controller: PlayerMovementComponent = %PlayerMovementComponent
@onready var input_controller: InputController = %InputController

@onready var player_save_controller: PlayerSaveController = %PlayerSaveController
@onready var skills_controller: SkillsController = %SkillsController
@onready var vehicle_rider: VehicleRider = %VehicleRider
@onready var portal_controller: PortalController = %PortalController
@onready var economy_controller: EconomyController = %EconomyController
@onready var easter_egg_controller: EasterEggController = %EasterEggController
@onready var environment_transition_controller: EnvironmentTransitionController = %EnvironmentTransitionController
@onready var vfx_controller: VFXController = %VFXController
@onready var cosmetics_controller: CosmeticsController = %CosmeticsController

@onready var movement: PlayerMovementComponent = %PlayerMovementComponent
@onready var projectile_attack_component: ProjectileAttackComponent = %ProjectileAttackComponent

@onready var _player_state_controller: PlayerStateController = %PlayerStateController
@onready var _player_respawn_controller: PlayerRespawnController = %PlayerRespawnController


func _physics_process(delta: float) -> void:
	player_movement_controller.move(delta)
	move_and_slide()
	player_movement_controller.handle_collisions()


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	await _player_respawn_controller.respawn(delay, target_transform, is_death)


# TODO Maybe change this to a signal based to decouple?
## Re-applies when unchanged, respawn relies on it to undo disable_entity()
func set_state(new_state: PlayerState) -> void:
	_player_state_controller.set_state(new_state)


func finish_load() -> void:
	_player_respawn_controller.finish_load()


func _child_ready() -> void:
	add_to_group(Groups.PLAYERS)

	assert(player_save_controller != null, "Player save controller missing for " + name)

	ControlledEntityEvents.player_spawning.emit(self)

	# TODO Move this to VFX controller?
	visual.meshes_replaced.connect(refresh_damage_feedback_meshes)

	ControlledEntityEvents.player_finished_spawning.emit(self)


func _on_death_complete() -> void:
	_player_respawn_controller.on_death_complete()
