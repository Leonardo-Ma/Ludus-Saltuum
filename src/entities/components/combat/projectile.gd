class_name Projectile
extends Area3D

## Straight-line mover, damage dealt by Hitbox child through attack

var attack: Attack
var shooter: AggressiveEntity

var _velocity: Vector3 = Vector3.ZERO
var _time_left: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_physics_process(false)


## Call after add_child and positioning, faces -Z along travel
func launch(projectile_attack: ProjectileAttack, new_shooter: AggressiveEntity, direction: Vector3) -> void:
	attack = projectile_attack
	shooter = new_shooter
	_velocity = direction * projectile_attack.projectile_speed
	_time_left = projectile_attack.projectile_lifetime
	look_at(global_position + direction)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	assert(attack != null, "Attack missing in " + name)
	global_position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body == shooter:
		return
	queue_free()
