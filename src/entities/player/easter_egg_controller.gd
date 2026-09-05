## Tracks Easter eggs discovered
class_name EasterEggController
extends Node

signal found(easter_egg_name: EasterEgg.Name)

var easter_eggs_found: int = 0
var found_easter_eggs: Dictionary[EasterEgg.Name, bool] = { }


func _ready() -> void:
	found.connect(_on_found)


func _on_found(easter_egg_name: EasterEgg.Name) -> void:
	if not found_easter_eggs.has(easter_egg_name):
		found_easter_eggs[easter_egg_name] = true
		easter_eggs_found += 1
