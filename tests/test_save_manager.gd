# TODO Improve fail safety, add check slot path and slots
## Verifies SaveManager slot path resolution, existence checks, and deletion
extends Node

var _slot_backups: Dictionary = { } # Dictionary[int, Dictionary] — {"base": PackedByteArray or null, "bak": PackedByteArray or null}


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_backup_slot(0)
	_backup_slot(1)

	_test_has_save_and_get_slot_data()
	_test_delete_slot_removes_all_variants()

	_restore_slot(0)
	_restore_slot(1)

	print("SaveManager test completed.")
	self.queue_free()


func _backup_slot(slot_index: int) -> void:
	var base: String = SaveManager._slot_path(slot_index)
	_slot_backups[slot_index] = {
		"base": FileAccess.get_file_as_bytes(base) if FileAccess.file_exists(base) else null,
		"bak": FileAccess.get_file_as_bytes(base + ".bak") if FileAccess.file_exists(base + ".bak") else null,
	}


func _restore_slot(slot_index: int) -> void:
	var base: String = SaveManager._slot_path(slot_index)
	var backup: Dictionary = _slot_backups[slot_index]

	for suffix: String in ["", ".bak"]:
		var path: String = base + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	if backup["base"] != null:
		var f: FileAccess = FileAccess.open(base, FileAccess.WRITE)
		f.store_buffer(backup["base"])
	if backup["bak"] != null:
		var f: FileAccess = FileAccess.open(base + ".bak", FileAccess.WRITE)
		f.store_buffer(backup["bak"])

	SaveManager.save_changed.emit(slot_index)


func _test_has_save_and_get_slot_data() -> void:
	var slot_index: int = 0
	var path: String = SaveManager._slot_path(slot_index)

	var data: SaveData = SaveData.new()
	data.slot_index = slot_index
	data.save_timestamp = 12345
	var err: int = ResourceSaver.save(data, path)
	assert(err == OK, "SaveManager: failed writing test fixture to %s" % path)

	assert(SaveManager.has_save(slot_index), "SaveManager: has_save() false after writing slot %d" % slot_index)

	var loaded: SaveData = SaveManager.get_slot_data(slot_index)
	assert(loaded != null, "SaveManager: get_slot_data() returned null for slot %d" % slot_index)
	assert(loaded.save_timestamp == 12345, "SaveManager: loaded save_timestamp mismatch")


func _test_delete_slot_removes_all_variants() -> void:
	var slot_index: int = 1
	var base: String = SaveManager._slot_path(slot_index)

	var data: SaveData = SaveData.new()
	var err: int = ResourceSaver.save(data, base)
	assert(err == OK, "SaveManager: failed writing test fixture to %s" % base)
	assert(DirAccess.copy_absolute(base, base + ".bak") == OK, "SaveManager: failed creating .bak fixture at %s" % (base + ".bak"))

	SaveManager.delete_slot(slot_index)

	assert(not FileAccess.file_exists(base), "SaveManager: delete_slot() left .tres behind")
	assert(not FileAccess.file_exists(base + ".bak"), "SaveManager: delete_slot() left .bak behind")
	assert(not SaveManager.has_save(slot_index), "SaveManager: has_save() true after delete_slot()")
