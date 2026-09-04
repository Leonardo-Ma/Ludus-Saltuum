class_name GoldCollectible
extends CollectibleData

@export var amount: int = 10


func apply_effect(player: PlayerEntity) -> void:
	player.economy_controller.add_gold(amount)
