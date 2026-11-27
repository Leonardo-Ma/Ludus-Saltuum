@icon("uid://eajxvr72e3t1") # shirt.png
class_name CosmeticsController
extends Node

## Ownership and equipped cosmetic per slot, slot defaults are owned and equipped implicitly

signal owned_changed
signal equipped_changed(asset: CosmeticAsset)
signal affordable_cosmetic_reminded

const NO_PRICE: int = -1
const MIN_REMINDER_PRICE: int = 1
const REMINDER_COOLDOWN: float = 120.0

@export var catalog: CosmeticCatalog

## Excludes slot defaults
var _acquired_ids: Array[StringName] = []
## Key is CosmeticAsset.Slot, missing key means slot default
var _equipped_ids: Dictionary[int, StringName] = { }

var _reminder_pending: bool = false
var _cooldown_timer: SceneTreeTimer = null

@onready var _economy_controller: EconomyController = %EconomyController


func _ready() -> void:
	assert(catalog != null, "Cosmetic catalog missing in " + name)
	catalog.validate()

	_economy_controller.gold_changed.connect(_on_gold_changed)
	owned_changed.connect(_evaluate_affordability)
	ApplicationStateManager.gameplay_started.connect(_evaluate_affordability)
	ApplicationStateManager.gameplay_resumed.connect(_evaluate_affordability)


#region Ownership and equipment
func acquire(cosmetic_id: StringName) -> void:
	assert(catalog.find_asset(cosmetic_id) != null, "Unknown cosmetic id in " + name + ": " + String(cosmetic_id))

	if owns(cosmetic_id):
		return

	_acquired_ids.append(cosmetic_id)
	owned_changed.emit()


func owns(cosmetic_id: StringName) -> bool:
	var asset: CosmeticAsset = catalog.find_asset(cosmetic_id)
	return asset != null and (asset.is_default or cosmetic_id in _acquired_ids)


func get_acquired_ids() -> Array[StringName]:
	return _acquired_ids.duplicate()


## Unknown ids are skipped, equipped cosmetics no longer owned fall back to slot default
func set_acquired_ids(cosmetic_ids: Array[StringName]) -> void:
	_acquired_ids = []
	for cosmetic_id: StringName in cosmetic_ids:
		if catalog.find_asset(cosmetic_id) == null:
			push_warning("Save references unknown cosmetic '%s', skipped" % [cosmetic_id])
			continue
		if not _acquired_ids.has(cosmetic_id):
			_acquired_ids.append(cosmetic_id)

	set_equipped_ids(get_equipped_ids())
	owned_changed.emit()


func reset() -> void:
	_acquired_ids = []
	set_equipped_ids({ })
	owned_changed.emit()


func equip(cosmetic_id: StringName) -> bool:
	if not owns(cosmetic_id):
		return false

	_set_equipped(catalog.get_asset(cosmetic_id))
	return true


func get_equipped_id(slot: CosmeticAsset.Slot) -> StringName:
	return _equipped_ids.get(slot, catalog.get_default(slot).cosmetic_id)


## Validates affordability and equips owned or newly acquired cosmetic
func buy_or_equip(cosmetic_id: StringName) -> bool:
	var asset: CosmeticAsset = catalog.get_asset(cosmetic_id)
	if not owns(cosmetic_id):
		if not _economy_controller.remove_gold(asset.price):
			return false
		acquire(cosmetic_id)
	return equip(cosmetic_id)


func get_equipped_asset(slot: CosmeticAsset.Slot) -> CosmeticAsset:
	return catalog.get_asset(get_equipped_id(slot))


## Every slot in use, for saving
func get_equipped_ids() -> Dictionary[int, StringName]:
	var ids: Dictionary[int, StringName] = { }
	for slot: CosmeticAsset.Slot in CosmeticAsset.Slot.values():
		if not catalog.get_assets(slot).is_empty():
			ids[slot] = get_equipped_id(slot)
	return ids


## Missing, unowned or wrong slot ids fall back to slot default
func set_equipped_ids(ids: Dictionary[int, StringName]) -> void:
	for slot: CosmeticAsset.Slot in CosmeticAsset.Slot.values():
		if catalog.get_assets(slot).is_empty():
			continue

		var saved_id: StringName = ids.get(slot, &"")
		var asset: CosmeticAsset = catalog.find_asset(saved_id)
		if asset == null or asset.get_slot() != slot or not owns(saved_id):
			asset = catalog.get_default(slot)
		_set_equipped(asset)


func _set_equipped(asset: CosmeticAsset) -> void:
	var slot: CosmeticAsset.Slot = asset.get_slot()
	if get_equipped_id(slot) == asset.cosmetic_id:
		return

	_equipped_ids[slot] = asset.cosmetic_id
	equipped_changed.emit(asset)
#endregion


#region Affordable visual highlight warning
## NO_PRICE when no unowned cosmetic costs at least MIN_REMINDER_PRICE
func get_cheapest_unowned_price() -> int:
	var cheapest_price: int = NO_PRICE
	for asset: CosmeticAsset in catalog.get_all_assets():
		if owns(asset.cosmetic_id) or asset.price < MIN_REMINDER_PRICE:
			continue
		if cheapest_price == NO_PRICE or asset.price < cheapest_price:
			cheapest_price = asset.price
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
