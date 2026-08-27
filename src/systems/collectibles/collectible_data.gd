## Base data container for collectibles. Use specific subclasses like CounterCollectible, StatusCollectible, or HealthCollectible.
@abstract class_name CollectibleData
extends Resource


## To override
func apply_effect(_player: PlayerEntity) -> void:
	pass


## Resource to be validated as external .tres. Validated by validate_external_resource()
## Override when a nested resource should be checked instead
func _resource_to_validate() -> Resource:
	return self


func validate_external_resource() -> void:
	var target: Resource = _resource_to_validate()
	assert(target != null, "CollectibleData: nothing to validate in " + resource_path)
	assert(target.resource_path.ends_with(".tres"), target.get_class() + " must be external .tres, not uniquely added in editor inspector")
