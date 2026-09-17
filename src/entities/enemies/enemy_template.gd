# TODO: Consider abstract class?
## Template Class intended to right click scene > make new inherited
## Basic functionality meant to be changed within the exported variables in inspector
## Specific functionality meant to be added here in inherited scene
class_name EnemyTemplate
extends AggressiveEntity


func _physics_process(delta: float) -> void:
	npc_movement_controller.move(delta)
	move_and_slide()
	npc_movement_controller.handle_collisions()


## Children should override this instead of _ready()
func _child_ready() -> void:
	pass


func _on_death_complete() -> void:
	CombatEvents.enemy_killed.emit(enemy_id)
	if is_procedurally_spawned:
		queue_free()
