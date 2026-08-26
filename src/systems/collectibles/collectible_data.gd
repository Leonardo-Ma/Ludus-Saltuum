## Base data container for collectibles. Use specific subclasses like CounterCollectible, StatusCollectible, or HealthCollectible.
@abstract class_name CollectibleData
extends Resource


## To override
func apply_effect(_player: PlayerEntity) -> void:
	pass
