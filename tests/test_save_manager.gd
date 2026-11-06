# TODO Improve fail safety, add check slot path and slots
## Verifies SaveManager slot path resolution, existence checks, and deletion
extends Node


class FakeCloudBackend:
	extends CloudSaveBackend

	var renamed: Dictionary[String, String] = { }


	func is_available() -> bool:
		return true


	func upload(_cloud_filename: String, _local_path: String) -> bool:
		return false


	func download(_cloud_filename: String, _local_path: String) -> bool:
		return false


	func delete(_cloud_filename: String) -> bool:
		return false


	func remote_is_newer(_cloud_filename: String, _local_path: String) -> bool:
		return false


	func rename(cloud_filename: String, new_cloud_filename: String) -> bool:
		renamed[cloud_filename] = new_cloud_filename
		return true


var _slot_backups: Dictionary = { } # Dictionary[int, Dictionary] — {"base": PackedByteArray or null, "bak": PackedByteArray or null}


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	_backup_slot(0)
	_backup_slot(1)

	_test_has_save_and_get_slot_data()
	_test_delete_slot_removes_all_variants()
	_test_corrupt_slot_quarantines_local_and_cloud()

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
		assert(f != null, "Failed to restore base save in " + self.name + ": " + base)
		f.store_buffer(backup["base"])
	if backup["bak"] != null:
		var f: FileAccess = FileAccess.open(base + ".bak", FileAccess.WRITE)
		assert(f != null, "Failed to restore backup save in " + self.name + ": " + base + ".bak")
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


func _test_corrupt_slot_quarantines_local_and_cloud() -> void:
	# TODO Find way to ignore errors without ignoring save manager
	push_error("Starting save corruption handle test. Ignore errors below: ")

	var slot_index: int = 1
	var base: String = SaveManager._slot_path(slot_index)
	var cloud_name: String = SaveManager._cloud_filename(slot_index)
	var quarantined_before: PackedStringArray = _list_quarantined(slot_index)

	for path: String in [base, base + ".bak"]:
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		assert(file != null, "SaveManager: failed writing corrupt fixture to %s" % path)
		file.store_string("corrupt")
		file.close()

	var original_backend: CloudSaveBackend = SaveManager._cloud_backend
	var fake_backend: FakeCloudBackend = FakeCloudBackend.new()
	SaveManager.configure_cloud_backend(fake_backend)

	var loaded: SaveData = SaveManager.get_slot_data(slot_index)

	SaveManager.configure_cloud_backend(original_backend)

	assert(loaded == null, "SaveManager: corrupt slot returned data")
	assert(not FileAccess.file_exists(base), "SaveManager: quarantine left .tres behind")
	assert(not FileAccess.file_exists(base + ".bak"), "SaveManager: quarantine left .bak behind")
	assert(not SaveManager.has_save(slot_index), "SaveManager: has_save() true after quarantine")

	var new_files: PackedStringArray = []
	for file_name: String in _list_quarantined(slot_index):
		if not quarantined_before.has(file_name):
			new_files.append(file_name)
	assert(new_files.size() == 2, "SaveManager: expected 2 quarantined files, got %d" % new_files.size())

	assert(fake_backend.renamed.has(cloud_name), "SaveManager: quarantine did not rename cloud save")
	var cloud_suffix: String = fake_backend.renamed[cloud_name].trim_prefix(cloud_name)
	assert(cloud_suffix.begins_with(SaveManager.CORRUPT_SUFFIX), "SaveManager: cloud quarantine name missing corrupt suffix")
	assert(new_files.has(base.get_file() + cloud_suffix), "SaveManager: local and cloud quarantine names differ")

	for file_name: String in new_files:
		DirAccess.remove_absolute(SaveManager.SAVE_DIR + file_name)

	push_error("Corruption handle test finished successfully")


func _list_quarantined(slot_index: int) -> PackedStringArray:
	var prefix: String = SaveManager._slot_path(slot_index).get_file()
	var found: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(SaveManager.SAVE_DIR):
		if file_name.begins_with(prefix) and SaveManager.CORRUPT_SUFFIX in file_name:
			found.append(file_name)
	return found
