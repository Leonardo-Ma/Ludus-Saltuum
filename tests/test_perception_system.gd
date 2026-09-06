## Verifies PerceptionSystem purges dead targets from known_entities
extends Node


class FakeHealthTarget:
	extends Node3D
	var health: Health


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_test_dead_target_purged_from_known_entities()
	_test_alive_target_not_purged()
	print("PerceptionSystem test completed.")
	self.queue_free()


func _test_dead_target_purged_from_known_entities() -> void:
	var perception: PerceptionSystem = PerceptionSystem.new()
	var target: FakeHealthTarget = FakeHealthTarget.new()
	target.health = Health.new()
	target.health.max_health = 10
	target.health.current_health = 0

	perception.known_entities[target] = KnownEntityData.new(target, Vector3.ZERO, 1.0)
	var purged: bool = perception._purge_if_dead(target)

	assert(purged, "PerceptionSystem: dead target not reported as purged")
	assert(not perception.known_entities.has(target), "PerceptionSystem: dead target still present after purge")

	target.free()
	perception.free()


func _test_alive_target_not_purged() -> void:
	var perception: PerceptionSystem = PerceptionSystem.new()
	var target: FakeHealthTarget = FakeHealthTarget.new()
	target.health = Health.new()
	target.health.max_health = 10
	target.health.current_health = 5

	perception.known_entities[target] = KnownEntityData.new(target, Vector3.ZERO, 1.0)
	var purged: bool = perception._purge_if_dead(target)

	assert(not purged, "PerceptionSystem: alive target incorrectly purged")
	assert(perception.known_entities.has(target), "PerceptionSystem: alive target incorrectly erased")

	target.free()
	perception.free()
