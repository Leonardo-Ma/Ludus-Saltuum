## Verifies SaveManager slot path resolution, existence checks, and deletion
extends Node


func _ready() -> void:
	_test_has_save_and_get_slot_data()
	_test_delete_slot_removes_all_variants()
	print("SaveManager test completed.")
	self.queue_free()


func _test_has_save_and_get_slot_data() -> void:
	var slot_index: int = 0
	var path: String = SaveManager.SAVE_DIR + "slot_%d.tres" % slot_index

	var data: SaveData = SaveData.new()
	data.slot_index = slot_index
	data.save_timestamp = 12345
	var err: int = ResourceSaver.save(data, path)
	assert(err == OK, "SaveManager: failed writing test fixture to %s" % path)

	assert(SaveManager.has_save(slot_index), "SaveManager: has_save() false after writing slot %d" % slot_index)

	var loaded: SaveData = SaveManager.get_slot_data(slot_index)
	assert(loaded != null, "SaveManager: get_slot_data() returned null for slot %d" % slot_index)
	assert(loaded.save_timestamp == 12345, "SaveManager: loaded save_timestamp mismatch")

	SaveManager.delete_slot(slot_index)
	assert(not SaveManager.has_save(slot_index), "SaveManager: has_save() true after delete_slot() cleanup")


func _test_delete_slot_removes_all_variants() -> void:
	var slot_index: int = 1
	var base: String = SaveManager.SAVE_DIR + "slot_%d.tres" % slot_index

	var data: SaveData = SaveData.new()
	var err: int = ResourceSaver.save(data, base)
	assert(err == OK, "SaveManager: failed writing test fixture to %s" % base)
	assert(DirAccess.copy_absolute(base, base + ".bak") == OK, "SaveManager: failed creating .bak fixture at %s" % (base + ".bak"))

	assert(FileAccess.file_exists(base), "SaveManager: fixture .tres missing before delete test")
	assert(FileAccess.file_exists(base + ".bak"), "SaveManager: fixture .bak missing before delete test")

	SaveManager.delete_slot(slot_index)

	assert(not FileAccess.file_exists(base), "SaveManager: delete_slot() left .tres behind")
	assert(not FileAccess.file_exists(base + ".bak"), "SaveManager: delete_slot() left .bak behind")
	assert(not SaveManager.has_save(slot_index), "SaveManager: has_save() true after delete_slot()")
