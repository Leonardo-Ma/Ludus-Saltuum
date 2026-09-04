class_name WanderAction
extends GoapAction

const WANDER_RADIUS: float = 10.0
const WANDER_COOLDOWN: float = 2.0
var _wander_timer: float = 0.0
var _wander_duration: float = 5.0
var _wander_target_set: bool = false
var _last_wander_end_time: int = 0


func get_custom_class_name() -> String:
	return "WanderAction"


func is_valid(_blackboard: Dictionary) -> bool:
	return true


func get_cost(_blackboard: Dictionary) -> int:
	return 1


func get_preconditions() -> Dictionary:
	return { }


func get_effects() -> Dictionary:
	return { "is_wandering": true }


# TODO Define actor to use walk speed
# This needs to be changed with navigation agent 3d: _on_navigation_agent_3d_velocity_computed
func perform(_actor: Node, _delta: float, _blackboard: Dictionary) -> bool:
	var actor_position: Vector3 = _blackboard.get("position", _actor.global_position)
	var current_time: int = Time.get_ticks_msec()

	if current_time - _last_wander_end_time < int(WANDER_COOLDOWN * 1000.0):
		if _wander_target_set:
			_actor.navigation_controller.stop()
			_wander_target_set = false
			_wander_timer = 0.0
		return false

	if not _wander_target_set or _wander_timer >= _wander_duration:
		var random_offset: Vector3 = Vector3(randf_range(-WANDER_RADIUS, WANDER_RADIUS), 0, randf_range(-WANDER_RADIUS, WANDER_RADIUS))
		var wander_target: Vector3 = actor_position + random_offset

		_actor.navigation_controller.set_physics_process(true)
		_actor.navigation_controller.update_target_location(wander_target)
		_wander_target_set = true
		_wander_timer = 0.0

	_wander_timer += _delta

	if _wander_timer >= _wander_duration:
		_last_wander_end_time = current_time
		_actor.navigation_controller.stop()
		_wander_target_set = false
		_wander_timer = 0.0
		return true

	return false
