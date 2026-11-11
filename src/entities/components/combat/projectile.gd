# TODO Also queue_free upon hitting generic world collision
class_name Projectile
extends Area3D

## Straight-line mover, damage dealt by Hitbox child through attack, freed on world contact or after hit

@export var sound_effect: AudioStreamOggVorbis

var attack: Attack
var shooter: AggressiveEntity

var _velocity: Vector3 = Vector3.ZERO
var _time_left: float = 0.0

@onready var _hitbox: Hitbox = %Hitbox


func _ready() -> void:
	assert(collision_layer == 0 and collision_mask == 9, "Projectile must have no layer and have world and world object mask")

	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	_hitbox.hit_landed.connect(_on_hit_landed)


## Call after add_child and positioning, faces -Z along travel
func launch(projectile_attack: ProjectileAttack, new_shooter: AggressiveEntity, direction: Vector3) -> void:
	attack = projectile_attack
	shooter = new_shooter
	_hitbox.ignored_entity = new_shooter
	_velocity = direction * projectile_attack.projectile_speed
	_time_left = projectile_attack.projectile_lifetime

	if not direction.is_zero_approx():
		look_at(global_position + direction)

	set_physics_process(true)

	AudioManager.play_sound(sound_effect, AudioManager.SoundBus.SFX, global_position)


func _physics_process(delta: float) -> void:
	assert(attack != null, "Attack missing in " + name)
	global_position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()


# NOTE When hitting an world object without hurtbox
func _on_body_entered(_body: Node3D) -> void:
	queue_free()


func _on_hit_landed(_hurtbox: Hurtbox) -> void:
	queue_free()
