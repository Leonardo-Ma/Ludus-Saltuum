@tool
extends EditorPlugin

## Assigns scene-owned placements an ID and preserves it for the life of the node
## Godot copies saved properties on duplication, so give the copy a fresh ID before saving
## Nodes opt in with an @export_storage StringName property named placement_id
## Packed scene instances get their own scope so their inherited placements stay independent
## Each scene stores scopes for instances it owns. Opening a scene only tracks existing nodes

const PLACEMENT_ID_PROPERTY: StringName = &"placement_id"

var _scene_root: Node
var _known_nodes: Dictionary[int, WeakRef] = {}
var _added_nodes: Array[WeakRef] = []
var _scenes_with_unsaved_ids: Dictionary[int, WeakRef] = {}


func _enter_tree() -> void:
	scene_changed.connect(_track_scene)
	scene_saved.connect(_on_scene_saved, CONNECT_DEFERRED)
	get_tree().node_added.connect(_on_node_added)
	_track_scene(EditorInterface.get_edited_scene_root())


func _exit_tree() -> void:
	scene_changed.disconnect(_track_scene)
	scene_saved.disconnect(_on_scene_saved)
	get_tree().node_added.disconnect(_on_node_added)


func _disable_plugin() -> void:
	# Finish additions already made while the plugin was enabled
	_assign_added_placements()


func _apply_changes() -> void:
	_complete_scene_placements()
	_validate_placements()


func _build() -> bool:
	_complete_scene_placements()
	if not _validate_placements():
		return false
	# Godot's save-before-run step has already finished
	var unsaved_scenes: PackedStringArray = EditorInterface.get_unsaved_scenes()
	for scene_id: int in _scenes_with_unsaved_ids.keys():
		var scene: Node = _scenes_with_unsaved_ids[scene_id].get_ref()
		if scene != null:
			var scene_path: String = scene.scene_file_path
			if scene_path.is_empty() or unsaved_scenes.has(scene_path):
				push_error("Placement IDs were assigned in " + scene.name + ". Save the scene before running")
				return false
		_scenes_with_unsaved_ids.erase(scene_id)
	return true


func _track_scene(scene_root: Node) -> void:
	_assign_added_placements()
	_scene_root = scene_root
	for node_id: int in _known_nodes.keys():
		if _known_nodes[node_id].get_ref() == null:
			_known_nodes.erase(node_id)
	for scene_id: int in _scenes_with_unsaved_ids.keys():
		if _scenes_with_unsaved_ids[scene_id].get_ref() == null:
			_scenes_with_unsaved_ids.erase(scene_id)
	for root: Node in EditorInterface.get_open_scene_roots():
		for node: Node in root.find_children("*", "", true, true):
			if node.owner == root and (node is EntityPlacementScope or _is_placement(node)):
				_known_nodes[node.get_instance_id()] = weakref(node)


func _complete_scene_placements() -> void:
	_assign_added_placements()
	if not is_instance_valid(_scene_root):
		return
	var changed: bool = false
	for node: Node in _scene_root.find_children("*", "", true, true):
		if _is_placement(node) and _assign_placement(node, false):
			changed = true
	if changed:
		_mark_ids_unsaved()


func _on_node_added(node: Node) -> void:
	if not is_instance_valid(_scene_root) or not _scene_root.is_ancestor_of(node) or not _is_placement(node):
		return
	if _added_nodes.is_empty():
		_assign_added_placements.call_deferred()
	_added_nodes.append(weakref(node))


func _assign_added_placements() -> void:
	var changed: bool = false
	for reference: WeakRef in _added_nodes:
		var node: Node = reference.get_ref()
		if node == null or not is_instance_valid(_scene_root) or not _scene_root.is_ancestor_of(node):
			continue
		if _assign_placement(node, true):
			changed = true
	_added_nodes.clear()
	if changed:
		_mark_ids_unsaved()


func _mark_ids_unsaved() -> void:
	_scenes_with_unsaved_ids[_scene_root.get_instance_id()] = weakref(_scene_root)
	EditorInterface.mark_scene_as_unsaved()


func _on_scene_saved(scene_path: String) -> void:
	if EditorInterface.get_unsaved_scenes().has(scene_path):
		return
	for scene_id: int in _scenes_with_unsaved_ids.keys():
		var scene: Node = _scenes_with_unsaved_ids[scene_id].get_ref()
		if scene == null or scene.scene_file_path == scene_path:
			_scenes_with_unsaved_ids.erase(scene_id)


func _assign_placement(node: Node, newly_added: bool) -> bool:
	if node.owner != _scene_root:
		return _assign_scope(node, newly_added)
	var placement_id: StringName = node.get(PLACEMENT_ID_PROPERTY)
	if not _needs_id(node, placement_id, newly_added):
		return false
	node.set(PLACEMENT_ID_PROPERTY, AuthoredEntityId.generate())
	return true


func _assign_scope(node: Node, newly_added: bool) -> bool:
	# Inner scopes belong to their source scenes and are resolved at runtime
	var boundary: Node = node.owner
	while boundary != null and boundary.owner != _scene_root:
		boundary = boundary.owner
	if boundary == null:
		return false
	var scope: EntityPlacementScope = AuthoredEntityId.find_scope(boundary)
	if scope == null:
		scope = EntityPlacementScope.new()
		scope.name = &"EntityPlacementScope"
		boundary.add_child(scope, true)
		scope.owner = _scene_root
	if not _needs_id(scope, scope.scope_id, newly_added):
		return false
	scope.scope_id = AuthoredEntityId.generate()
	return true


func _needs_id(node: Node, current_id: StringName, newly_added: bool) -> bool:
	var instance_id: int = node.get_instance_id()
	var already_known: bool = _known_nodes.has(instance_id)
	if not already_known:
		_known_nodes[instance_id] = weakref(node)
	return current_id.is_empty() or (newly_added and not already_known)


func _validate_placements() -> bool:
	if not is_instance_valid(_scene_root):
		return true
	var ids: Dictionary[StringName, bool] = {}
	for node: Node in _scene_root.find_children("*", "", true, true):
		if not _is_placement(node):
			continue
		var placement_id: StringName = node.get(PLACEMENT_ID_PROPERTY)
		var resolved_id: StringName = AuthoredEntityId.resolve(node, placement_id, _scene_root)
		if resolved_id.is_empty() or ids.has(resolved_id):
			push_error("Missing or duplicate Placement ID in " + node.name + " of " + _scene_root.name)
			return false
		ids[resolved_id] = true
	return true


func _is_placement(node: Node) -> bool:
	var script: Script = node.get_script()
	if script == null:
		return false
	for property: Dictionary in script.get_script_property_list():
		if property.name == PLACEMENT_ID_PROPERTY:
			var stored: bool = (property.usage & PROPERTY_USAGE_STORAGE) != 0
			var shown_in_inspector: bool = (property.usage & PROPERTY_USAGE_EDITOR) != 0
			return property.type == TYPE_STRING_NAME and stored and not shown_in_inspector
	return false
