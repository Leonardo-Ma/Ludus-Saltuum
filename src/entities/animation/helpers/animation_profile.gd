class_name AnimationProfile
extends Resource

## Declares animation capabilities of one archetype's authored graph

@export var default_stance: StringName = AnimKeys.STANDING
## Locomotion state names in body
@export var stances: Array[StringName] = [AnimKeys.STANDING]
@export var actions: Array[AnimationActionDefinition] = []

@export_category("States")
## Jump and fall are authored together
@export var has_air_states: bool = false
@export var has_death: bool = false
## Death Transition inputs, empty for a single authored death clip
@export var death_inputs: Array[StringName] = []
@export var has_respawn: bool = false


func validate(owner_name: String) -> void:
	assert(stances.has(default_stance), "Default stance '%s' not declared in %s" % [default_stance, owner_name])
	assert(has_death or death_inputs.is_empty(), "Death inputs require a dead state in " + owner_name)
	var stance_ids: Dictionary[StringName, bool] = { }
	for stance: StringName in stances:
		assert(stance != &"" and not stance_ids.has(stance), "Invalid or duplicate stance '%s' in %s" % [stance, owner_name])
		stance_ids[stance] = true

	var action_ids: Dictionary[StringName, bool] = { }
	for action: AnimationActionDefinition in actions:
		assert(action != null and action.id != &"", "Incomplete action in " + owner_name)
		assert(not action_ids.has(action.id), "Duplicate action '%s' in %s" % [action.id, owner_name])
		action_ids[action.id] = true
