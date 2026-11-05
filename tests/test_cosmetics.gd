extends Node

## Verifies CosmeticsController ownership/equip rules and owned cosmetic ids surviving slot save round trip

const CHARACTER_CATALOG: CharacterEntityCatalog = preload("uid://b2bfyxo1s4qql") # character_catalog.tres
const ALT_CHARACTER: CharacterEntityAsset = preload("uid://cq06jgmjen48") # mage.tres
const LEGACY_SAVE_PATH: String = "res://tests/saves/slot_0.tres"
const TEST_SLOT: int = 2

var _slot_backup: Dictionary = { }
var _owned_changed_count: int = 0
var _equipped_changed_count: int = 0


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	assert(CHARACTER_CATALOG.get_character_asset(ALT_CHARACTER.character_id) != null, "Cosmetics test: mage missing from character catalog")

	_backup_slot()

	_test_default_state()
	_test_acquire_and_signal()
	_test_owned_ids_returns_copy()
	_test_equip_rules()
	_test_set_owned_ids_keeps_default_and_resets_equipped()
	_test_reset()
	_test_owned_ids_survive_save_slot()
	_test_legacy_save_without_cosmetics()

	_restore_slot()

	print("✅ Cosmetics test completed.")
	queue_free()


func _make_controller() -> CosmeticsController:
	var controller: CosmeticsController = CosmeticsController.new()
	controller.character_catalog = CHARACTER_CATALOG
	_owned_changed_count = 0
	_equipped_changed_count = 0
	controller.owned_changed.connect(_on_owned_changed)
	controller.equipped_character_changed.connect(_on_equipped_changed)
	return controller


func _on_owned_changed() -> void:
	_owned_changed_count += 1


func _on_equipped_changed(_character_asset: CharacterEntityAsset) -> void:
	_equipped_changed_count += 1


func _test_default_state() -> void:
	var controller: CosmeticsController = _make_controller()

	assert(controller.owns(CosmeticsController.DEFAULT_CHARACTER_ID), "CosmeticsController: default character not owned")
	assert(controller.get_owned_ids() == [CosmeticsController.DEFAULT_CHARACTER_ID], "CosmeticsController: owned ids should only hold default")
	assert(controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID, "CosmeticsController: default not equipped")
	assert(not controller.owns(ALT_CHARACTER.character_id), "CosmeticsController: alt character owned by default")

	controller.free()


func _test_acquire_and_signal() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(ALT_CHARACTER.character_id)
	assert(controller.owns(ALT_CHARACTER.character_id), "CosmeticsController: acquire did not add id")
	assert(_owned_changed_count == 1, "CosmeticsController: acquire should emit owned_changed once")

	controller.acquire(ALT_CHARACTER.character_id)
	assert(_owned_changed_count == 1, "CosmeticsController: duplicate acquire emitted owned_changed")
	assert(controller.get_owned_ids().count(ALT_CHARACTER.character_id) == 1, "CosmeticsController: duplicate id stored")

	controller.free()


func _test_owned_ids_returns_copy() -> void:
	var controller: CosmeticsController = _make_controller()

	var ids: Array[StringName] = controller.get_owned_ids()
	ids.append(ALT_CHARACTER.character_id)
	assert(not controller.owns(ALT_CHARACTER.character_id), "CosmeticsController: get_owned_ids exposes internal array")

	controller.free()


func _test_equip_rules() -> void:
	var controller: CosmeticsController = _make_controller()

	assert(not controller.equip(ALT_CHARACTER.character_id), "CosmeticsController: equipped unowned character")
	assert(
		controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID,
		"CosmeticsController: equip of unowned changed equipped",
	)
	assert(_equipped_changed_count == 0, "CosmeticsController: failed equip emitted signal")

	controller.acquire(ALT_CHARACTER.character_id)
	assert(controller.equip(ALT_CHARACTER.character_id), "CosmeticsController: equip of owned failed")
	assert(controller.get_equipped_character_id() == ALT_CHARACTER.character_id, "CosmeticsController: equipped id not updated")
	assert(_equipped_changed_count == 1, "CosmeticsController: equip should emit equipped_character_changed once")

	assert(controller.equip(ALT_CHARACTER.character_id), "CosmeticsController: re-equip should return true")
	assert(_equipped_changed_count == 1, "CosmeticsController: re-equip emitted signal")

	controller.set_equipped_character_id(&"character.unowned_test")
	assert(
		controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID,
		"CosmeticsController: unowned set_equipped did not fall back to default",
	)

	controller.free()


func _test_set_owned_ids_keeps_default_and_resets_equipped() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(ALT_CHARACTER.character_id)
	controller.equip(ALT_CHARACTER.character_id)

	var ids: Array[StringName] = []
	controller.set_owned_ids(ids)
	assert(controller.owns(CosmeticsController.DEFAULT_CHARACTER_ID), "CosmeticsController: set_owned_ids dropped default")
	assert(not controller.owns(ALT_CHARACTER.character_id), "CosmeticsController: set_owned_ids kept removed id")
	assert(
		controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID,
		"CosmeticsController: equipped not reset after ownership loss",
	)

	controller.free()


func _test_reset() -> void:
	var controller: CosmeticsController = _make_controller()

	controller.acquire(ALT_CHARACTER.character_id)
	controller.equip(ALT_CHARACTER.character_id)
	controller.reset()

	assert(controller.get_owned_ids() == [CosmeticsController.DEFAULT_CHARACTER_ID], "CosmeticsController: reset kept owned ids")
	assert(controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID, "CosmeticsController: reset kept equipped")

	controller.free()


func _test_owned_ids_survive_save_slot() -> void:
	var controller: CosmeticsController = _make_controller()
	controller.acquire(ALT_CHARACTER.character_id)
	controller.equip(ALT_CHARACTER.character_id)

	var data: SaveData = SaveData.new()
	data.slot_index = TEST_SLOT
	data.player.owned_cosmetic_ids = controller.get_owned_ids()
	data.player.equipped_character_id = controller.get_equipped_character_id()

	var err: int = ResourceSaver.save(data, SaveManager._slot_path(TEST_SLOT))
	assert(err == OK, "Cosmetics test: failed writing slot fixture")

	var loaded: SaveData = SaveManager.get_slot_data(TEST_SLOT)
	assert(loaded != null, "Cosmetics test: slot fixture not loadable")
	assert(loaded.player.owned_cosmetic_ids == data.player.owned_cosmetic_ids, "Save regression: owned_cosmetic_ids changed after round trip")
	assert(
		loaded.player.equipped_character_id == data.player.equipped_character_id,
		"Save regression: equipped_character_id changed after round trip",
	)

	var restored: CosmeticsController = _make_controller()
	restored.set_owned_ids(loaded.player.owned_cosmetic_ids)
	restored.set_equipped_character_id(loaded.player.equipped_character_id)
	assert(restored.owns(ALT_CHARACTER.character_id), "Save regression: owned cosmetic lost after apply")
	assert(restored.get_equipped_character_id() == ALT_CHARACTER.character_id, "Save regression: equipped cosmetic lost after apply")

	controller.free()
	restored.free()


func _test_legacy_save_without_cosmetics() -> void:
	var legacy: SaveData = load(LEGACY_SAVE_PATH) as SaveData
	assert(legacy != null, "Cosmetics test: legacy save failed to load")

	var controller: CosmeticsController = _make_controller()
	controller.set_owned_ids(legacy.player.owned_cosmetic_ids)
	controller.set_equipped_character_id(legacy.player.equipped_character_id)

	assert(controller.owns(CosmeticsController.DEFAULT_CHARACTER_ID), "Save regression: legacy save lost default character")
	assert(controller.get_equipped_character_id() == CosmeticsController.DEFAULT_CHARACTER_ID, "Save regression: legacy save equipped not default")

	controller.free()


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
