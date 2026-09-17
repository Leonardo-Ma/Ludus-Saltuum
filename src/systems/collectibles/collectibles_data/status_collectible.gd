class_name StatusCollectible
extends CollectibleData

@export_category("Buff Mechanics")
@export var status_effect: StatusEffect
@export var duration: float = 10.0
@export var stack_mode: StatusEffect.StackMode = StatusEffect.StackMode.REPLACE
@export var max_stacks: int = 1
@export var tick_interval: float = 1.0

## Defined in collectible final script's _child_ready, using Icons constant
var icon: Texture2D


func apply_effect(player: PlayerEntity) -> void:
	assert(status_effect != null, "Status buff collectible " + resource_path + " missing effect resource.")
	assert(
		status_effect.get_id() != &"collectible_name" and status_effect.get_id() != &"",
		"Status buff collectible " + resource_path + " missing identifier.",
	)
	assert(icon != null, "Status buff collectible " + resource_path + " missing data.icon definition in child_ready.")

	var entity: PlayerEntity = player as PlayerEntity
	var status_manager: StatusManager = entity.status_manager

	assert(status_manager != null, "Status buff collectible " + resource_path + " missing StatusManager.")

	status_manager.apply_status(status_effect, duration, stack_mode, max_stacks, tick_interval)

	CollectiblesEvents.status_buff_collected.emit(self)


func _resource_to_validate() -> Resource:
	return status_effect
