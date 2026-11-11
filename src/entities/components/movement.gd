@icon("uid://bn57rt7oachxy") # entity_move.png
## Data resource for movement configuration
class_name Movement
extends Resource

@export_range(1.0, 100.0, 0.1, "suffix:meters/second?") var speed: float = 5.5
@export_range(6.5, 150.0, 0.1, "suffix:meters/second?") var jump_velocity: float = 7.5
