class_name EntityCombatAudio
extends Node

## Manage attack and damaged sound effects

const DAMAGED_SOUNDS: Array[AudioStream] = [
	preload("uid://c2uxva6p1yaxw"), # chequered_ink/punch.wav
	preload("uid://ygovytmkf0xu"), # chequered_ink/punch_2.wav
	preload("uid://c4qxkql51g7pm"), # chequered_ink/punch_3.wav
]

## When attacking, called by animation player
const ATTACK_SOUNDS: Array[AudioStream] = [
	preload("uid://domodec4epc7f"), # sword_slice.wav
	#preload("uid://doay56c5x3rwr"),  # sword_clash_2.wav
]

@onready var _entity: CharacterBody3D = owner as CharacterBody3D
@onready var _health: HealthComponent = %HealthComponent


func initialize() -> void:
	assert(_entity, "Entity owner missing in " + name)
	assert(_health, "Health missing in " + _entity.name)

	_health.damaged.connect(_on_damaged)


func play_attack_sound() -> void:
	if ATTACK_SOUNDS.size() > 0:
		AudioManager.play_sound(ATTACK_SOUNDS.pick_random(), AudioManager.SoundBus.SFX, _entity.global_position)


func _on_damaged(_attack: Attack) -> void:
	AudioManager.play_sound(DAMAGED_SOUNDS.pick_random(), AudioManager.SoundBus.SFX, _entity.global_position)
