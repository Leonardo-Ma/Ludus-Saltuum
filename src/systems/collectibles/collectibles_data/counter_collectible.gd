class_name CounterCollectible
extends CollectibleData

@export var icon: Texture2D

@export_category("Counter Mechanics")
@export var amount: int = 1


func apply_effect(_player: PlayerEntity) -> void:
	pass
