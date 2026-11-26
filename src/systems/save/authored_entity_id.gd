@tool class_name AuthoredEntityId
extends RefCounted

## Generates stable IDs to serialize on authored entity placements


static func generate() -> StringName:
	return StringName(Crypto.new().generate_random_bytes(16).hex_encode())


## Qualifies a placement with each enclosing scene instance's stored scope
static func resolve(node: Node, placement_id: StringName, scene_root: Node = null) -> StringName:
	if placement_id.is_empty():
		return &""
	var resolved_id: String = placement_id
	var boundary: Node = node.owner
	while boundary != null and boundary != scene_root and boundary.owner != null:
		var scope: EntityPlacementScope = find_scope(boundary)
		if scope == null or scope.scope_id.is_empty():
			return &""
		resolved_id = "%s/%s" % [scope.scope_id, resolved_id]
		boundary = boundary.owner
	return StringName(resolved_id)


## Finds the scope serialized by the scene that contains this instance
static func find_scope(boundary: Node) -> EntityPlacementScope:
	for child: Node in boundary.get_children():
		if child is EntityPlacementScope and child.owner == boundary.owner:
			return child
	return null
