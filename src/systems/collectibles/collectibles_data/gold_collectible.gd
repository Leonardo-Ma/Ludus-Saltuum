@icon("uid://bmdg7sc3tlyrv") # coins.png
class_name GoldCollectible
extends CollectibleData

@export var amount: int = 10


func apply_effect(player: PlayerEntity) -> void:
	var economy: EconomyController = player.get_node(^"%EconomyController")
	assert(economy, "EconomyController missing in " + player.name)
	economy.add_gold(amount)
