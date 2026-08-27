@abstract class_name Collectible
extends Area3D

@export var data: CollectibleData
@export var respawn_delay: float = 5.0

## set after chunk alignment via call_deferred
var spawn_position: Vector3

var collect_sounds: Array[AudioStream] = []

var float_tween: Tween
var rot_tween: Tween

## Children should override this instead of _ready()
@abstract func _child_ready() -> void


func _ready() -> void:
	assert(data != null, "Collectible data missing on " + name)
	data.validate_external_resource()

	body_entered.connect(_on_body_entered)
	add_to_group(Groups.COLLECTIBLES)
	_child_ready()

	# chunk may not be aligned yet when _ready() fires
	_record_spawn_position.call_deferred()

	_setup_float_animation()


# TODO This should be a data driven id check instead of position, even more while using procedural generation
func _record_spawn_position() -> void:
	spawn_position = global_position


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		SoundManager.play_sound(collect_sounds.pick_random(), SoundManager.SoundCategory.SFX, global_position)
		_apply_effect(body as PlayerEntity)
		# TODO Refactor to be an exported bool instead
		if data is StatusCollectible:
			await _respawn_collectible()
		else:
			GameEvents.collectible_consumed.emit(spawn_position)
			queue_free()


func _apply_effect(player: PlayerEntity) -> void:
	data.apply_effect(player)


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
	await get_tree().create_timer(respawn_delay).timeout
	visible = true
	float_tween.play()
	rot_tween.play()
	set_deferred("monitoring", true)
