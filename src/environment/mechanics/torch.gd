@tool
class_name Torch
extends StaticBody3D

const GLOW_SOUND: AudioStream = preload("uid://la63nm5wsh1u") # flame.ogg

## If a area_trigger is assigned, torch will be disabled by default and only enabled when area_trigger is triggered
@export var area_trigger: RedTorchTrigger = null
@export var activation_delay: float = 0
@export var light_color: Color = Color("#ffff67"):
	set(value):
		light_color = value
		if omni_light_3d:
			omni_light_3d.light_color = value

var is_disabled: bool = false

@onready var omni_light_3d: OmniLight3D = %OmniLight3D


func _ready() -> void:
	if Engine.is_editor_hint():
		omni_light_3d.light_color = light_color
		return

	# Apply editor color at runtime
	omni_light_3d.light_color = light_color

	if area_trigger:
		omni_light_3d.visible = false
		area_trigger.red_torch_triggered.connect(_on_triggered)


func _on_triggered() -> void:
	if not omni_light_3d:
		return
	await get_tree().create_timer(activation_delay).timeout
	omni_light_3d.visible = true
	AudioManager.play_sound(GLOW_SOUND, AudioManager.SoundBus.SFX, global_position)
