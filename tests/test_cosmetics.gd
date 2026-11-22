extends Node

## Verifies CosmeticsController slots, ownership, equip rules, defaults and acquired/equipped ids surviving slot save round trip

const COSMETIC_CATALOGS: CosmeticCatalog = preload("uid://fcuvxgh84u61")
const LEGACY_SAVE_PATH: String = "res://tests/saves/slot_0.tres"
const TEST_SLOT: int = 2

const KNIGHT: StringName = &"character.knight"
const MAGE: StringName = &"character.mage"
const IRON_SWORD: StringName = &"weapon.iron_sword"
const STEEL_SWORD: StringName = &"weapon.steel_sword"

var _slot_backup: Dictionary = { }
var _owned_changed_count: int = 0
var _equipped_changed_count: int = 0


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	COSMETIC_CATALOGS.validate()

	_backup_slot()

	_test_default_state()
	_test_acquire_and_signal()
	_test_acquired_ids_returns_copy()
	_test_equip_rules()
	_test_set_equipped_ids_falls_back()
	_test_set_acquired_ids_skips_unknown_and_resets_equipped()
	_test_reset()
	_test_ids_survive_save_slot()
	_test_legacy_save_without_cosmetics()
	_test_cheapest_unowned_price()
	_test_assets_sorted_by_price()

	_restore_slot()

	print("✅ Cosmetics test completed.")
	queue_free()


func _make_character(id: StringName, price: int, is_default: bool) -> CharacterEntityAsset:
	var asset: CharacterEntityAsset = CharacterEntityAsset.new()
	asset.cosmetic_id = id
	asset.price = price
	asset.is_default = is_default
	return asset


func _make_weapon(id: StringName, price: int, is_default: bool) -> WeaponAsset:
	var asset: WeaponAsset = WeaponAsset.new()
	asset.cosmetic_id = id
	asset.price = price
	asset.is_default = is_default
	return asset


func _make_catalog() -> CosmeticCatalog:
	var characters: CosmeticSlotCatalog = CosmeticSlotCatalog.new()
	characters.slot = CosmeticAsset.Slot.CHARACTER
	characters.assets = [_make_character(KNIGHT, 0, true), _make_character(MAGE, 250, false)]

	var weapons: CosmeticSlotCatalog = CosmeticSlotCatalog.new()
	weapons.slot = CosmeticAsset.Slot.WEAPON
	weapons.assets = [_make_weapon(IRON_SWORD, 0, true), _make_weapon(STEEL_SWORD, 100, false)]

	var catalog: CosmeticCatalog = CosmeticCatalog.new()
	catalog.slots = [characters, weapons]
	catalog.validate()
	return catalog


func _make_controller() -> CosmeticsController:
	var controller: CosmeticsController = CosmeticsController.new()
	controller.catalog = _make_catalog()
	_owned_changed_count = 0
	_equipped_changed_count = 0
	controller.owned_changed.connect(_on_owned_changed)
	controller.equipped_changed.connect(_on_equipped_changed)
	return controller


func _on_owned_changed() -> void:
	_owned_changed_count += 1


func _on_equipped_changed(_asset: CosmeticAsset) -> void:
	_equipped_changed_count += 1


func _test_default_state() -> void:
	var controller: CosmeticsController = _make_controller()

	assert(controller.owns(KNIGHT) and controller.owns(IRON_SWORD), "CosmeticsController: slot defaults not owned")
	assert(controller.get_acquired_ids().is_empty(), "CosmeticsController: defaults must not count as acquired")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == KNIGHT, "CosmeticsController: default character not equipped")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: default weapon not equipped")
	assert(not controller.owns(MAGE) and not controller.owns(STEEL_SWORD), "CosmeticsController: paid cosmetic owned by default")

	controller.free()


func _test_acquire_and_signal() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(STEEL_SWORD)
	assert(controller.owns(STEEL_SWORD), "CosmeticsController: acquire did not add id")
	assert(_owned_changed_count == 1, "CosmeticsController: acquire should emit owned_changed once")

	controller.acquire(STEEL_SWORD)
	controller.acquire(KNIGHT)
	assert(_owned_changed_count == 1, "CosmeticsController: duplicate or default acquire emitted owned_changed")
	assert(controller.get_acquired_ids() == [STEEL_SWORD], "CosmeticsController: duplicate or default id stored")

	controller.free()


func _test_acquired_ids_returns_copy() -> void:
	var controller: CosmeticsController = _make_controller()

	var ids: Array[StringName] = controller.get_acquired_ids()
	ids.append(STEEL_SWORD)
	assert(not controller.owns(STEEL_SWORD), "CosmeticsController: get_acquired_ids exposes internal array")

	controller.free()


func _test_equip_rules() -> void:
	var controller: CosmeticsController = _make_controller()

	assert(not controller.equip(STEEL_SWORD), "CosmeticsController: equipped unowned weapon")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: failed equip changed equipped")
	assert(_equipped_changed_count == 0, "CosmeticsController: failed equip emitted signal")

	controller.acquire(STEEL_SWORD)
	assert(controller.equip(STEEL_SWORD), "CosmeticsController: equip of owned failed")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == STEEL_SWORD, "CosmeticsController: equipped weapon not updated")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == KNIGHT, "CosmeticsController: weapon equip changed character slot")
	assert(_equipped_changed_count == 1, "CosmeticsController: equip should emit equipped_changed once")

	assert(controller.equip(STEEL_SWORD), "CosmeticsController: re-equip should return true")
	assert(_equipped_changed_count == 1, "CosmeticsController: re-equip emitted signal")

	controller.free()


func _test_set_equipped_ids_falls_back() -> void:
	var controller: CosmeticsController = _make_controller()

	var ids: Dictionary[int, StringName] = { CosmeticAsset.Slot.CHARACTER: STEEL_SWORD, CosmeticAsset.Slot.WEAPON: &"weapon.unknown_test" }
	controller.set_equipped_ids(ids)

	assert(controller.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == KNIGHT, "CosmeticsController: wrong slot id not rejected")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: unknown id not rejected")

	ids = { CosmeticAsset.Slot.WEAPON: STEEL_SWORD }
	controller.set_equipped_ids(ids)
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: unowned id not rejected")

	controller.free()


func _test_set_acquired_ids_skips_unknown_and_resets_equipped() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(STEEL_SWORD)
	controller.equip(STEEL_SWORD)

	var ids: Array[StringName] = []
	controller.set_acquired_ids(ids)
	assert(not controller.owns(STEEL_SWORD), "CosmeticsController: set_acquired_ids kept removed id")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: equipped not reset after ownership loss")

	ids = [&"weapon.unknown_test", MAGE]
	controller.set_acquired_ids(ids)
	assert(controller.get_acquired_ids() == [MAGE], "CosmeticsController: unknown id not skipped")

	controller.free()


func _test_reset() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(STEEL_SWORD)
	controller.acquire(MAGE)
	controller.equip(STEEL_SWORD)
	controller.equip(MAGE)
	controller.reset()

	assert(controller.get_acquired_ids().is_empty(), "CosmeticsController: reset kept acquired ids")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "CosmeticsController: reset kept equipped weapon")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == KNIGHT, "CosmeticsController: reset kept equipped character")

	controller.free()


func _test_ids_survive_save_slot() -> void:
	var controller: CosmeticsController = _make_controller()
	controller.acquire(STEEL_SWORD)
	controller.acquire(MAGE)
	controller.equip(STEEL_SWORD)
	controller.equip(MAGE)

	var data: SaveData = SaveData.new()
	data.slot_index = TEST_SLOT
	data.player.acquired_cosmetic_ids = controller.get_acquired_ids()
	data.player.equipped_ids = controller.get_equipped_ids()

	var err: int = ResourceSaver.save(data, SaveManager._slot_path(TEST_SLOT))
	assert(err == OK, "Cosmetics test: failed writing slot fixture")

	var loaded: SaveData = SaveManager.get_slot_data(TEST_SLOT)
	assert(loaded != null, "Cosmetics test: slot fixture not loadable")
	assert(
		loaded.player.acquired_cosmetic_ids == data.player.acquired_cosmetic_ids,
		"Save regression: acquired_cosmetic_ids changed after round trip",
	)
	assert(loaded.player.equipped_ids == data.player.equipped_ids, "Save regression: equipped_ids changed after round trip")

	var restored: CosmeticsController = _make_controller()
	restored.set_acquired_ids(loaded.player.acquired_cosmetic_ids)
	restored.set_equipped_ids(loaded.player.equipped_ids)
	assert(restored.get_equipped_id(CosmeticAsset.Slot.WEAPON) == STEEL_SWORD, "Save regression: equipped weapon lost after apply")
	assert(restored.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == MAGE, "Save regression: equipped character lost after apply")

	controller.free()
	restored.free()


func _test_legacy_save_without_cosmetics() -> void:
	var legacy: SaveData = load(LEGACY_SAVE_PATH) as SaveData
	assert(legacy != null, "Cosmetics test: legacy save failed to load")

	var controller: CosmeticsController = _make_controller()
	controller.set_acquired_ids(legacy.player.acquired_cosmetic_ids)
	controller.set_equipped_ids(legacy.player.equipped_ids)

	assert(controller.get_equipped_id(CosmeticAsset.Slot.CHARACTER) == KNIGHT, "Save regression: legacy save equipped character not default")
	assert(controller.get_equipped_id(CosmeticAsset.Slot.WEAPON) == IRON_SWORD, "Save regression: legacy save equipped weapon not default")

	controller.free()


func _test_cheapest_unowned_price() -> void:
	var controller: CosmeticsController = _make_controller()

	assert(controller.get_cheapest_unowned_price() == 100, "CosmeticsController: cheapest price should be steel sword 100")

	controller.acquire(STEEL_SWORD)
	assert(controller.get_cheapest_unowned_price() == 250, "CosmeticsController: cheapest price should be mage 250")

	controller.acquire(MAGE)
	assert(controller.get_cheapest_unowned_price() == CosmeticsController.NO_PRICE, "CosmeticsController: free or owned cosmetics counted")

	controller.free()


func _test_assets_sorted_by_price() -> void:
	var slot_catalog: CosmeticSlotCatalog = _make_catalog().slots[1]
	var prices: Array[int] = []
	for asset: CosmeticAsset in slot_catalog.get_assets_by_price():
		prices.append(asset.price)
	assert(prices == [0, 100], "CosmeticSlotCatalog: expected assets sorted by price, got %s" % str(prices))


func _backup_slot() -> void:
	var base: String = SaveManager._slot_path(TEST_SLOT)
	_slot_backup = {
		"base": FileAccess.get_file_as_bytes(base) if FileAccess.file_exists(base) else null,
		"bak": FileAccess.get_file_as_bytes(base + ".bak") if FileAccess.file_exists(base + ".bak") else null,
	}


func _restore_slot() -> void:
	var base: String = SaveManager._slot_path(TEST_SLOT)

	for suffix: String in ["", ".bak"]:
		var path: String = base + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	if _slot_backup["base"] != null:
		var f: FileAccess = FileAccess.open(base, FileAccess.WRITE)
		assert(f != null, "Failed to restore base save in " + self.name + ": " + base)
		f.store_buffer(_slot_backup["base"])
	if _slot_backup["bak"] != null:
		var f: FileAccess = FileAccess.open(base + ".bak", FileAccess.WRITE)
		assert(f != null, "Failed to restore backup save in " + self.name + ": " + base + ".bak")
		f.store_buffer(_slot_backup["bak"])

	SaveManager.save_changed.emit(TEST_SLOT)
