class_name ProjectileAttack
extends Attack

## Enemy projectile attack, rate = seconds between shots, scene defines look and kind

@export_category("Projectile")
@export var projectile_scene: PackedScene
@export_range(1.0, 100.0, 0.5, "suffix:m/s") var projectile_speed: float = 15.0
@export_range(0.1, 30.0, 0.1, "suffix:s") var projectile_lifetime: float = 4.0
## Local to shooter, +Z forward
@export var muzzle_offset: Vector3 = Vector3(0.0, 1.2, 0.8)

@export_category("Range")
@export_range(1.0, 100.0, 0.5, "suffix:m") var max_range: float = 15.0
