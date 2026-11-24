@abstract class_name Collectible
extends Area3D

@export_category("Core")
@export var data: CollectibleData
@export var respawn_delay: float = 5.0

@export_category("Procedurally Generation")
## False when outside level chunk, requires static_id set in editor
@export var is_procedurally_spawned: bool = true
## Must be unique
@export var static_id: StringName = &""

var procedural_id: StringName = &""
var collectible_id: StringName = &""

var collect_sounds: Array[AudioStream] = []

var float_tween: Tween
var rot_tween: Tween
var _respawn_tween: Tween

var collected: bool = false


## Children should override this instead of _ready()
@abstract func _child_ready() -> void


func _ready() -> void:
	assert(data != null, "Collectible data missing on " + name)
	data.validate_external_resource()

	body_entered.connect(_on_body_entered)
	add_to_group(Groups.COLLECTIBLES)
	_child_ready()

	if not is_procedurally_spawned:
		assert(static_id != &"", "Collectible static_id not set on non-procedural instance " + name)
		collectible_id = static_id

	_setup_float_animation()


func assign_procedural_id(seed_value: int, scene_local_path: NodePath) -> void:
	assert(is_procedurally_spawned, "Procedural id assigned to non-procedural collectible " + name)
	procedural_id = StringName(scene_local_path)
	collectible_id = ProceduralId.spawn_id(seed_value, scene_local_path)
	assert(collectible_id != &"", "Collectible identity not assigned on " + name)


func _on_body_entered(body: Node3D) -> void:
	if visible and body.is_in_group(Groups.CONTROLLED):
		assert(collectible_id != &"", "Collectible ID missing in " + name)
		AudioManager.play_sound(collect_sounds.pick_random(), AudioManager.SoundBus.SFX, global_position)
		_apply_effect(body)
		if data is StatusCollectible:
			_respawn_collectible()
		else:
			set_collected_state(true)
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
