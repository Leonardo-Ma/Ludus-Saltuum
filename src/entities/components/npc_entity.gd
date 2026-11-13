class_name NPCEntity
extends AggressiveEntity

## Abstract base for GOAP, perception and procedural identity

@export_category("Perception System")
@export var perception_config: PerceptionConfig
@export var target_groups: Array[String] = [Groups.PLAYERS]
@export var debug_perception: bool = false

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
@onready var projectile_attack_component: ProjectileAttackComponent


func _physics_process(delta: float) -> void:
	assert(npc_movement_controller, "NPCMovementController missing in " + name)
	npc_movement_controller.move(delta)
	move_and_slide()
	npc_movement_controller.handle_collisions()


func _child_ready() -> void:
	assert(ai_config, "GOAP Not properly configured for " + name)
	assert(goap_controller, "GoapController missing for " + name)
	assert(npc_movement_controller, "NPCMovementController missing for " + name)
	assert(perception_system, "Perception system missing for " + name)

	# TODO Remove magic string, but still need entity level reference for GOAP
	if $%ProjectileAttackComponent:
		projectile_attack_component = %ProjectileAttackComponent

	if not is_procedurally_spawned:
		assert(static_id != &"", "Enemy static_id not set on non-procedural instance " + name)
		enemy_id = static_id

	_brain = NPCBrainController.new()
	_brain.setup(self, ai_config, goap_controller)
	add_child(_brain)
	goap_agent = _brain.goap_agent

	npc_movement_controller.set_physics_process(false)

	add_to_group(Groups.ENEMIES)


func _on_dying() -> void:
	print("Disabling GOAP agent ", goap_agent.name)
	_brain.set_active(false)


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
