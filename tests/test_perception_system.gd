## Verifies PerceptionSystem purges dead targets from known_entities
extends Node


class FakeHealthTarget:
	extends Node3D
	var health: HealthComponent


class InvestigationPerception:
	extends PerceptionSystem
	var alerts: int = 0


	func share_investigation() -> void:
		alerts += 1


class FinishedRoute:
	extends NPCMovementController
	var requests: int = 0
	var search_steps: int = 0


	func request_clear_target(_target: Vector3) -> bool:
		requests += 1
		return true


	func request_nearby_target(_center: Vector3, _radius: float) -> bool:
		search_steps += 1
		return true


	func has_route() -> bool:
		return true


	func is_navigation_finished() -> bool:
		return true


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	_test_dead_target_purged_from_known_entities()
	_test_alive_target_not_purged()
	_test_closest_target_selection()
	_test_investigation_after_arrival()
	_test_scan_detects_target_behind_observer()
	print("PerceptionSystem test completed.")
	self.queue_free()


func _test_dead_target_purged_from_known_entities() -> void:
	var perception: PerceptionSystem = PerceptionSystem.new()
	var target: FakeHealthTarget = FakeHealthTarget.new()
	target.health = HealthComponent.new()
	target.health.max_health = 10
	target.health.current_health = 0

	perception.known_entities[target] = KnownEntityData.new(target, Vector3.ZERO, 1.0)
	var purged: bool = perception._purge_if_dead(target)

	assert(purged, "PerceptionSystem: dead target not reported as purged")
	assert(not perception.known_entities.has(target), "PerceptionSystem: dead target still present after purge")

	target.free()
	perception.free()


func _test_closest_target_selection() -> void:
	var perception: PerceptionSystem = PerceptionSystem.new()
	var observer: Node3D = Node3D.new()
	add_child(observer)
	perception._owner_node = observer
	perception.config = PerceptionConfig.new()
	var audible_position: Vector3 = Vector3.RIGHT * perception.config.hearing_range
	perception._on_sound_played(audible_position * 2.0)
	assert(not perception.has_investigation_point(), "Distant sound triggered investigation in " + name)
	perception._on_sound_played(audible_position)
	assert(perception.has_investigation_point() and perception.investigation_position == audible_position, "Sound at hearing limit missed in " + name)
	perception.clear_investigation_point()
	var near_target: FakeHealthTarget = FakeHealthTarget.new()
	var far_target: FakeHealthTarget = FakeHealthTarget.new()
	var far_memory: KnownEntityData = KnownEntityData.new(far_target, Vector3.RIGHT * 8.0, 1.0)
	var near_memory: KnownEntityData = KnownEntityData.new(near_target, Vector3.RIGHT, 0.1)
	perception.known_entities[far_target] = far_memory
	perception.known_entities[near_target] = near_memory
	perception._on_sound_played(audible_position)
	assert(not perception.has_investigation_point(), "Sound distracted NPC from known target in " + name)
	assert(perception.get_best_target_data() == near_memory, "Nearest tracked target lost to confidence in " + name)
	near_memory.last_detection_time -= PerceptionSystem.VISUAL_TRACK_DURATION
	assert(perception.get_best_target_data() == far_memory, "Tracked target lost to stale memory in " + name)
	far_memory.last_detection_time -= PerceptionSystem.VISUAL_TRACK_DURATION
	assert(perception.get_best_target_data() == near_memory, "Nearest remembered target skipped in " + name)
	perception._on_sound_played(audible_position)
	perception.report_last_sighting(near_memory)
	assert(
		perception.has_investigation_point() and perception.investigation_position == audible_position,
		"Older sighting displaced fresh sound in " + name,
	)
	near_memory.last_detection_time -= perception.config.memory_duration
	far_target.free()
	assert(perception.get_best_target_data() == null and perception.known_entities.is_empty(), "Invalid memories retained in " + name)
	near_target.free()
	observer.free()
	perception.free()


func _test_alive_target_not_purged() -> void:
	var perception: PerceptionSystem = PerceptionSystem.new()
	var target: FakeHealthTarget = FakeHealthTarget.new()
	target.health = HealthComponent.new()
	target.health.max_health = 10
	target.health.current_health = 5

	perception.known_entities[target] = KnownEntityData.new(target, Vector3.ZERO, 1.0)
	var purged: bool = perception._purge_if_dead(target)

	assert(not purged, "PerceptionSystem: alive target incorrectly purged")
	assert(perception.known_entities.has(target), "PerceptionSystem: alive target incorrectly erased")

	target.free()
	perception.free()


func _test_investigation_after_arrival() -> void:
	var npc: NPCEntity = NPCEntity.new()
	var movement: FinishedRoute = FinishedRoute.new()
	var perception: InvestigationPerception = InvestigationPerception.new()
	var action: InvestigateAction = InvestigateAction.new()
	npc.npc_movement_controller = movement
	npc.perception_system = perception
	perception.config = PerceptionConfig.new()
	perception.set_investigation_point(Vector3.RIGHT)
	var body_transform: Transform3D = npc.transform
	assert(not action.perform(npc, 0.1, { }), "Arrival ended investigation in " + name)
	assert(
		npc.transform == body_transform and is_equal_approx(perception.sight_yaw_offset, InvestigateAction.SCAN_SPEED * 0.1),
		"Scan must turn only sight in " + name,
	)
	assert(not action.perform(npc, 0.1, { }) and movement.requests == 1, "Finished route requested again in " + name)
	assert(movement.search_steps == 2, "Local search walk waited for a full sweep in " + name)
	assert(perception.alerts == 1, "Action did not recruit once on entry in " + name)
	action.exit(npc)
	assert(is_zero_approx(perception.sight_yaw_offset), "Interrupted scan kept sight offset in " + name)
	assert(not action.perform(npc, 0.1, { }) and movement.requests == 2, "Resumed investigation skipped route in " + name)
	perception.clear_investigation_point()
	assert(action.perform(npc, 0.1, { }), "Investigation outlived evidence in " + name)
	action.free()
	perception.free()
	movement.free()
	npc.free()


func _test_scan_detects_target_behind_observer() -> void:
	var observer: Node3D = Node3D.new()
	var target: Node3D = Node3D.new()
	add_child(observer)
	add_child(target)
	target.position = Vector3.FORWARD * 10.0
	var visual: VisualConfig = VisualConfig.new()
	visual.distance_weight = 0.0
	visual.collision_mask = 0
	var processor: VisualProcessor = VisualProcessor.new(visual)
	assert(not processor.detect(observer, target).is_detected, "Rear target visible before scan in " + name)
	assert(processor.detect(observer, target, PI).is_detected, "Scan missed unobstructed rear target in " + name)
	target.position = Vector3.BACK * 10.0
	assert(processor.detect(observer, target, PI).is_detected, "Rear sweep disabled frontal vision in " + name)
	target.free()
	observer.free()
