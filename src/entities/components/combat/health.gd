@icon("uid://c71vj0fgk7gfw") # heart.png
class_name Health
extends Resource

## Data resource for Health configuration

@export var max_health: int = 100
@export_range(0, 9999, 0.01, "suffix:health/second") var health_regen: float = 3.0

## iframes
@export_range(0.0, 10.0, 0.05, "suffix:s") var invulnerability_duration: float = 1.0
## Delay only counts outside combat
@export_range(0.0, 600.0, 0.5, "suffix:s") var regen_delay: float = 15.0
@export_range(0.05, 5.0, 0.05, "suffix:s") var regen_tick_rate: float = 0.5
