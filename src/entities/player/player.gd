class_name PlayerEntity
extends AggressiveEntity

enum PlayerState {
	INACTIVE = 0, ## Not playing (menus)
	ACTIVE = 1,
	IN_VEHICLE = 2,
}

@export_category("Skills")
@export var startup_skills: Array[SkillDefinition] = []

var state: PlayerState = PlayerState.INACTIVE

var is_respawning: bool:
	get:
		return _player_respawn_controller.is_respawning()

@onready var starting_transform: Transform3D = global_transform

@onready var visual: CharacterVisual = %Visual
@onready var weapon_controller: WeaponController = %WeaponController

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


func _child_ready() -> void:
	add_to_group(Groups.PLAYERS)

	assert(player_save_controller, "Player save controller missing for " + name)

	ControlledEntityEvents.player_spawning.emit(self)

	# TODO Move this to VFX controller?
	visual.meshes_replaced.connect(refresh_damage_feedback_meshes)

	# TODO Move this to cosmetics controller? Or Visual?
	cosmetics_controller.equipped_changed.connect(_on_equipped_changed)
	_on_equipped_changed(cosmetics_controller.get_equipped_asset(CosmeticAsset.Slot.CHARACTER))
	var cosmetic_weapon: CosmeticAsset = cosmetics_controller.get_equipped_asset(CosmeticAsset.Slot.WEAPON)
	if weapon_controller.equipped_weapon == null or not cosmetic_weapon.is_default:
		_on_equipped_changed(cosmetic_weapon)

	ControlledEntityEvents.player_finished_spawning.emit(self)


func _physics_process(delta: float) -> void:
	assert(player_movement_controller, "PlayerMovementComponent missing in " + name)
	player_movement_controller.move(delta)
	velocity += player_movement_controller.consume_external_force()
	move_and_slide()
	var push_force: float = player_movement_controller.get_speed() * 0.1
	for index: int in get_slide_collision_count():
		_push_rigid_body(get_slide_collision(index), push_force)


func respawn(delay: float, target_transform: Transform3D, is_death: bool = false) -> void:
	_player_respawn_controller.respawn(delay, target_transform, is_death)


func try_melee_attack() -> bool:
	if state != PlayerState.ACTIVE or is_respawning or not is_on_floor():
		return false
	return super.try_melee_attack()


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


func _on_equipped_changed(asset: CosmeticAsset) -> void:
	if asset is CharacterEntityAsset:
		visual.replace_character_visual(asset.character_mesh)
	elif asset is WeaponCosmetic:
		weapon_controller.equip_weapon(asset.weapon)
