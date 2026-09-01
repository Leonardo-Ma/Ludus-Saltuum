extends Node

signal easter_egg_found(easter_egg_name: StringName)

var easter_eggs_found: int = 0
var found_easter_eggs: Dictionary = {}


func _ready() -> void:
	easter_egg_found.connect(_on_easter_egg_found)


func _on_easter_egg_found(easter_egg_name: StringName) -> void:
	if not found_easter_eggs.has(easter_egg_name):
		found_easter_eggs[easter_egg_name] = true
		easter_eggs_found += 1
		print(easter_eggs_found)
