@icon("uid://c71vj0fgk7gfw") # heart.png
class_name Health
extends Resource

## Data resource for Health configuration

@export var max_health: int = 100
@export_range(0, 9999, 0.01, "suffix:health/second") var health_regen: float = 3.0
