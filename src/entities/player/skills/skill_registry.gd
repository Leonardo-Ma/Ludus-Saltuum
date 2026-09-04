## Autoload for SkillDefinition lookup by id
extends Node
# TODO Remove hardcoded path
const _DATA_PATH: StringName = &"res://src/entities/player/skills/skill_registry_data.tres"

var _by_id: Dictionary = { }


func _ready() -> void:
	var data: SkillRegistryData = load(_DATA_PATH)
	assert(data != null, "SkillRegistry: skill_registry_data.tres not found in " + name)
	for definition: SkillDefinition in data.definitions:
		assert(definition.id != &"", "SkillRegistry: a SkillDefinition has an empty id in " + name)
		_by_id[definition.id] = definition


func get_definition(id: StringName) -> SkillDefinition:
	assert(_by_id.has(id), "SkillRegistry: unknown skill id '%s' in %s" % [id, name])
	return _by_id[id] as SkillDefinition


## All registered definitions
func all() -> Array[SkillDefinition]:
	var result: Array[SkillDefinition] = []
	for value: SkillDefinition in _by_id.values():
		result.append(value)
	return result


## Definitions that include [param tag]
func with_tag(tag: StringName) -> Array[SkillDefinition]:
	return all().filter(
		func(d: SkillDefinition) -> bool:
			return tag in d.tags,
	)
