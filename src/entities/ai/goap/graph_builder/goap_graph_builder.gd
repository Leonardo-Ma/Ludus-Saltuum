# TODO Fix this garbage, attach to specific key to open
class_name GoapGraphBuilder
extends GraphEdit

const GOALS_DIRECTORY: String = "res://src/entities/ai/goap/goals"
const ACTIONS_DIRECTORY: String = "res://src/entities/ai/goap/actions"

var _goals: Array[GoapGoal] = []
var _actions: Array[GoapAction] = []
var _last_modification_times: Dictionary = {}
var _update_timer: Timer


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	# Ensure this node processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Configure GraphEdit
	right_disconnects = true
	scroll_offset = Vector2(50, 50)
	zoom = 1.0
	minimap_enabled = true
	show_grid = true

	_update_timer = Timer.new()
	_update_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_update_timer.wait_time = 1.0
	_update_timer.timeout.connect(_check_for_updates)
	add_child(_update_timer)
	_update_timer.start()

	_load_goap_elements()
	_build_graph()


func _check_for_updates() -> void:
	var needs_rebuild: bool = false

	for dir_path: String in [GOALS_DIRECTORY, ACTIONS_DIRECTORY]:
		var dir: DirAccess = DirAccess.open(dir_path)
		assert(dir != null, "GOAP directory missing in %s: %s" % [name, dir_path])

		var has_gd_script: bool = false

		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				has_gd_script = true

				var file_path: String = dir_path + "/" + file_name
				var mod_time: int = FileAccess.get_modified_time(file_path)

				if not _last_modification_times.has(file_path) or _last_modification_times[file_path] != mod_time:
					_last_modification_times[file_path] = mod_time
					needs_rebuild = true

			file_name = dir.get_next()
		dir.list_dir_end()

		assert(
			has_gd_script,
			"GOAP directory contains no GDScript files in %s: %s" % [name, dir_path],
		)

	if needs_rebuild:
		_rebuild_graph()


func _rebuild_graph() -> void:
	# Clear existing nodes
	for child: Node in get_children():
		if child is GraphNode:
			remove_child(child)
			child.queue_free()

	clear_connections()
	_load_goap_elements()
	_build_graph()


func _load_goap_elements() -> void:
	_actions = _load_all_actions(ACTIONS_DIRECTORY)


func _load_all_goals(dir_path: String) -> Array[GoapGoal]:
	var result: Array[GoapGoal] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				var script_path: String = dir_path + "/" + file_name
				var script: Script = load(script_path)
				if script:
					var instance: GoapGoal = script.new()
					if instance:
						result.append(instance)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result


func _load_all_actions(dir_path: String) -> Array[GoapAction]:
	var result: Array[GoapAction] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				var script_path: String = dir_path + "/" + file_name
				var script: Script = load(script_path)
				if script:
					var instance: GoapAction = script.new()
					if instance:
						result.append(instance)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result


func _build_graph() -> void:
	var y_offset: int = 0
	var goal_nodes: Dictionary = {}

	for i: int in range(_goals.size()):
		var goal: GoapGoal = _goals[i]
		var node: GraphNode = _create_goal_node(goal, i)
		node.position_offset = Vector2(50, y_offset)
		y_offset += 150
		add_child(node)
		goal_nodes[goal] = node.name

	var action_x_offset: int = 400
	y_offset = 0

	for i: int in range(_actions.size()):
		var action: GoapAction = _actions[i]
		var node: GraphNode = _create_action_node(action, i)
		node.position_offset = Vector2(action_x_offset, y_offset)
		y_offset += 150
		add_child(node)

		_connect_action_to_goals(action, node.name, goal_nodes)


func _create_goal_node(goal: GoapGoal, index: int) -> GraphNode:
	var node: GraphNode = GraphNode.new()
	node.name = "Goal_%d" % index
	node.title = goal.get_custom_class_name()

	var vbox: VBoxContainer = VBoxContainer.new()

	var priority_label: Label = Label.new()
	priority_label.text = "Priority: %d" % goal.priority()
	vbox.add_child(priority_label)

	var state_label: Label = Label.new()
	state_label.text = "Desired State:"
	vbox.add_child(state_label)

	for key: String in goal.get_desired_state().keys():
		var key_label: Label = Label.new()
		key_label.text = "  %s: %s" % [key, goal.get_desired_state()[key]]
		vbox.add_child(key_label)

	node.add_child(vbox)

	# Set slots for connections (right side only for goals)
	node.set_slot(0, false, 0, Color.WHITE, true, 0, Color.GREEN)

	return node


func _create_action_node(action: GoapAction, index: int) -> GraphNode:
	var node: GraphNode = GraphNode.new()
	node.name = "Action_%d" % index
	node.title = action.get_custom_class_name()

	var vbox: VBoxContainer = VBoxContainer.new()

	if not action.get_preconditions().is_empty():
		var precond_label: Label = Label.new()
		precond_label.text = "Preconditions:"
		vbox.add_child(precond_label)

		for key: Variant in action.get_preconditions().keys():
			var key_label: Label = Label.new()
			key_label.text = "  %s: %s" % [key, action.get_preconditions()[key]]
			vbox.add_child(key_label)

	if not action.get_effects().is_empty():
		var effect_label: Label = Label.new()
		effect_label.text = "Effects:"
		vbox.add_child(effect_label)

		for key: Variant in action.get_effects().keys():
			var key_label: Label = Label.new()
			key_label.text = "  %s: %s" % [key, action.get_effects()[key]]
			vbox.add_child(key_label)

	node.add_child(vbox)

	# Set slots for connections (left side only for actions)
	node.set_slot(0, true, 0, Color.GREEN, false, 0, Color.WHITE)

	return node


func _connect_action_to_goals(action: GoapAction, action_node_name: String, goal_nodes: Dictionary) -> void:
	var action_effects: Dictionary = action.get_effects()

	for goal: GoapGoal in _goals:
		var desired_state: Dictionary = goal.get_desired_state()

		# Check if action's effects satisfy any of the goal's desired state
		for key: Variant in desired_state.keys():
			if action_effects.has(key) and action_effects[key] == desired_state[key]:
				var goal_node_name: String = goal_nodes[goal]
				# Connect action (left) to goal (right)
				connect_node(action_node_name, 0, goal_node_name, 0)
				break
