# TODO: Consider abstract class?
## Template Class intended to right click scene > make new inherited
## Basic functionality meant to be changed within the exported variables in inspector
## Specific functionality meant to be added here in inherited scene
class_name EnemyTemplate
extends AggressiveEntity


func _physics_process(delta: float) -> void:
	npc_movement_controller.move(delta)
	move_and_slide()

	# Apply physics collision with rigid bodies
	for i: int in get_slide_collision_count():
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is RigidBody3D:
			var push_force: float = movement.speed * 0.1
			var push_dir: Vector3 = -collision.get_normal()
			push_dir.y = 0.0 # Prevent pushing into the ground or sky
			if push_dir.length_squared() > 0.001:
				collider.apply_impulse(push_dir.normalized() * push_force, collision.get_position() - collider.global_position)


## Children should override this instead of _ready()
func _child_ready() -> void:
	pass


func _on_death_complete() -> void:
	CombatEvents.enemy_killed.emit(enemy_id)
	if is_procedurally_spawned:
		queue_free()
