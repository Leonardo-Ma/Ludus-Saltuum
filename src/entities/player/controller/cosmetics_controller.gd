@icon("uid://eajxvr72e3t1") # shirt.png
class_name CosmeticsController
extends Node

signal owned_changed
signal equipped_character_changed(character_asset: CharacterEntityAsset)
signal affordable_cosmetic_reminded

const DEFAULT_CHARACTER_ID: StringName = &"character.knight"

const NO_PRICE: int = -1
const MIN_REMINDER_PRICE: int = 1
const REMINDER_COOLDOWN: float = 120.0

@export var character_catalog: CharacterEntityCatalog

@onready var _economy_controller: EconomyController = %EconomyController

var _character_ids: Array[StringName] = [DEFAULT_CHARACTER_ID]
var _equipped_character_id: StringName = DEFAULT_CHARACTER_ID

var _reminder_pending: bool = false
var _cooldown_timer: SceneTreeTimer = null


func _ready() -> void:
	assert(character_catalog != null, "Character catalog missing in " + name)
	assert(get_character_asset(DEFAULT_CHARACTER_ID) != null, "Default character missing in " + name)

	_economy_controller.gold_changed.connect(_on_gold_changed)
	owned_changed.connect(_evaluate_affordability)
	ApplicationStateManager.gameplay_started.connect(_evaluate_affordability)
	ApplicationStateManager.gameplay_resumed.connect(_evaluate_affordability)


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


#region Character affordable visual highlight warning
## NO_PRICE when no unowned cosmetic costs at least MIN_REMINDER_PRICE
func get_cheapest_unowned_price() -> int:
	assert(character_catalog != null, "Character catalog missing in " + name)
	var cheapest_price: int = NO_PRICE
	for character_asset: CharacterEntityAsset in character_catalog.characters:
		if owns(character_asset.character_id) or character_asset.character_price < MIN_REMINDER_PRICE:
			continue
		if cheapest_price == NO_PRICE or character_asset.character_price < cheapest_price:
			cheapest_price = character_asset.character_price
	return cheapest_price


## True once per reminder, used by pause menu to decide on highlight
func consume_reminder() -> bool:
	var was_pending: bool = _reminder_pending
	_reminder_pending = false
	return was_pending


func _on_gold_changed(_new_gold: int) -> void:
	_evaluate_affordability()


func _evaluate_affordability() -> void:
	var cheapest_price: int = get_cheapest_unowned_price()
	var can_afford: bool = cheapest_price != NO_PRICE and _economy_controller.gold >= cheapest_price

	if not can_afford:
		_reminder_pending = false
		return

	if not ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING):
		return

	if _cooldown_timer != null and _cooldown_timer.time_left > 0.0:
		return

	_reminder_pending = true
	_cooldown_timer = get_tree().create_timer(REMINDER_COOLDOWN)
	_cooldown_timer.timeout.connect(_evaluate_affordability)
	affordable_cosmetic_reminded.emit()
#endregion
