extends StaticBody3D

@export var fade_in_seconds: int = 2
@export var fade_out_seconds: int = 3

var _is_cycle_running: bool = false
var _mesh_parts: Array[MeshInstance3D] = []
var _part_original_overlays: Dictionary[MeshInstance3D, Material] = {}
var _part_white_overlays: Dictionary[MeshInstance3D, StandardMaterial3D] = {}

@onready var surface: Area3D = $Surface
@onready var body_collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	_mesh_parts = _collect_mesh_parts()
	for mesh_part: MeshInstance3D in _mesh_parts:
		_part_original_overlays[mesh_part] = mesh_part.material_overlay
		_part_white_overlays[mesh_part] = _create_white_overlay()
	surface.body_entered.connect(_on_character_step)


func _on_character_step(body: Node3D) -> void:
	if !body.is_in_group(Groups.PLAYERS) or _is_cycle_running:
		return
	_is_cycle_running = true
	surface.set_deferred("monitoring", false)
	await _play_vanish_effect(float(fade_out_seconds))
	disable()
	await get_tree().create_timer(fade_in_seconds).timeout
	surface.set_deferred("monitoring", true)
	body_collision.disabled = false  # collision before visual — no texture visible yet
	await _play_appear_effect(float(fade_in_seconds))
	_restore_original_overlays()
	_is_cycle_running = false


func enable() -> void:
	_restore_original_overlays()
	visible = true
	body_collision.disabled = false


func disable() -> void:
	visible = false
	body_collision.disabled = true


func _play_vanish_effect(duration: float) -> void:
	visible = true
	for mesh_part: MeshInstance3D in _mesh_parts:
		var white_overlay: StandardMaterial3D = _part_white_overlays[mesh_part]
		white_overlay.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
		mesh_part.material_overlay = white_overlay
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for mesh_part: MeshInstance3D in _mesh_parts:
		tween.tween_property(_part_white_overlays[mesh_part], "albedo_color:a", 1.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished


func _play_appear_effect(duration: float) -> void:
	# White overlay starts fully opaque (platform hidden), fades to reveal
	visible = true
	for mesh_part: MeshInstance3D in _mesh_parts:
		var white_overlay: StandardMaterial3D = _part_white_overlays[mesh_part]
		white_overlay.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
		mesh_part.material_overlay = white_overlay
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for mesh_part: MeshInstance3D in _mesh_parts:
		tween.tween_property(_part_white_overlays[mesh_part], "albedo_color:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished


func _restore_original_overlays() -> void:
	for mesh_part: MeshInstance3D in _mesh_parts:
		mesh_part.material_overlay = _part_original_overlays[mesh_part]


func _collect_mesh_parts() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in find_children("*", "MeshInstance3D", true, false):
		result.append(child as MeshInstance3D)
	return result


func _create_white_overlay() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	return material
