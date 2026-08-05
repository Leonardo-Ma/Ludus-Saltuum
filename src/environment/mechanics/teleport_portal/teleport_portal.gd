## Teleports player between linked portals after crossing portal plane
## Uses a plane-based detection system and handles cooldowns to prevent teleport loops
@tool
class_name TeleportPortal
extends Area3D

const TELEPORT_SOUNDS: Array[AudioStream] = [
	preload("uid://kw3i7ckrkmv8"),  # teleport.wav
]
@export var linked_portal: TeleportPortal
@export var cooldown_duration_seconds: float = 3.0

# TODO Remove auxiliary variable
#gdlint: disable=class-definitions-order
var _portal_color: Color = Color("#4db2ff23")

@export var portal_color: Color:
	get:
		return _portal_color
	set(value):
		_portal_color = value
		if Engine.is_editor_hint():
			_update_enabled_mesh_color()

			if linked_portal:
				linked_portal._portal_color = value
				linked_portal._update_enabled_mesh_color()

var is_disabled: bool = false
#gdlint: enable=class-definitions-order
var _cooldown_timer: float = 0.0

## Tracks players inside the portal and their entry side of the portal plane (positive/negative)
var _tracked_players: Dictionary[Node3D, float] = {}
## Prevents rapid back-and-forth teleportation by blocking players on cooldown
var _cooldown_players: Dictionary[Node3D, bool] = {}

@onready var enabled_mesh: MeshInstance3D = %EnabledMesh


# TODO Decouple tool logic from teleport logic
func _ready() -> void:
	if Engine.is_editor_hint():
		_init_editor_color()
		return

	# TODO Change the tool aspect to automatically link the other portal
	assert(linked_portal != null, "Linked portal missing in " + name)
	assert(enabled_mesh != null, "EnabledMesh missing in " + name)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_mesh_visibility()
	_update_enabled_mesh_color()
	set_physics_process(true)


#region Tool editor logic
func _init_editor_color() -> void:
	## Read existing material color as default if export hasn't been set
	if _portal_color == Color("#4db2ff23") and enabled_mesh and enabled_mesh.mesh:
		for i: int in enabled_mesh.mesh.get_surface_count():
			var mat: Material = enabled_mesh.mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				_portal_color = mat.albedo_color
				break
	_update_enabled_mesh_color()


func _update_enabled_mesh_color() -> void:
	if not enabled_mesh or not enabled_mesh.mesh:
		return
	var mat: Material = enabled_mesh.get_active_material(0)
	enabled_mesh.set_surface_override_material(0, mat.duplicate())
	for i: int in enabled_mesh.mesh.get_surface_count():
		mat = enabled_mesh.get_surface_override_material(i)
		if mat is StandardMaterial3D:
			mat.albedo_color = portal_color


#endregion


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
		if _cooldown_timer <= 0.0:
			set_disabled(false)
			_cooldown_players.clear()

	if _tracked_players.is_empty() or is_disabled:
		return

	## Cache the players array to avoid repeated .keys() calls
	var players: Array[Node3D] = _tracked_players.keys()

	for player: Node3D in players:
		if not is_instance_valid(player):
			_tracked_players.erase(player)
			continue

		var previous_side: float = _tracked_players[player]
		var current_side: float = _portal_side(player.global_position)

		if previous_side > 0.0:
			if not _cooldown_players.has(player):
				_cooldown_players[player] = true
				set_disabled(true)
				_cooldown_timer = cooldown_duration_seconds

				SoundManager.play_sound(TELEPORT_SOUNDS.pick_random(), SoundManager.SoundCategory.SFX, player.global_position)

				var player_portal_controller: PortalController = player.portal_controller
				await player_portal_controller.begin_portal_transition(linked_portal, player)

				linked_portal._cooldown_players[player] = true
				linked_portal.set_disabled(true)
				linked_portal._cooldown_timer = cooldown_duration_seconds

		if _tracked_players.has(player):
			_tracked_players[player] = current_side


func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body.is_in_group(Groups.PLAYERS) or body.is_in_group(Groups.ENEMIES) or is_disabled or _cooldown_players.has(body):
		return

	_tracked_players[body] = _portal_side(body.global_position)


func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body.is_in_group(Groups.PLAYERS) or body.is_in_group(Groups.ENEMIES):
		return

	_tracked_players.erase(body)


## What side the portal is on
## Positive = front (entry side), Negative = back (exit side)
func _portal_side(world_position: Vector3) -> float:
	return global_transform.basis.z.dot(world_position - global_position)


## Adjusts velocity to match the linked portal's orientation
func transform_velocity(velocity: Vector3) -> Vector3:
	return linked_portal.global_basis * global_basis.inverse() * velocity


## Updates visibility of both enabled and disabled meshes based on portal state
func _update_mesh_visibility() -> void:
	var mat: Material = enabled_mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color = Color(portal_color.r, portal_color.g, portal_color.b, 0.2 if is_disabled else portal_color.a)


## Public method to toggle the portal's disabled state
func set_disabled(value: bool) -> void:
	is_disabled = value
	_update_mesh_visibility()
