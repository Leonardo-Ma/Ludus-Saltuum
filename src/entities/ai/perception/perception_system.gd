## Main system node that processes sensory modules to build known entity memory
class_name PerceptionSystem
extends Node

signal perception_updated(detections: Array)

var debug_mode: bool = false

var config: PerceptionConfig
var known_entities: Dictionary = {}  # Node3D -> KnownEntityData
var _visual_processor: VisualProcessor
var _last_update_time: float = 0.0
var _owner_node: Node3D
var _debug_node: PerceptionDebug


func _ready() -> void:
	_owner_node = self.owner as Node3D
	assert(_owner_node != null, "PerceptionSystem must be a child of a Node3D in " + self.name)

	var entity: AggressiveEntity = _owner_node as AggressiveEntity
	if entity:
		if entity.perception_config:
			config = entity.perception_config
		if entity.get("debug_perception"):
			debug_mode = true

	if config == null:
		config = PerceptionConfig.new()

	_visual_processor = VisualProcessor.new(config.visual)

	if debug_mode:
		_debug_node = PerceptionDebug.new()
		_debug_node.name = "PerceptionDebug"
		add_child(_debug_node)


func _process(_delta: float) -> void:
	if not is_instance_valid(_owner_node):
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time - _last_update_time < config.update_interval:
		return

	_last_update_time = current_time
	_process_perception()


# TODO Create target groups, remove player being only target
func _process_perception() -> void:
	var current_detections: Array[DetectionResult] = []

	for group: String in owner.target_groups:
		var all_targets: Array[Node] = get_tree().get_nodes_in_group(group)
		for target: Node in all_targets:
			if target == _owner_node or not is_instance_valid(target) or not target is Node3D:
				continue

			# Additional health validation to not detect dead bodies
			if target.has_method("get_health") or "health" in target:
				var target_health: Health = target.get_health() if target.has_method("get_health") else target.get("health")
				if target_health and target_health.current_health <= 0.0:
					known_entities.erase(target)
					continue

			var detection: DetectionResult = _visual_processor.detect(_owner_node, target as Node3D)
			if detection.is_detected:
				current_detections.append(detection)
				if known_entities.has(target):
					var known: KnownEntityData = known_entities[target]
					known.update(detection.detected_position, detection.confidence)
				else:
					known_entities[target] = KnownEntityData.new(target as Node3D, detection.detected_position, detection.confidence)

	# If anyone cares about instant updates
	if not current_detections.is_empty():
		perception_updated.emit(current_detections)


## Gets the best known target data (KnownEntityData)
func get_best_target_data() -> KnownEntityData:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var best_data: KnownEntityData = null
	var highest_confidence: float = -1.0

	var to_remove: Array = []

	for target: Node3D in known_entities:
		if not is_instance_valid(target):
			to_remove.append(target)
			continue

		var known: KnownEntityData = known_entities[target]
		if known.is_valid(current_time, config.memory_duration):
			# Simplistic "best" target by confidence
			if known.confidence > highest_confidence:
				highest_confidence = known.confidence
				best_data = known
		else:
			# Memory expired
			to_remove.append(target)

	for target: Node3D in to_remove:
		known_entities.erase(target)

	return best_data


func has_valid_target() -> bool:
	return get_best_target_data() != null
