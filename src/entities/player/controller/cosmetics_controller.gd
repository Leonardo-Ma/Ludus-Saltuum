@icon("uid://eajxvr72e3t1") # shirt.png
class_name CosmeticsController
extends Node

signal owned_changed
signal equipped_character_changed(character_asset: CharacterEntityAsset)

const DEFAULT_CHARACTER_ID: StringName = &"character.knight"

@export var character_catalog: CharacterEntityCatalog

var _character_ids: Array[StringName] = [DEFAULT_CHARACTER_ID]
var _equipped_character_id: StringName = DEFAULT_CHARACTER_ID


func _ready() -> void:
	assert(character_catalog != null, "Character catalog missing in " + name)
	assert(get_character_asset(DEFAULT_CHARACTER_ID) != null, "Default character missing in " + name)


func acquire(character_id: StringName) -> void:
	assert(not character_id.is_empty(), "Character ID cannot be empty in " + name)

	if owns(character_id):
		return

	_character_ids.append(character_id)
	owned_changed.emit()


func owns(character_id: StringName) -> bool:
	return character_id in _character_ids


func get_owned_ids() -> Array[StringName]:
	return _character_ids.duplicate()


func set_owned_ids(character_ids: Array[StringName]) -> void:
	_character_ids = character_ids.duplicate()

	assert(not _character_ids.has(StringName()), "Empty character ID in owned characters for " + name)

	if not owns(DEFAULT_CHARACTER_ID):
		_character_ids.append(DEFAULT_CHARACTER_ID)

	if not owns(_equipped_character_id):
		set_equipped_character_id(DEFAULT_CHARACTER_ID)

	owned_changed.emit()


func reset() -> void:
	_character_ids = [DEFAULT_CHARACTER_ID]
	set_equipped_character_id(DEFAULT_CHARACTER_ID)
	owned_changed.emit()


func equip(character_id: StringName) -> bool:
	if not owns(character_id):
		return false

	if _equipped_character_id == character_id:
		return true

	_set_equipped_character_id(character_id)
	return true


func get_equipped_character_id() -> StringName:
	return _equipped_character_id


func get_equipped_character_asset() -> CharacterEntityAsset:
	return get_character_asset(_equipped_character_id)


func set_equipped_character_id(character_id: StringName) -> void:
	var target_id: StringName = character_id if owns(character_id) else DEFAULT_CHARACTER_ID

	if _equipped_character_id == target_id:
		return

	_set_equipped_character_id(target_id)


func get_character_asset(character_id: StringName) -> CharacterEntityAsset:
	assert(character_catalog != null, "Character catalog missing in " + name)
	return character_catalog.get_character_asset(character_id)


func _set_equipped_character_id(character_id: StringName) -> void:
	var character_asset: CharacterEntityAsset = get_character_asset(character_id)

	_equipped_character_id = character_id
	equipped_character_changed.emit(character_asset)
