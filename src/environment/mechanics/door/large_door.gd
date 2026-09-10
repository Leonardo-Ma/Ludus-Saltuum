class_name LargeDoor
extends Node3D

const DOOR_OPEN: AudioStreamWAV = preload("uid://cx5j2ge2f0m6q")
const DOOR_CLOSE: AudioStreamWAV = preload("uid://diaumdug5gwrg")

@export var _button: Area3D = null

@onready var door: MeshInstance3D = $Door


func _ready() -> void:
	_button.button_toggled_on.connect(open)
	_button.button_toggled_off.connect(close)


func open() -> void:
	door.rotation.y = -90
	SoundManager.play_sound(DOOR_OPEN, SoundManager.SoundCategory.SFX, global_position)


func close() -> void:
	door.rotation.y = 0
	SoundManager.play_sound(DOOR_CLOSE, SoundManager.SoundCategory.SFX, global_position)
