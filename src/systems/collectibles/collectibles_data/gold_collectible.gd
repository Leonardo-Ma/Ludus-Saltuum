class_name GoldCollectible
extends CollectibleData

@export var amount: int = 10


func apply_effect(_player: PlayerEntity) -> void:
	GameEvents.add_gold(amount)
