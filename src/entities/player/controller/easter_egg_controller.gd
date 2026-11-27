## Tracks Easter eggs discovered
class_name EasterEggController
extends Node

signal found(easter_egg_name: EasterEgg.Name)

var found_easter_eggs: Dictionary[EasterEgg.Name, bool] = { }


func discover(easter_egg_name: EasterEgg.Name) -> void:
	if found_easter_eggs.has(easter_egg_name):
		return
	found_easter_eggs[easter_egg_name] = true
	found.emit(easter_egg_name)
