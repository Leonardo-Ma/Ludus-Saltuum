extends Area3D

# TODO Check if this is best approach
@export var attack: Attack
## The distance below the current checkpoint before the player dies
@export var fall_margin: float = 30.0

## Entity to be followed for fall boundary tracking; set via controlled_entity_changed
var target: Node3D

# Store the exact spot the player was born before any checkpoints existed
var _fallback_spawn_transform: Transform3D

@onready var hitbox_collision_shape_3d: CollisionShape3D = $Hitbox/CollisionShape3D


func _ready() -> void:
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	CheckpointManager.checkpoint_activated.connect(_on_checkpoint_activated)
	GameEvents.controlled_entity_changed.connect(_on_controlled_entity_changed)
	if GameEvents.controlled_entity != null:
		_on_controlled_entity_changed(GameEvents.controlled_entity)


func _physics_process(_delta: float) -> void:
	assert(target != null, "Target missing in " + name)

	global_position.x = target.global_position.x
	global_position.z = target.global_position.z


func _initialize_position() -> void:
	_fallback_spawn_transform = target.global_transform

	if CheckpointManager.has_active_checkpoint():
		global_position.y = CheckpointManager.get_respawn_position().y - fall_margin
	else:
		global_position.y = target.global_position.y - fall_margin


func _on_checkpoint_activated(checkpoint_position: Vector3) -> void:
	global_position.y = checkpoint_position.y - fall_margin


func _on_controlled_entity_changed(entity: Node3D) -> void:
	assert(entity != null, "Controlled entity missing in " + name)
	target = entity
	set_physics_process(true)
	hitbox_collision_shape_3d.disabled = false


func _on_body_entered(body: Node3D) -> void:
	if body != target:
		return

	var target_transform: Transform3D

	if CheckpointManager.has_active_checkpoint():
		target_transform = CheckpointManager.get_respawn_transform()
	else:
		target_transform = _fallback_spawn_transform

	GameEvents.request_respawn(2.0, target_transform, false)
