class_name NPCEntity
extends AggressiveEntity

## Abstract base for GOAP, perception and persistent enemy identity

const TURN_SPEED: float = 10.0

@export_category("Perception System")
@export var perception_config: PerceptionConfig
@export var target_groups: Array[String] = [Groups.PLAYERS]
@export var debug_perception: bool = false

@export_category("AI System")
@export var ai_config: AIConfig

## Unique across authored and procedural placements
var enemy_id: StringName = &""

var goap_agent: GoapAgent

var _brain: NPCBrainController
var _is_procedurally_spawned: bool = false

@onready var npc_movement_controller: NPCMovementController = %NPCMovementController
@onready var goap_controller: GoapMemory = %GoapController
@onready var perception_system: PerceptionSystem = %PerceptionSystem

# TODO Decouple from here, GOAP requires a reference from entity
@export var projectile_attack_component: ProjectileAttackComponent

## Editor-assigned placement ID saved with scene for runtime use
## Storage keeps it out of Inspector
@export_storage var placement_id: StringName


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
		if collision.get_angle() <= floor_max_angle:
			continue
		if npc_movement_controller.is_route_obstructed_by(collision.get_normal(), collision.get_collider() is CharacterBody3D):
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

	if not _is_procedurally_spawned:
		enemy_id = AuthoredEntityId.resolve(self, placement_id)
		assert(owner == null or enemy_id != &"", "Placement ID or enclosing scope missing in " + name)

	_brain = NPCBrainController.new()
	_brain.setup(self, ai_config, goap_controller)
	add_child(_brain)
	goap_agent = _brain.goap_agent

	hurtbox.hit_received.connect(_on_hit_received)

	add_to_group(Groups.ENEMIES)


func _on_dying() -> void:
	print("Disabling GOAP agent ", goap_agent.name)
	_stop_ai()
	CombatEvents.enemy_killed.emit(enemy_id)


func _on_revived() -> void:
	velocity = Vector3.ZERO
	hitbox.close_attack_window()
	perception_system.set_process(true)
	_brain.set_active(true)


func apply_saved_killed_state(killed: bool) -> void:
	if killed:
		_stop_ai()
		_lifecycle.restore_dead()
	else:
		revive()


func _stop_ai() -> void:
	_brain.set_active(false)
	perception_system.set_process(false)
	npc_movement_controller.stop()


## Marks a chunk placement and assigns its unique ID before entering the tree
func assign_procedural_id(id: StringName) -> void:
	assert(not is_inside_tree() and enemy_id == &"" and id != &"", "Invalid procedural ID assignment in " + name)
	_is_procedurally_spawned = true
	enemy_id = id


func _on_death_complete() -> void:
	if _is_procedurally_spawned:
		queue_free()


func _on_hit_received(attacker: Node3D) -> void:
	assert(attacker != null, "Hit source missing in " + name)
	perception_system.report_hit(attacker)
