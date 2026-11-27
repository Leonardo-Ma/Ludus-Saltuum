@tool
class_name WeaponVisual
extends Node

## Replaces weapon at hand socket with equipped weapon scene
## Positions swing trail on striking end of equipped mesh

signal weapon_replaced

@export var socket: Node3D
@export var swing_trail: Trail3D

var _instance: Node3D
var _swing_trail_active: bool

@onready var _animation: AnimationController = %AnimationController


func _ready() -> void:
	assert(socket, "Socket missing in " + name)
	if not Engine.is_editor_hint():
		_setup_swing_trail()


#region Weapon Socket
func replace_weapon_visual(weapon: WeaponAsset) -> void:
	if not Engine.is_editor_hint():
		_clear_swing_trail()

	if is_instance_valid(_instance):
		socket.remove_child(_instance)
		_instance.queue_free()
		_instance = null

	if weapon and weapon.weapon_scene:
		_instance = weapon.weapon_scene.instantiate()
		assert(_instance, "Weapon scene root must be Node3D in " + name)
		socket.add_child(_instance)

	if not Engine.is_editor_hint():
		_refresh_swing_trail()
		weapon_replaced.emit()
#endregion


#region Swing Trail
## Called by melee animation keys
func set_swing_trail_enabled(enabled: bool) -> void:
	if not Engine.is_editor_hint() and _animation.is_action_running(AnimKeys.MELEE):
		_swing_trail_active = enabled
		swing_trail.emitting = enabled and _instance != null


func _setup_swing_trail() -> void:
	assert(swing_trail, "Swing trail missing in " + name)
	assert(_animation, "AnimationController missing in " + name)
	# Keep generated trail bounds out of editor saves
	swing_trail.process_mode = Node.PROCESS_MODE_INHERIT
	_animation.action_finished.connect(_on_action_ended)
	_animation.action_interrupted.connect(_on_action_ended)


func _clear_swing_trail() -> void:
	swing_trail.emitting = false
	swing_trail.clear()


func _refresh_swing_trail() -> void:
	if _instance:
		_position_swing_trail()
	swing_trail.emitting = _swing_trail_active and _instance != null


func _position_swing_trail() -> void:
	var world_to_weapon: Transform3D = _instance.global_transform.affine_inverse()
	var bounds: AABB
	if _instance is MeshInstance3D:
		var root_mesh: MeshInstance3D = _instance
		bounds = root_mesh.get_aabb()
	for mesh: MeshInstance3D in _instance.find_children("*", "MeshInstance3D", true, false):
		bounds = bounds.merge(world_to_weapon * mesh.global_transform * mesh.get_aabb())
	var trail_head: Vector3 = bounds.get_center()
	trail_head.y = bounds.end.y * 0.85
	swing_trail.global_transform = _instance.global_transform.translated_local(trail_head)


func _on_action_ended(action_id: StringName) -> void:
	if action_id == AnimKeys.MELEE:
		_swing_trail_active = false
		swing_trail.emitting = false
#endregion
