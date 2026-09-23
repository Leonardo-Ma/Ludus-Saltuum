@icon("uid://bn57rt7oachxy") # entity_move.png
## To be used with movement controller
class_name Movement
extends Resource

@export_range(3.0, 100.0, 0.1, "suffix:meters/second?") var _speed: float = 5.5
@export_range(6.5, 150.0, 0.1, "suffix:meters/second?") var _jump_velocity: float = 7.5

# TODO Consider using getters and setters
## Runtime only
var speed_bonus: float = 0.0
var speed_multiplier: float = 1.0
var jump_bonus: float = 0.0
var jump_multiplier: float = 1.0
## Applied to gravity only while falling
var fall_gravity_multiplier: float = 1.0


func get_speed() -> float:
	return (_speed + speed_bonus) * speed_multiplier


func get_jump_velocity() -> float:
	return (_jump_velocity + jump_bonus) * jump_multiplier
