@icon("uid://b2ggug31fd52y") # star.png
class_name Collectible
extends Area3D

## Applies pickup effects and tracks persistent collectible state

@export_category("Core")
@export var data: CollectibleData
@export var respawn_delay: float = 5.0
## If more than one is set, one is chosen at random upon collected
@export var collect_sounds: Array[AudioStream] = []

## Editor-assigned placement ID saved with scene for runtime use
## Storage keeps it out of Inspector
@export_storage var placement_id: StringName

## Unique across authored and procedural placements
var collectible_id: StringName = &""

var float_tween: Tween
var rot_tween: Tween
var _respawn_tween: Tween

var collected: bool = false


## Children should override this instead of _ready()
func _child_ready() -> void:
	pass


func _ready() -> void:
	assert(data != null, "Collectible data missing on " + name)
	data.validate_external_resource()

	if collectible_id == &"":
		collectible_id = AuthoredEntityId.resolve(self, placement_id)
		assert(owner == null or collectible_id != &"", "Placement ID or enclosing scope missing in " + name)

	body_entered.connect(_on_body_entered)
	add_to_group(Groups.COLLECTIBLES)
	_child_ready()
	assert(not collect_sounds.is_empty() and not collect_sounds.has(null), "Collect sounds missing on " + name)

	_setup_float_animation()


## Assigns a unique chunk placement ID before entering the tree
func assign_procedural_id(id: StringName) -> void:
	assert(not is_inside_tree() and collectible_id == &"" and id != &"", "Invalid procedural ID assignment in " + name)
	collectible_id = id


func _on_body_entered(body: Node3D) -> void:
	if visible and body.is_in_group(Groups.CONTROLLED):
		AudioManager.play_sound(collect_sounds.pick_random(), AudioManager.SoundBus.SFX, global_position)
		_apply_effect(body)
		if data is StatusCollectible:
			_respawn_collectible()
		else:
			set_collected_state(true)
			if collectible_id != &"":
				CollectiblesEvents.collectible_collected.emit(collectible_id)


func _apply_effect(player: Node3D) -> void:
	data.apply_effect(player)


func set_collected_state(is_collected: bool) -> void:
	if _respawn_tween and _respawn_tween.is_valid():
		_respawn_tween.kill()
	collected = is_collected
	visible = not collected
	set_deferred("monitoring", not collected)
	if collected:
		float_tween.pause()
		rot_tween.pause()
	else:
		float_tween.play()
		rot_tween.play()


# TODO: Transform this into an exportable variable bool
# That rotates vertically or horizontally
func _setup_float_animation() -> void:
	float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(self, "position:y", 0.5, 1.0).as_relative()
	float_tween.tween_property(self, "position:y", -0.5, 1.0).as_relative()

	rot_tween = create_tween()
	rot_tween.set_loops()
	rot_tween.tween_property(self, "rotation:y", TAU, 2.0).as_relative()


func _respawn_collectible() -> void:
	set_deferred("monitoring", false)
	visible = false
	float_tween.pause()
	rot_tween.pause()
	_respawn_tween = create_tween()
	_respawn_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_respawn_tween.tween_interval(respawn_delay)
	_respawn_tween.tween_callback(set_collected_state.bind(false))
