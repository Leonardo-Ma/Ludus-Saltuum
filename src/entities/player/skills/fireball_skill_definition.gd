## SkillDefinition with fireball data
class_name FireballSkillDefinition
extends SkillDefinition

@export_category("Fireball")
@export var projectile_scene: PackedScene
@export_range(0.1, 60.0, 0.1, "suffix:s") var cooldown: float = 2.0
@export var spawn_height: float = 1.0
@export var spawn_distance: float = 1.5
