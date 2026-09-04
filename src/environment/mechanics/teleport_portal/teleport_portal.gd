## Teleports player between linked portals after crossing portal plane
## Uses a plane-based detection system and handles cooldowns to prevent teleport loops
@tool
class_name TeleportPortal
extends Area3D

const TELEPORT_SOUNDS: Array[AudioStream] = [
	preload("uid://kw3i7ckrkmv8"), # teleport.wav
]
@export var linked_portal: TeleportPortal
@export var cooldown_duration_seconds: float = 3.0

@export var portal_vfx: VFXPortalController

# TODO Remove auxiliary variable
var _portal_color: Color = Color("#4db2ff23")

@export var portal_color: Color:
	get:
		return _portal_color
	set(value):
		_portal_color = value
		if Engine.is_editor_hint() and portal_vfx:
			# This only works because meshes > geometry > material override > resource > Local to scene = true
			portal_vfx.set_portal_param("primary_color", value)

			if linked_portal:
				linked_portal.portal_vfx.set_portal_param("primary_color", value)

var is_disabled: bool = false
var _cooldown_timer: float = 0.0

## Tracks players inside the portal and their entry side of the portal plane (positive/negative)
var _tracked_players: Dictionary[Node3D, float] = { }
## Prevents rapid back-and-forth teleportation by blocking players on cooldown
var _cooldown_players: Dictionary[Node3D, bool] = { }


# TODO Decouple tool logic from teleport logic
func _ready() -> void:
	assert(portal_vfx, "Portal vfx must be assigned for " + name)
	if Engine.is_editor_hint():
		return

	portal_vfx.set_portal_param("primary_color", portal_color)

	# TODO Change the tool aspect to automatically link the other portal
	assert(linked_portal != null, "Linked portal missing in " + name)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_physics_process(true)


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
				linked_portal._cooldown_timer = cooldown_duration_seconds # gdlint-ignore private-access

		if _tracked_players.has(player):
			_tracked_players[player] = current_side


func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body.is_in_group(Groups.CONTROLLED) or body.is_in_group(Groups.ENEMIES) or is_disabled or _cooldown_players.has(body):
		return

	_tracked_players[body] = _portal_side(body.global_position)


func _on_body_exited(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not body.is_in_group(Groups.CONTROLLED) or body.is_in_group(Groups.ENEMIES):
		return

	_tracked_players.erase(body)


## What side the portal is on
## Positive = front (entry side), Negative = back (exit side)
func _portal_side(world_position: Vector3) -> float:
	return global_transform.basis.z.dot(world_position - global_position)


## Adjusts velocity to match the linked portal's orientation
func transform_velocity(velocity: Vector3) -> Vector3:
	return linked_portal.global_basis * global_basis.inverse() * velocity


## Public method to toggle the portal's disabled state
func set_disabled(value: bool) -> void:
	is_disabled = value
	if value:
		portal_vfx.close()
	else:
		portal_vfx.open()
