# TODO Improve fail safety, add check slot path and slots
extends ProjectTest

## Verifies disk recovery and Steam sync against isolated fixtures


class FakeCloudBackend:
	extends CloudSaveBackend

	var deleted: Array[String] = []
	var remote_saves: Dictionary[String, PackedByteArray] = { }
	var download_succeeds: bool = true
	var delete_succeeds: bool = true


	func is_available() -> bool:
		return true


	func upload(_cloud_filename: String, _local_path: String) -> bool:
		return false


	func download(cloud_filename: String, local_path: String) -> bool:
		var bytes: PackedByteArray = remote_saves.get(cloud_filename, PackedByteArray())
		if bytes.is_empty():
			return false
		var file: FileAccess = FileAccess.open(local_path, FileAccess.WRITE)
		return file != null and file.store_buffer(bytes) and download_succeeds


	func delete(cloud_filename: String) -> bool:
		if not delete_succeeds:
			return false
		deleted.append(cloud_filename)
		remote_saves.erase(cloud_filename)
		return true


	func has_remote_save(cloud_filename: String) -> bool:
		return remote_saves.has(cloud_filename)


var _slot_backups: Dictionary[String, PackedByteArray] = { }
var _cloud_failures: Array[SaveManager.CloudOperation] = []


func run_tests() -> void:
	var original_backend: CloudSaveBackend = SaveManager._cloud_backend
	var fake_backend: FakeCloudBackend = FakeCloudBackend.new()
	SaveManager.configure_cloud_backend(fake_backend)

	SaveManager.cloud_sync_failed.connect(_on_cloud_sync_failed)
	_backup_slot(0)
	_backup_slot(1)

	_test_has_save_and_get_slot_data()
	_test_reads_uncached()
	_test_recover_legacy_and_interrupted_saves()
	_test_corrupt_slot_inspection_is_read_only()
	_test_cloud_sync(fake_backend)
	_test_local_commit_keeps_previous_save()
	_test_rename_round_trip(fake_backend)
	_test_delete_slot_removes_all_variants(fake_backend)

	_restore_slot(0)
	_restore_slot(1)
	SaveManager.cloud_sync_failed.disconnect(_on_cloud_sync_failed)
	SaveManager.configure_cloud_backend(original_backend)

	print("SaveManager test completed.")


func _backup_slot(slot_index: int) -> void:
	for path: String in _slot_paths(slot_index):
		if FileAccess.file_exists(path):
			_slot_backups[path] = FileAccess.get_file_as_bytes(path)
			assert(DirAccess.remove_absolute(path) == OK, "Cannot clear isolated fixture in " + name)


func _restore_slot(slot_index: int) -> void:
	for path: String in _slot_paths(slot_index):
		if FileAccess.file_exists(path):
			assert(DirAccess.remove_absolute(path) == OK, "Cannot clear isolated fixture in " + name)
		if _slot_backups.has(path):
			_write_bytes(path, _slot_backups[path])
	SaveManager.save_changed.emit(slot_index)


func _slot_paths(slot_index: int) -> Array[String]:
	var base: String = SaveManager._slot_path(slot_index)
	return [
		base,
		base + ".bak",
		base + ".bak.old",
		base + ".tmp",
		SaveManager._backup_path(slot_index),
		SaveManager._tmp_path(slot_index),
		SaveManager._incoming_path(slot_index),
	]


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


func _test_reads_uncached() -> void:
	var path: String = SaveManager._slot_path(0)
	var cached: Resource = ResourceLoader.load(path)
	_write_snapshot(path, 0, 20000)
	assert(cached.get("save_timestamp") == 12345, "Cache fixture changed in " + name)
	assert(SaveManager.get_slot_data(0).save_timestamp == 20000, "Slot read returned stale data in " + name)


func _test_recover_legacy_and_interrupted_saves() -> void:
	var slot_index: int = 0
	var base: String = SaveManager._slot_path(slot_index)
	var tmp: String = SaveManager._tmp_path(slot_index)
	assert(DirAccess.rename_absolute(base, base + ".bak.old") == OK, "Cannot stage old legacy fixture in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 20000, "Old legacy backup unreadable in " + name)
	assert(DirAccess.rename_absolute(base + ".bak.old", base + ".bak") == OK, "Cannot stage legacy fixture in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 20000, "Legacy backup unreadable in " + name)
	assert(not FileAccess.file_exists(base), "Slot inspection restored backup on disk in " + name)
	assert(SaveManager._recover_slot(slot_index), "Legacy backup recovery failed in " + name)
	assert(FileAccess.file_exists(base), "Legacy backup was not copied into primary in " + name)

	_write_snapshot(tmp, slot_index, 30000)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 30000, "Interrupted write unreadable in " + name)
	assert(FileAccess.file_exists(tmp), "Slot inspection consumed interrupted write in " + name)
	assert(SaveManager._recover_slot(slot_index), "Interrupted write recovery failed in " + name)
	assert(not FileAccess.file_exists(tmp), "Recovery left interrupted write in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 30000, "Recovery lost latest save in " + name)
	assert(ResourceLoader.load(SaveManager._backup_path(slot_index)).get("save_timestamp") == 20000, "Recovery lost previous save in " + name)

	assert(DirAccess.rename_absolute(base, tmp) == OK, "Cannot simulate interrupted rotation in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 30000, "Recovery chose an older backup in " + name)
	assert(SaveManager._recover_slot(slot_index), "Cannot recover a missing primary in " + name)

	_write_snapshot(tmp, slot_index, 10000)
	assert(SaveManager._recover_slot(slot_index), "Stale temp cleanup failed in " + name)
	assert(not FileAccess.file_exists(tmp), "Recovery left stale temp in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 30000, "Stale temp replaced primary in " + name)


func _test_delete_slot_removes_all_variants(fake_backend: FakeCloudBackend) -> void:
	var slot_index: int = 1
	var base: String = SaveManager._slot_path(slot_index)

	_write_snapshot(base, slot_index, 12345)
	for path: String in _slot_paths(slot_index):
		if path != base:
			assert(DirAccess.copy_absolute(base, path) == OK, "Cannot write delete fixture in " + name)
	fake_backend.delete_succeeds = false
	assert(not SaveManager.delete_slot(slot_index), "Cloud delete failure reported success in " + name)
	assert(_cloud_failures.back() == SaveManager.CloudOperation.DELETE, "Missing delete failure in " + name)
	assert(FileAccess.file_exists(base), "Failed cloud deletion removed primary in " + name)
	fake_backend.delete_succeeds = true
	assert(SaveManager.delete_slot(slot_index), "Slot deletion failed in " + name)
	for path: String in _slot_paths(slot_index):
		assert(not FileAccess.file_exists(path), "Deletion left fixture in " + name + ": " + path)
	assert(not SaveManager.has_save(slot_index), "SaveManager: has_save() true after delete_slot()")
	assert(fake_backend.deleted == [SaveManager._cloud_filename(slot_index)], "Wrong cloud deletion in " + name)


func _test_corrupt_slot_inspection_is_read_only() -> void:
	var slot_index: int = 1
	var base: String = SaveManager._slot_path(slot_index)
	var corrupt_bytes: PackedByteArray = "corrupt".to_utf8_buffer()
	_write_bytes(base, corrupt_bytes)
	_write_bytes(base + ".bak", corrupt_bytes)
	var before: PackedStringArray = DirAccess.get_files_at(SaveManager.SAVE_DIR)

	# Limit diagnostic suppression to reading the deliberately corrupt fixture
	var print_error_messages: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var loaded: SaveData = SaveManager.get_slot_data(slot_index)
	var exists: bool = SaveManager.has_save(slot_index)
	Engine.print_error_messages = print_error_messages

	assert(loaded == null, "SaveManager: corrupt slot returned data")
	assert(not exists, "Corrupt slot reported as loadable in " + name)
	assert(DirAccess.get_files_at(SaveManager.SAVE_DIR) == before, "Slot inspection changed save directory in " + name)
	assert(FileAccess.get_file_as_bytes(base) == corrupt_bytes, "Slot inspection changed primary in " + name)
	assert(FileAccess.get_file_as_bytes(base + ".bak") == corrupt_bytes, "Slot inspection changed backup in " + name)
	assert(DirAccess.remove_absolute(base) == OK, "Cannot clear corrupt fixture in " + name)
	assert(DirAccess.remove_absolute(base + ".bak") == OK, "Cannot clear corrupt backup fixture in " + name)


func _test_cloud_sync(fake_backend: FakeCloudBackend) -> void:
	var slot_index: int = 0
	var base: String = SaveManager._slot_path(slot_index)
	var cloud_name: String = SaveManager._cloud_filename(slot_index)
	var staged: String = SaveManager._incoming_path(slot_index)
	assert(not fake_backend.download(cloud_name, staged), "Missing cloud save reported success in " + name)
	assert(not FileAccess.file_exists(staged), "Missing cloud save created staging file in " + name)
	var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(base)
	var fixture_dir: DirAccess = DirAccess.create_temp("ludus-remote")
	assert(fixture_dir != null, "Cannot create remote fixture directory in " + name)
	var fixture: String = fixture_dir.get_current_dir().path_join("remote.tres")
	var print_error_messages: bool = Engine.print_error_messages
	fake_backend.remote_saves[cloud_name] = "corrupt".to_utf8_buffer()
	Engine.print_error_messages = false
	SaveManager._recover_and_sync_slots()
	Engine.print_error_messages = print_error_messages
	assert(_cloud_failures.back() == SaveManager.CloudOperation.DOWNLOAD, "Corrupt download accepted in " + name)
	assert(FileAccess.get_file_as_bytes(base) == original_bytes, "Corrupt download replaced primary in " + name)

	_write_snapshot(fixture, slot_index, 40000, 1)
	fake_backend.remote_saves[cloud_name] = FileAccess.get_file_as_bytes(fixture)
	fake_backend.download_succeeds = false
	SaveManager._recover_and_sync_slots()
	assert(_cloud_failures.count(SaveManager.CloudOperation.DOWNLOAD) == 2, "Failed write was not reported in " + name)
	assert(FileAccess.get_file_as_bytes(base) == original_bytes, "Failed download replaced primary in " + name)
	assert(not FileAccess.file_exists(SaveManager._incoming_path(slot_index)), "Failed download left staging file in " + name)
	fake_backend.download_succeeds = true

	_write_snapshot(fixture, slot_index, 30000, 1)
	fake_backend.remote_saves[cloud_name] = FileAccess.get_file_as_bytes(fixture)
	SaveManager._recover_and_sync_slots()
	assert(_cloud_failures.back() == SaveManager.CloudOperation.CONFLICT, "Equal revision conflict was not reported in " + name)
	assert(FileAccess.get_file_as_bytes(base) == original_bytes, "Equal revision replaced primary in " + name)

	_write_snapshot(fixture, slot_index, 10000)
	fake_backend.remote_saves[cloud_name] = FileAccess.get_file_as_bytes(fixture)
	SaveManager._recover_and_sync_slots()
	assert(FileAccess.get_file_as_bytes(base) == original_bytes, "Older snapshot replaced primary in " + name)

	_write_snapshot(fixture, slot_index, 40000, 1)
	fake_backend.remote_saves[cloud_name] = FileAccess.get_file_as_bytes(fixture)
	_test_cloud_commit_failure(slot_index, original_bytes)
	SaveManager._recover_and_sync_slots()
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 40000, "Newer snapshot was not installed in " + name)
	assert(FileAccess.get_file_as_bytes(SaveManager._backup_path(slot_index)) == original_bytes, "Commit lost previous save in " + name)

	var failures_before_repeat: int = _cloud_failures.size()
	SaveManager._recover_and_sync_slots()
	assert(_cloud_failures.size() == failures_before_repeat, "Identical revision reported as a conflict in " + name)

	SaveManager._upload_slot(slot_index)
	assert(_cloud_failures.back() == SaveManager.CloudOperation.UPLOAD, "Upload failure was not reported in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 40000, "Upload failure changed primary in " + name)
	fake_backend.remote_saves.clear()


func _test_cloud_commit_failure(slot_index: int, original_bytes: PackedByteArray) -> void:
	var backup: String = SaveManager._backup_path(slot_index)
	assert(DirAccess.remove_absolute(backup) == OK, "Cannot clear backup fixture in " + name)
	assert(DirAccess.make_dir_absolute(backup) == OK, "Cannot block backup destination in " + name)
	var blocker: String = backup.path_join("blocker")
	_write_bytes(blocker, "blocker".to_utf8_buffer())
	var print_error_messages: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	SaveManager._recover_and_sync_slots()
	Engine.print_error_messages = print_error_messages
	assert(_cloud_failures.back() == SaveManager.CloudOperation.DOWNLOAD, "Failed commit was not reported in " + name)
	assert(FileAccess.get_file_as_bytes(SaveManager._slot_path(slot_index)) == original_bytes, "Failed commit changed primary in " + name)
	assert(not FileAccess.file_exists(SaveManager._incoming_path(slot_index)), "Failed commit left staging file in " + name)
	assert(DirAccess.remove_absolute(blocker) == OK, "Cannot clear backup blocker in " + name)
	assert(DirAccess.remove_absolute(backup) == OK, "Cannot clear blocked backup destination in " + name)


func _test_local_commit_keeps_previous_save() -> void:
	var slot_index: int = 0
	var base: String = SaveManager._slot_path(slot_index)
	var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(base)
	var data: SaveData = SaveData.new()
	data.slot_index = slot_index
	data.save_timestamp = 50000
	assert(SaveManager._persist_slot(slot_index, data), "Local write failed in " + name)
	assert(SaveManager.get_slot_data(slot_index).save_timestamp == 50000, "Local write did not install snapshot in " + name)
	assert(FileAccess.get_file_as_bytes(SaveManager._backup_path(slot_index)) == original_bytes, "Local write lost previous save in " + name)


func _test_rename_round_trip(backend: FakeCloudBackend) -> void:
	var slot_index: int = 0
	var base: String = SaveManager._slot_path(slot_index)
	_write_snapshot(base, slot_index, 12345, 42)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(base)
	assert(SaveManager.get_slot_data(slot_index).display_name.is_empty(), "Legacy save has a name in " + name)
	assert(not SaveManager.rename_slot(SaveManager.MANUAL_SLOTS, "Auto"), "Autosave accepted a rename in " + name)

	var display_name: String = "São / 日本語 : \"العربية\" 👩‍🚀 e\u0301"
	assert(SaveManager.rename_slot(slot_index, display_name), "Rename failed in " + name)
	var renamed: SaveData = SaveManager.get_slot_data(slot_index)
	assert(renamed.display_name == display_name, "Rename did not round-trip in " + name)
	assert(renamed.save_timestamp == 12345 and renamed.player.gold == 42, "Rename changed progress in " + name)
	var renamed_bytes: PackedByteArray = FileAccess.get_file_as_bytes(base)
	assert(SaveManager.rename_slot(slot_index, display_name), "Identical rename failed in " + name)
	assert(FileAccess.get_file_as_bytes(base) == renamed_bytes, "Identical rename rewrote the save in " + name)

	_write_bytes(base, original)
	var cloud_filename: String = SaveManager._cloud_filename(slot_index)
	backend.remote_saves[cloud_filename] = renamed_bytes
	SaveManager._recover_and_sync_slots()
	assert(SaveManager.get_slot_data(slot_index).display_name == display_name, "Cloud missed a rename in " + name)
	assert(SaveManager.rename_slot(slot_index, ""), "Clearing the name failed in " + name)
	assert(SaveManager.get_slot_data(slot_index).display_name.is_empty(), "Clearing the name did not persist in " + name)
	SaveManager._recover_and_sync_slots()
	assert(SaveManager.get_slot_data(slot_index).display_name.is_empty(), "Cloud replayed an earlier name in " + name)

	var newer_save: SaveData = SaveData.new()
	newer_save.save_timestamp = 12346
	newer_save.player.gold = 43
	var remote_path: String = SaveManager._incoming_path(slot_index)
	assert(ResourceSaver.save(newer_save, remote_path) == OK, "Could not stage newer gameplay in " + name)
	backend.remote_saves[cloud_filename] = FileAccess.get_file_as_bytes(remote_path)
	SaveManager._recover_and_sync_slots()
	backend.remote_saves.erase(cloud_filename)
	assert(SaveManager.get_slot_data(slot_index).player.gold == 43, "Rename overrode newer gameplay in " + name)


func _on_cloud_sync_failed(_slot_index: int, operation: SaveManager.CloudOperation) -> void:
	_cloud_failures.append(operation)


func _write_snapshot(path: String, slot_index: int, timestamp: int, gold: int = 0) -> void:
	var data: SaveData = SaveData.new()
	data.slot_index = slot_index
	data.save_timestamp = timestamp
	data.player.gold = gold
	assert(ResourceSaver.save(data, path) == OK, "Cannot write snapshot fixture in " + name + ": " + path)


func _write_bytes(path: String, bytes: PackedByteArray) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	assert(file != null and file.store_buffer(bytes), "Cannot write bytes in " + name + ": " + path)
