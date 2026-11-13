class_name HealthCollectible
extends CollectibleData

@export_category("Health Recovery")
@export var health_recovered: int = 20


func apply_effect(player: PlayerEntity) -> void:
	player.health.current_health += health_recovered
