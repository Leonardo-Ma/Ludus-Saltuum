@icon("uid://bgcef2dg8bwf") # computer.png
## Configuration resource for entity AI
## Defines which actions and goals are available for a specific entity type
class_name AIConfig
extends Resource

@export_category("GOAP Actions")
@export var available_actions: Array[Script] = []

@export_category("GOAP Goals")
@export var available_goals: Array[Script] = []


## Creates action instances from the configured scripts
func create_actions() -> Array[GoapAction]:
	var actions: Array[GoapAction] = []
	var seen_scripts: Dictionary = { }

	for action_script: Script in available_actions:
		assert(action_script != null, "AIConfig: Null script found in available_actions")

		var script_path: String = action_script.resource_path
		assert(not seen_scripts.has(script_path), "AIConfig: Duplicate action script '%s' ignored" % script_path)

		seen_scripts[script_path] = true

		assert(action_script.can_instantiate(), "AIConfig: Script '%s' cannot be instantiated" % script_path)

		var instance: Variant = action_script.new()
		assert(
			instance is GoapAction,
			"AIConfig: Script '%s' is not a GoapAction! Found type: %s" % [script_path, instance.get_class() if instance else "null"],
		)

		actions.append(instance)

	assert(not actions.is_empty(), "AIConfig: No valid actions created for config: " + resource_path)
	return actions


## Creates goal instances from the configured scripts
func create_goals() -> Array[GoapGoal]:
	var goals: Array[GoapGoal] = []
	var seen_scripts: Dictionary = { }

	for goal_script: Script in available_goals:
		assert(goal_script != null, "AIConfig: Null script found in available_goals")

		var script_path: String = goal_script.resource_path
		assert(not seen_scripts.has(script_path), "AIConfig: Duplicate goal script '%s' ignored" % script_path)

		seen_scripts[script_path] = true

		assert(goal_script.can_instantiate(), "AIConfig: Script '%s' cannot be instantiated" % script_path)

		var instance: Variant = goal_script.new()
		assert(
			instance is GoapGoal,
			"AIConfig: Script '%s' is not a GoapGoal! Found type: %s" % [script_path, instance.get_class() if instance else "null"],
		)

		goals.append(instance)

	assert(not goals.is_empty(), "AIConfig: No valid goals created for config: " + resource_path)
	return goals
