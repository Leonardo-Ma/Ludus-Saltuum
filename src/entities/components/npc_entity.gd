class_name NPCEntity
extends AggressiveEntity

## Abstract base for GOAP, perception and procedural identity

const TURN_SPEED: float = 10.0

@export_category("Perception System")
@export var perception_config: PerceptionConfig
@export var target_groups: Array[String] = [Groups.PLAYERS]
@export var debug_perception: bool = false

@export_category("Weapon")
## Optional, null keeps socket empty
@export var weapon: WeaponAsset

@export_category("AI System")
@export var ai_config: AIConfig

## False when outside level chunk, requires static_id set in editor
@export var is_procedurally_spawned: bool = true
## Must be unique
@export var static_id: StringName = &""
## Must be unique within this level chunk
@export var procedural_id: StringName = &""

var enemy_id: StringName = &""

var goap_agent: GoapAgent

var _brain: NPCBrainController

@onready var npc_movement_controller: NPCMovementController = %NPCMovementController
@onready var goap_controller: GoapMemory = %GoapController
@onready var perception_system: PerceptionSystem = %PerceptionSystem

# TODO Decouple from here, GOAP requires a reference from entity
@export var projectile_attack_component: ProjectileAttackComponent


func _physics_process(delta: float) -> void:
	assert(npc_movement_controller, "NPCMovementController missing in " + name)
	npc_movement_controller.move(delta)

	var direction: Vector3 = npc_movement_controller.get_desired_direction()
	if not direction.is_zero_approx():
		var target_rotation_y: float = atan2(direction.x, direction.z)
		global_rotation.y = lerp_angle(global_rotation.y, target_rotation_y, 1.0 - exp(-TURN_SPEED * delta))

	var horizontal_velocity: Vector3 = npc_movement_controller.get_horizontal_velocity()
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	if not is_on_floor():
		velocity.y += get_gravity().y * npc_movement_controller.gravity_multiplier * delta

	velocity += npc_movement_controller.consume_external_force()
	move_and_slide()
	_handle_movement_collisions()


func _handle_movement_collisions() -> void:
	var route_obstructed: bool = false
	var push_force: float = npc_movement_controller.get_speed() * 0.1
	for index: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(index)
		_push_rigid_body(collision, push_force)
		if collision.get_collider() is CharacterBody3D or collision.get_angle() <= floor_max_angle:
			continue
		if npc_movement_controller.is_route_obstructed_by(collision.get_normal()):
			route_obstructed = true

	if route_obstructed:
		npc_movement_controller.handle_route_obstruction()


func _child_ready() -> void:
	assert(ai_config, "GOAP Not properly configured for " + name)
	assert(goap_controller, "GoapController missing for " + name)
	assert(npc_movement_controller, "NPCMovementController missing for " + name)
	assert(perception_system, "Perception system missing for " + name)

	assert(
		projectile_attack_component != null or not ai_config.available_actions.has(MagicAttack),
		"ProjectileAttackComponent must be assigned for MagicAttack action to work for " + name,
	)

	if weapon != null:
		equip_weapon(weapon)

	if not is_procedurally_spawned:
		assert(static_id != &"", "Enemy static_id not set on non-procedural instance " + name)
		enemy_id = static_id

	_brain = NPCBrainController.new()
	_brain.setup(self, ai_config, goap_controller)
	add_child(_brain)
	goap_agent = _brain.goap_agent

	add_to_group(Groups.ENEMIES)


func _on_dying() -> void:
	print("Disabling GOAP agent ", goap_agent.name)
	_brain.set_active(false)
	npc_movement_controller.stop()


func _on_revived() -> void:
	_brain.set_active(true)


func assign_procedural_id(seed_value: int, scene_local_path: NodePath) -> void:
	assert(is_procedurally_spawned, "Procedural id assigned to non-procedural enemy " + name)
	procedural_id = StringName(scene_local_path)
	enemy_id = ProceduralId.spawn_id(seed_value, scene_local_path)
	assert(enemy_id != &"", "Enemy identity not assigned on " + name)


func _on_death_complete() -> void:
	CombatEvents.enemy_killed.emit(enemy_id)
	if is_procedurally_spawned:
		queue_free()
