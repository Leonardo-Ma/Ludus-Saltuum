class_name Checkpoint
extends Area3D

signal checkpoint_activated(checkpoint_node: Checkpoint)

const ACTIVATION_SOUNDS: Array[AudioStream] = [
	preload("uid://elo0urfpuyn7"),  # rise01
	preload("uid://cslbkk8dlfqo2"),  # rise02
	preload("uid://ot2jiajcrnw8"),  # rise03
]

@export var is_active: bool = false
@export var should_save_checkpoint: bool = true
var parent_chunk: LevelChunk = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# TODO BUG Improve this, maybe signal or move somewhere else. Shouldn't traverse the node path
	# Auto-detect parent LevelChunk (may be null for checkpoints outside chunks)
	var current: Node = self
	while current:
		if current is LevelChunk:
			parent_chunk = current as LevelChunk
			break
		current = current.get_parent()


func activate_checkpoint() -> void:
	is_active = true

	checkpoint_activated.emit(self)
	CheckpointManager.on_checkpoint_activated(self)
	SoundManager.play_sound(ACTIVATION_SOUNDS.pick_random(), SoundManager.SoundCategory.SFX, global_position)

	var tween: Tween = create_tween()
	var original_scale: Vector3 = scale
	tween.tween_property(self, "scale", original_scale * 1.3, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", original_scale, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var light: OmniLight3D = OmniLight3D.new()
	light.light_color = Color.YELLOW
	light.light_energy = 5.0
	light.omni_range = 3.0
	add_child(light)

	var light_tween: Tween = create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	light_tween.tween_callback(light.queue_free)


func deactivate_checkpoint() -> void:
	is_active = false
	# TODO Add deactivation logic


func _on_body_entered(body: Node3D) -> void:
	if not is_active and body.is_in_group(Groups.CONTROLLED):
		activate_checkpoint()
