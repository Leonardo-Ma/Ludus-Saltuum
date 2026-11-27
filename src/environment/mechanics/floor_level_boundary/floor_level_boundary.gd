extends Area3D

## Tracks the controlled body and recovers players and vehicles crossing the fall plane

const FALL_RECOVERY_DELAY: float = 2.0

# TODO Check if this is best approach
@export var attack: Attack
## The distance below the current checkpoint before the player dies
@export var fall_margin: float = 30.0
@export var hitbox_collision_shape_3d: CollisionShape3D

## Entity to be followed for fall boundary tracking; set via controlled_entity_changed
var target: Node3D

@onready var _hitbox: Hitbox = %Hitbox


func _ready() -> void:
	assert(_hitbox and hitbox_collision_shape_3d and attack, "Hitbox, shape or attack missing in " + name)
	_hitbox.arm(attack)
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	CheckpointManager.checkpoint_activated.connect(_on_checkpoint_changed)
	CheckpointManager.checkpoint_loaded.connect(_on_checkpoint_changed)
	CheckpointManager.checkpoint_cleared.connect(_refresh_height)
	ChunkManager.chunk_recycled.connect(_on_chunk_recycled)
	ChunkManager.level_loaded.connect(_refresh_height)
	ControlledEntityEvents.controlled_entity_changed.connect(_on_controlled_entity_changed)
	if ControlledEntityEvents.controlled_entity != null:
		_on_controlled_entity_changed(ControlledEntityEvents.controlled_entity)


func _physics_process(_delta: float) -> void:
	assert(target, "Target missing in " + name)

	global_position.x = target.global_position.x
	global_position.z = target.global_position.z


func _refresh_height() -> void:
	# Use the authored spawn before any checkpoints exist
	_on_checkpoint_changed(CheckpointManager.get_respawn_position())


func _on_checkpoint_changed(checkpoint_position: Vector3) -> void:
	global_position.y = checkpoint_position.y - fall_margin


func _on_chunk_recycled(_chunk: LevelChunk) -> void:
	if not CheckpointManager.has_active_checkpoint():
		_refresh_height()


func _on_controlled_entity_changed(entity: Node3D) -> void:
	target = entity
	if target != null:
		_refresh_height()
	set_physics_process(target != null)
	hitbox_collision_shape_3d.set_deferred(&"disabled", target == null)


func _on_body_entered(body: Node3D) -> void:
	_recover_body.call_deferred(body)


func _recover_body(body: Node3D) -> void:
	if body == target and is_instance_valid(body):
		ControlledEntityEvents.request_respawn(FALL_RECOVERY_DELAY, CheckpointManager.get_respawn_transform())
	elif body is PlayerCar:
		# TODO Verify that pushed cars can always recover before they softlock a route
		var car: PlayerCar = body
		car.recover_unattended()
