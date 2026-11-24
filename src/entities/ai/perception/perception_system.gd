## Main system node that processes sensory modules to build known entity memory
class_name PerceptionSystem
extends Node

signal perception_updated(detections: Array)

const UPDATE_JITTER: float = 0.25
## Seconds a target stays tracked after last detection
const VISUAL_TRACK_DURATION: float = 0.5

var debug_mode: bool = false
## Horizontal sight offset from body facing during investigation
var sight_yaw_offset: float = 0.0

var config: PerceptionConfig
var known_entities: Dictionary = { } # Node3D -> KnownEntityData
## Place to search, meaningful only while has_investigation_point() is true
var investigation_position: Vector3 = Vector3.ZERO
var _visual_processor: VisualProcessor
var _next_update_time: float = 0.0
var _investigation_expires_at: float = 0.0
var _last_stimulus_time: float = -INF
var _can_share_investigation: bool = false
var _owner_node: Node3D
var _debug_node: PerceptionDebug


func _enter_tree() -> void:
	AudioManager.sound_played.connect(_on_sound_played)


func _exit_tree() -> void:
	AudioManager.sound_played.disconnect(_on_sound_played)


func _ready() -> void:
	_owner_node = self.owner as Node3D
	assert(_owner_node != null, "PerceptionSystem must be a child of a Node3D in " + self.name)

	var entity: NPCEntity = _owner_node
	if entity:
		entity.melee_attacked.connect(_on_owner_attack)
		entity.magic_casted.connect(_on_owner_attack)
		if entity.perception_config:
			config = entity.perception_config
		if entity.get("debug_perception"):
			debug_mode = true

	if config == null:
		config = PerceptionConfig.new()

	_visual_processor = VisualProcessor.new(config.visual)
	_next_update_time = Time.get_ticks_msec() / 1000.0 + randf_range(0.0, config.update_interval)

	if debug_mode:
		_debug_node = PerceptionDebug.new()
		_debug_node.name = "PerceptionDebug"
		add_child(_debug_node)


func _process(_delta: float) -> void:
	if not is_instance_valid(_owner_node):
		return

	var current_time: float = Time.get_ticks_msec() / 1000.0
	if current_time < _next_update_time:
		return

	_next_update_time = current_time + config.update_interval * randf_range(1.0 - UPDATE_JITTER, 1.0 + UPDATE_JITTER)
	_process_perception()


func _process_perception() -> void:
	var current_detections: Array[DetectionResult] = []
	for group: String in owner.target_groups:
		for target: Node in get_tree().get_nodes_in_group(group):
			if target == _owner_node or not is_instance_valid(target) or not target is Node3D:
				continue
			if _purge_if_dead(target):
				continue

			var detection: DetectionResult = _visual_processor.detect(_owner_node, target as Node3D, sight_yaw_offset)
			if detection.is_detected:
				current_detections.append(detection)
				_register_target(target as Node3D, detection.detected_position, detection.confidence)

	# If anyone cares about instant updates
	if not current_detections.is_empty():
		perception_updated.emit(current_detections)


## Erases target from known_entities if its health reached zero, returns true if purged
func _purge_if_dead(target: Node) -> bool:
	if not (target.has_method("get_health") or "health" in target):
		return false
	var target_health: HealthComponent = target.get_health() if target.has_method("get_health") else target.get("health")
	if target_health and target_health.current_health <= 0:
		known_entities.erase(target)
		return true
	return false


## Select closest recently detected target, falling back to closest remembered position
func get_best_target_data() -> KnownEntityData:
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var closest_tracked: KnownEntityData
	var closest_remembered: KnownEntityData
	var tracked_distance: float = INF
	var remembered_distance: float = INF

	for target: Variant in known_entities.keys():
		var known: KnownEntityData = known_entities[target]
		if not is_instance_valid(target) or not known.is_valid(current_time, config.memory_duration):
			# Memory expired
			known_entities.erase(target)
			continue

		var distance_squared: float = _owner_node.global_position.distance_squared_to(known.last_known_position)
		if current_time - known.last_detection_time < VISUAL_TRACK_DURATION:
			if distance_squared < tracked_distance:
				closest_tracked = known
				tracked_distance = distance_squared
		elif distance_squared < remembered_distance:
			closest_remembered = known
			remembered_distance = distance_squared

	return closest_tracked if closest_tracked != null else closest_remembered


func has_valid_target() -> bool:
	return get_best_target_data() != null


#region Awareness
## Noise or ally call, ignored while directly tracking a target
func report_stimulus(stimulus_position: Vector3, shared_search: bool = false) -> void:
	if shared_search and has_investigation_point():
		return
	var target: KnownEntityData = get_best_target_data()
	var now: float = Time.get_ticks_msec() / 1000.0
	if target and now - target.last_detection_time < VISUAL_TRACK_DURATION:
		return
	_last_stimulus_time = now
	set_investigation_point(stimulus_position)
	_can_share_investigation = not shared_search


## Prefer fresh sounds and ally calls over older visual evidence
func report_last_sighting(target: KnownEntityData) -> void:
	if target.last_detection_time > _last_stimulus_time:
		set_investigation_point(target.last_known_position)


## Hit grants full awareness of attacker, even outside field of view
func report_hit(attacker: Node3D) -> void:
	for group: String in owner.target_groups:
		if attacker.is_in_group(group):
			_register_target(attacker, attacker.global_position, 1.0, true)
			return


func set_investigation_point(point: Vector3) -> void:
	_can_share_investigation = true
	investigation_position = point
	_investigation_expires_at = Time.get_ticks_msec() / 1000.0 + config.investigation_duration


func clear_investigation_point() -> void:
	_investigation_expires_at = 0.0


func has_investigation_point() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _investigation_expires_at


## Recruit nearby allies once for local evidence, keeping shared alerts within sender's radius
func share_investigation() -> void:
	if _can_share_investigation:
		_can_share_investigation = false
		_alert_allies(investigation_position, config.investigation_alert_radius, true)


## First sighting or incoming hit calls allies, later sightings only refresh memory
func _register_target(target: Node3D, target_position: Vector3, confidence: float, hit: bool = false) -> void:
	if known_entities.has(target):
		var known: KnownEntityData = known_entities[target]
		known.update(target_position, confidence)
		if not hit:
			return
	else:
		known_entities[target] = KnownEntityData.new(target, target_position, confidence)
	_alert_allies(target_position, config.ally_alert_radius)


func _on_owner_attack() -> void:
	_alert_allies(_owner_node.global_position, config.ally_alert_radius)


func _alert_allies(alert_position: Vector3, radius: float, shared_search: bool = false) -> void:
	if owner.health.current_health <= 0:
		return

	var radius_squared: float = radius * radius
	for node: Node in get_tree().get_nodes_in_group(Groups.ENEMIES):
		var ally: NPCEntity = node as NPCEntity
		assert(ally != null, "Non NPCEntity in enemies group, found by " + self.name)
		if ally == _owner_node or ally.get_world_3d() != _owner_node.get_world_3d() or ally.health.current_health <= 0:
			continue
		if _owner_node.global_position.distance_squared_to(ally.global_position) <= radius_squared:
			ally.perception_system.report_stimulus(alert_position, shared_search)


func _on_sound_played(sound_position: Vector3) -> void:
	if not is_instance_valid(_owner_node) or not _owner_node.is_inside_tree():
		return
	if _owner_node is NPCEntity:
		var enemy: NPCEntity = _owner_node
		if enemy.health.current_health <= 0:
			return
	if _owner_node.global_position.distance_squared_to(sound_position) <= config.hearing_range * config.hearing_range:
		report_stimulus(sound_position)
#endregion
