## Contains all skills, order = display order, lower = left
class_name SkillCatalogue
extends Resource

@export var definitions: Array[SkillDefinition] = []


## Position of skill for UI
func get_order(definition: SkillDefinition) -> int:
	var order: int = definitions.find(definition)
	assert(order != -1, "SkillCatalogue: " + definition.resource_path + " missing from " + resource_path)
	return order


## Null if no skill has [param id]
func find_by_id(id: StringName) -> SkillDefinition:
	for definition: SkillDefinition in definitions:
		if definition.id == id:
			return definition
	return null
