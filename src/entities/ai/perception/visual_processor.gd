class_name VisualProcessor
extends RefCounted

## Responsible for determining if target is visually detectable or near enough (considering a "smell or noise" / sixth sense)

var config: VisualConfig


func _init(config_data: VisualConfig) -> void:
	assert(config_data.awareness_radius <= config_data.visual_range, "VisualProcessor: awareness_radius exceeds visual_range")

	config = config_data


func detect(owner_node: Node3D, target: Node3D) -> DetectionResult:
	var result: DetectionResult = DetectionResult.new()

	var distance_squared: float = owner_node.global_position.distance_squared_to(target.global_position)
	var range_squared: float = config.visual_range * config.visual_range

	if distance_squared > range_squared:
		return result

	# Sixth-sense / Hearing radius (distance that can always notice)
	var is_very_close: bool = distance_squared < config.awareness_radius * config.awareness_radius

	# Angle check (cone vision), only applied if not very close
	var target_pos: Vector3 = target.global_position
	target_pos.y = owner_node.global_position.y # Only check horizontal angle
	var to_target: Vector3 = (target_pos - owner_node.global_position).normalized()

	# TODO Double check
	# -Z is typically forward, but the navigation script uses atan2(x, z)
	# which aligns the +Z axis with the movement direction. So, +Z is forward.
	var forward: Vector3 = owner_node.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var angle: float = rad_to_deg(forward.angle_to(to_target))

	if not is_very_close and abs(angle) > (config.field_of_view / 2.0):
		return result

	if not _has_line_of_sight(owner_node, target):
		return result

	var distance: float = sqrt(distance_squared) # We need actual distance for detection chance formulas

	# TODO Improve this detection calculation
	var stealth_penalty: float = _calculate_stealth_penalty(target)
	var detection_chance: float = _calculate_detection_chance(distance, angle, stealth_penalty)

	if randf() < detection_chance:
		result.is_detected = true
		result.confidence = detection_chance
		result.type = 0 # VISUAL
		result.detected_position = target.global_position
		result.detected_entity = target

	return result


func _has_line_of_sight(owner_node: Node3D, target: Node3D) -> bool:
	# Add slight vertical offset to avoid floor hits and aim for torso/head
	var start_pos: Vector3 = owner_node.global_position + Vector3(0, 1.0, 0)
	var end_pos: Vector3 = target.global_position + Vector3(0, 1.0, 0)

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start_pos, end_pos, config.collision_mask)

	# Ignore Area3Ds (like Hurtboxes/Hitboxes) to prevent false positives blocking vision
	query.collide_with_areas = false
	query.collide_with_bodies = true

	if owner_node is CollisionObject3D:
		query.exclude = [owner_node.get_rid()]

	var space_state: PhysicsDirectSpaceState3D = owner_node.get_world_3d().direct_space_state
	var ray_result: Dictionary = space_state.intersect_ray(query)

	# If hit nothing, or hit the target
	if ray_result.is_empty() or ray_result.collider == target:
		return true

	return false


func _calculate_stealth_penalty(target: Node3D) -> float:
	if target.has_method("get_stealth_value"):
		return target.call("get_stealth_value")
	return 0.0


func _calculate_detection_chance(distance: float, angle: float, stealth: float) -> float:
	var distance_factor: float = 1.0 - (distance / config.visual_range)
	var angle_factor: float = 1.0 - (abs(angle) / (config.field_of_view / 2.0))
	var base_chance: float = (
		(distance_factor * config.distance_weight + angle_factor * config.angle_weight) / (config.distance_weight + config.angle_weight)
	)

	# Simple baseline guarantee
	base_chance = max(0.5, base_chance)
	return clamp(base_chance * (1.0 - stealth), 0.0, 1.0)
