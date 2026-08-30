# An Autoload that ensures all goals have a matching desired condition
# TODO Improve and expand to check matching action effects
# TODO Consider removing hardcoded path?

extends Node


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	var actions_dir: String = "res://src/entities/ai/goap/actions"
	var actions: Array = _load_all_scripts_in_dir(actions_dir)

	var goals_dir: String = "res://src/entities/ai/goap/goals"
	var goals: Array = _load_all_scripts_in_dir(goals_dir)

	assert(not actions.is_empty(), "No GOAP actions found in " + self.name)
	assert(not goals.is_empty(), "No GOAP goals found in " + self.name)

	test_goal_action_consistency(goals, actions)
	print("GOAP consistency test completed.")
	queue_free()


func _load_all_scripts_in_dir(dir_path: String) -> Array[Object]:
	var result: Array[Object] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				var script_path: String = dir_path + "/" + file_name
				var instance: Object = load(script_path).new()
				result.append(instance)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result


func test_goal_action_consistency(_goals: Array[Object], _actions: Array[Object]) -> void:
	for goal: Object in _goals:
		for key: String in goal.get_desired_state().keys():
			var found: bool = false
			for action: Object in _actions:
				if action.get_effects().has(key):
					found = true
					break
			assert(found, "GOAP TEST FAIL: No action effect matches desired state key '%s' for goal '%s'" % [key, goal.get_class()])
