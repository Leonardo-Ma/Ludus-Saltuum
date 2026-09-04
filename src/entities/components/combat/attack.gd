@icon("uid://cdm1p42bwmr10") # sword.png
## This is attached to 'Attack' resources on entities to deal damage (passing to hurtbox)
class_name Attack
extends Resource

#@export_category("Attack Type")
@export_flags("Physical", "Fire", "Earth", "Water", "Ice", "Lightning", "Wind", "Poison") var type: int

#@export_category("Attributes")
@export_range(-99999, 99999, 1, "suffix:base dmg") var damage: int
@export_range(-99, 99, 0.1, "suffix:meters/second") var knockback_force: float
@export_range(0.1, 999, 0.1, "suffix:Seconds/attack") var rate: float = 1
#@export var attack_position: Vector2

@export var hitkill: bool
