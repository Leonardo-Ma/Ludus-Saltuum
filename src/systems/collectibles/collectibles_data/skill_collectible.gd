## Unlocks a player skill
class_name SkillCollectible
extends CollectibleData

@export_category("Skill")
@export var definition: SkillDefinition


func apply_effect(_player: PlayerEntity) -> void:
	assert(definition != null, "SkillCollectible: definition is null in " + definition.id)
	_player.skills_controller.unlock(definition)
	CollectiblesEvents.skill_collected.emit(definition)


func _resource_to_validate() -> Resource:
	return definition
