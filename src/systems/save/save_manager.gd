# TODO Refactor to decouple from player spawn
extends Node

## Manages manual and automatic save slots, disk recovery, and cloud sync [br]
## Stage and validate .tres snapshots before replacing primary, keep previous good save [br]
## [img]res://docs/diagrams/saving/saving.drawio.png[/img]

## Every system should trigger internal save
signal save_requested(data: SaveData)
## Every system should trigger internal load
signal load_requested(data: SaveData)
signal save_changed(slot_index: int)
## Reports cloud failures independently of local save success
signal cloud_sync_failed(slot_index: int, operation: CloudOperation)
## Every system should restore defaults for new game
signal reset_requested
signal reset_finished

const SAVE_DIR: String = "user://saves/"
const FIRST_MANUAL_SLOT: int = 0
const MANUAL_SLOTS: int = 2
const AUTO_SLOTS: int = 2
const TOTAL_SLOTS: int = MANUAL_SLOTS + AUTO_SLOTS
const AUTO_SAVE_INTERVAL: float = 120.0
const CURRENT_SAVE_VERSION: int = 2

const CORRUPT_SUFFIX: String = ".corrupt_"

enum CloudOperation {
	DOWNLOAD = 0,
	UPLOAD = 1,
	DELETE = 2,
	CONFLICT = 3,
}


class SlotSnapshot:
	var path: String
	var data: SaveData


var _save_block_sources: Dictionary = { }

var _next_auto_slot: int = 0
var _auto_timer: Timer

var _active_slot_index: int = -1

var _cloud_backend: CloudSaveBackend


func _ready() -> void:
	if SteamWorks.steam_enabled:
		_cloud_backend = SteamCloudSaveBackend.new()
	else:
		# This is used so save manager doesn't care about cloud
		# TODO Decouple cloud operations to a CloudSaveSyncService
		_cloud_backend = NullCloudSaveBackend.new()

	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	get_tree().set_auto_accept_quit(false)
	_recover_and_sync_slots()
	_next_auto_slot = _find_next_auto_slot()

	_setup_auto_save_timer()

	# Saves to quick slot upon pause and quit
	ApplicationStateManager.gameplay_paused.connect(_save_to_active_slot.bind(false))
	ApplicationStateManager.quit_requested.connect(_save_to_active_slot.bind(true))

	ApplicationStateManager.gameplay_started.connect(
		func() -> void:
			_auto_timer.start(),
	)
	ApplicationStateManager.gameplay_paused.connect(
		func() -> void:
			_auto_timer.stop(),
	)


func configure_cloud_backend(backend: CloudSaveBackend) -> void:
	_cloud_backend = backend


func initialize_new_save(slot_index: int) -> void:
	_active_slot_index = slot_index
	_next_auto_slot = 0
	reset_requested.emit()
	reset_finished.emit()


#region Save Load and Delete

# TODO Change to a request save to slot
func _save_to_active_slot(force: bool) -> void:
	if _active_slot_index == -1:
		push_warning("Tried saving without active slot")
		return
	_write_slot(_active_slot_index, false, force)


# TODO Change to a request quick save
func save_to_quick_slot(force: bool) -> bool:
	return _write_slot(MANUAL_SLOTS - 1, false, force)


func load_from_slot(slot_index: int) -> bool:
	assert(not is_save_blocked(), "Saving blocked in %s by %s" % [name, _save_block_sources.keys()])

	assert(slot_index >= 0 and slot_index < TOTAL_SLOTS, "SaveManager: slot out of range in " + name)
	var data: SaveData = get_slot_data(slot_index)
	assert(data != null, "No readable save in slot %d in %s" % [slot_index, name])
	if data == null:
		return false

	if data.save_version != CURRENT_SAVE_VERSION:
		if not _migrate(data):
			return false

	_active_slot_index = slot_index
	request_save_block(&"loading")
	_apply(data)

	return true


func delete_slot(slot_index: int) -> bool:
	assert(slot_index >= 0 and slot_index < TOTAL_SLOTS, "SaveManager: slot out of range in " + name)
	var base: String = _slot_path(slot_index)
	if _cloud_backend.is_available() and not _cloud_backend.delete(_cloud_filename(slot_index)):
		_report_cloud_failure(slot_index, CloudOperation.DELETE)
		return false

	var paths: Array[String] = [
		_backup_path(slot_index),
		base + ".bak",
		base + ".bak.old",
		_tmp_path(slot_index),
		base + ".tmp",
		_incoming_path(slot_index),
		base,
	]
	for path: String in paths:
		if FileAccess.file_exists(path) and not _safe_remove(path):
			save_changed.emit(slot_index)
			return false
	save_changed.emit(slot_index)
	return true

#endregion


#region Public getters
func has_save(slot_index: int) -> bool:
	return get_slot_data(slot_index) != null


func get_slot_data(slot_index: int) -> SaveData:
	var snapshot: SlotSnapshot = _read_slot(slot_index)
	return snapshot.data if snapshot != null else null


func has_any_save() -> bool:
	for i: int in range(TOTAL_SLOTS):
		if has_save(i):
			return true
	return false


##  if empty slot, it wins
func get_oldest_slot(first_slot: int, slot_count: int) -> int:
	var oldest_slot: int = first_slot
	var oldest_timestamp: float = INF
	for slot: int in range(first_slot, first_slot + slot_count):
		var data: SaveData = get_slot_data(slot)
		if data == null:
			return slot
		if data.save_timestamp < oldest_timestamp:
			oldest_timestamp = data.save_timestamp
			oldest_slot = slot
	return oldest_slot


## -1 if none
func get_latest_slot() -> int:
	var latest_slot: int = -1
	var latest_timestamp: int = -1
	for slot: int in range(TOTAL_SLOTS):
		var data: SaveData = get_slot_data(slot)
		if data != null and data.save_timestamp > latest_timestamp:
			latest_timestamp = data.save_timestamp
			latest_slot = slot
	return latest_slot


## Blocks saving while [param source] is mid-transition (respawn, load...)
func request_save_block(source: StringName) -> void:
	_save_block_sources[source] = true


func release_save_block(source: StringName) -> void:
	_save_block_sources.erase(source)


func is_save_blocked() -> bool:
	return not _save_block_sources.is_empty()

#endregion


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save") and ApplicationStateManager.is_gameplay_active():
		_save_to_active_slot(false)
		get_viewport().set_input_as_handled()


#region Private helpers
func _on_auto_save() -> void:
	var target_slot: int = MANUAL_SLOTS + _next_auto_slot
	if _write_slot(target_slot, true):
		_next_auto_slot = (_next_auto_slot + 1) % AUTO_SLOTS


func _write_slot(slot_index: int, is_auto: bool, force: bool = false) -> bool:
	assert(slot_index >= 0 and slot_index < TOTAL_SLOTS, "SaveManager: slot out of range in " + name)

	if not _can_save(force):
		return false

	var data: SaveData = _build_save_data(slot_index, is_auto)
	if not _persist_slot(slot_index, data):
		return false

	_upload_slot(slot_index)
	save_changed.emit(slot_index)

	print_debug("Saved slot ", slot_index)
	return true


func _can_save(force: bool) -> bool:
	if not force and is_save_blocked():
		print_debug("Save blocked by ", _save_block_sources.keys())
		return false

	if not ApplicationStateManager.is_gameplay_active():
		print_debug("Tried saving while gameplay not active")
		return false

	return true


func _persist_slot(slot_index: int, data: SaveData) -> bool:
	if not _recover_slot(slot_index):
		return false
	var tmp: String = _tmp_path(slot_index)
	var err: int = ResourceSaver.save(data, tmp)
	if err != OK:
		push_error("SaveManager: failed writing tmp for slot %d (error %d)" % [slot_index, err])
		return false

	if _read_snapshot(tmp, slot_index) == null:
		push_error("SaveManager: tmp verification failed for slot %d, aborting commit" % slot_index)
		return false
	return _commit_staged_slot(slot_index, tmp)


func _commit_staged_slot(slot_index: int, staged: String) -> bool:
	var base: String = _slot_path(slot_index)
	if not FileAccess.file_exists(base):
		return _safe_rename(staged, base)

	var previous: String = _backup_path(slot_index)
	if _read_snapshot(base, slot_index) == null:
		previous = "%s%s%d_%d" % [base, CORRUPT_SUFFIX, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	if not _safe_rename(base, previous):
		return false
	if not _safe_rename(staged, base):
		_safe_rename(previous, base)
		return false
	return true


func _build_save_data(slot_index: int, is_auto: bool) -> SaveData:
	var data: SaveData = SaveData.new()
	data.save_version = CURRENT_SAVE_VERSION
	data.slot_index = slot_index
	data.is_auto_save = is_auto
	data.save_timestamp = int(Time.get_unix_time_from_system())
	data.play_time_seconds = GameplayStateManager.get_play_time()

	save_requested.emit(data)

	return data


func _apply(data: SaveData) -> void:
	GameplayStateManager.set_play_time(data.play_time_seconds)
	load_requested.emit(data)


func _migrate(data: SaveData) -> bool:
	if data.save_version == 1:
		_migrate_v1_to_v2(data)
	return data.save_version == CURRENT_SAVE_VERSION


## v1 stored skills as resource references, v2 stores SkillDefinition.id
func _migrate_v1_to_v2(data: SaveData) -> void:
	for definition: SkillDefinition in data.player.unlocked_skills:
		data.player.unlocked_skill_ids.append(definition.id)
	data.player.unlocked_skills.clear()
	data.save_version = 2


func _slot_path(slot_index: int) -> String:
	return SAVE_DIR + "slot_%d.tres" % slot_index


func _read_slot(slot_index: int) -> SlotSnapshot:
	var base: String = _slot_path(slot_index)
	var best: SlotSnapshot = _read_snapshot(base, slot_index)
	var candidates: Array[String] = [_tmp_path(slot_index), base + ".tmp"]
	if best == null:
		candidates.append_array([_backup_path(slot_index), base + ".bak", base + ".bak.old"])
	for path: String in candidates:
		var candidate: SlotSnapshot = _read_snapshot(path, slot_index)
		if candidate != null and (best == null or candidate.data.save_timestamp > best.data.save_timestamp):
			best = candidate
	return best


func _read_snapshot(path: String, slot_index: int) -> SlotSnapshot:
	if not FileAccess.file_exists(path):
		return null
	var load_path: String = path
	var staging_file: FileAccess
	if path.get_extension() != "tres":
		staging_file = FileAccess.create_temp(FileAccess.WRITE, "ludus-save", "tres")
		if staging_file == null or not staging_file.store_buffer(FileAccess.get_file_as_bytes(path)):
			return null
		staging_file.flush()
		if staging_file.get_error() != OK:
			return null
		load_path = staging_file.get_path_absolute()
	var resource: Resource = ResourceLoader.load(load_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not (resource is SaveData):
		return null
	var data: SaveData = resource
	if (
		data.slot_index != slot_index or data.save_version < 1 or data.save_timestamp < 0 or not is_finite(data.play_time_seconds)
		or data.play_time_seconds < 0.0 or data.player == null or data.world == null or data.chunks == null or data.checkpoint == null
	):
		return null
	var snapshot: SlotSnapshot = SlotSnapshot.new()
	snapshot.path = path
	snapshot.data = data
	return snapshot


## Recover before cleaning interrupted writes; archive unreadable primaries only when replacing them
func _recover_slot(slot_index: int) -> bool:
	var best: SlotSnapshot = _read_slot(slot_index)
	var base: String = _slot_path(slot_index)
	var tmp: String = _tmp_path(slot_index)
	if best != null and best.path != base:
		var staged: String = best.path
		if staged != tmp:
			staged = _incoming_path(slot_index)
			var error: Error = DirAccess.copy_absolute(best.path, staged)
			if error != OK:
				push_error("SaveManager: failed staging recovery for slot %d (%d)" % [slot_index, error])
				return false
		if not _commit_staged_slot(slot_index, staged):
			return false
	for path: String in [tmp, base + ".tmp", _incoming_path(slot_index)]:
		if FileAccess.file_exists(path) and not _safe_remove(path):
			return false
	return true


func _safe_remove(path: String) -> bool:
	var err: int = DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SaveManager: failed removing %s (%d)" % [path, err])
		return false
	return true


func _safe_rename(from: String, to: String) -> bool:
	var err: int = DirAccess.rename_absolute(from, to)
	if err != OK:
		push_error("SaveManager: failed renaming %s -> %s (%d)" % [from, to, err])
		return false
	return true


func _tmp_path(slot_index: int) -> String:
	return _slot_path(slot_index).get_basename() + "_tmp.tres"


func _backup_path(slot_index: int) -> String:
	return _slot_path(slot_index).get_basename() + "_bak.tres"


func _incoming_path(slot_index: int) -> String:
	return _slot_path(slot_index).get_basename() + "_incoming.tres"


func _find_next_auto_slot() -> int:
	return get_oldest_slot(MANUAL_SLOTS, AUTO_SLOTS) - MANUAL_SLOTS


func _setup_auto_save_timer() -> void:
	_auto_timer = Timer.new()
	_auto_timer.name = "AutoSaveTimer"
	_auto_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)

	ApplicationStateManager.gameplay_started.connect(_auto_timer.start)
	ApplicationStateManager.gameplay_resumed.connect(_auto_timer.start)
	ApplicationStateManager.gameplay_paused.connect(_auto_timer.stop)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		ApplicationStateManager.request_quit()

#endregion


#region Cloud
func _recover_and_sync_slots() -> void:
	for slot_index: int in range(TOTAL_SLOTS):
		if (_recover_slot(slot_index) and _cloud_backend.is_available() and _cloud_backend.has_remote_save(_cloud_filename(slot_index))):
			_sync_cloud_slot(slot_index)


func _sync_cloud_slot(slot_index: int) -> void:
	var local: SlotSnapshot = _read_slot(slot_index)
	var staged: String = _incoming_path(slot_index)
	var downloaded: bool = _cloud_backend.download(_cloud_filename(slot_index), staged)
	var remote: SlotSnapshot = _read_snapshot(staged, slot_index) if downloaded else null
	if remote == null or remote.data.save_version > CURRENT_SAVE_VERSION:
		_report_cloud_failure(slot_index, CloudOperation.DOWNLOAD)
	elif local == null or (local.data.save_version <= CURRENT_SAVE_VERSION and remote.data.save_timestamp > local.data.save_timestamp):
		if _commit_staged_slot(slot_index, staged):
			save_changed.emit(slot_index)
		else:
			_report_cloud_failure(slot_index, CloudOperation.DOWNLOAD)
	elif (remote.data.save_timestamp == local.data.save_timestamp and FileAccess.get_sha256(staged) != FileAccess.get_sha256(local.path)):
		_report_cloud_failure(slot_index, CloudOperation.CONFLICT)
	if FileAccess.file_exists(staged):
		_safe_remove(staged)


func _upload_slot(slot_index: int) -> void:
	if _cloud_backend.is_available() and not _cloud_backend.upload(_cloud_filename(slot_index), _slot_path(slot_index)):
		_report_cloud_failure(slot_index, CloudOperation.UPLOAD)


func _report_cloud_failure(slot_index: int, operation: CloudOperation) -> void:
	var operation_name: String = CloudOperation.keys()[operation]
	print("SaveManager: cloud %s failed for slot %d" % [operation_name, slot_index])
	cloud_sync_failed.emit(slot_index, operation)

# TODO Study cloud cleanup if too many files


func _cloud_filename(slot_index: int) -> String:
	return "slot_%d.tres" % slot_index
#endregion
