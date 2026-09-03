# TODO Refactor to decouple from player spawn
## [img]res://docs/diagrams/saving/saving.drawio.png[/img] [br]
## Slot save system: slots 2 manual, 2 auto
## Write to .tmp → rename to .tres, keep .bak of previous good save
extends Node

## Every system should trigger internal save
signal save_requested(data: SaveData)
## Every system should trigger internal load
signal load_requested(data: SaveData)
signal save_changed(slot_index: int)
## Every system should reset for new game
signal reset_requested
signal reset_finished

const SAVE_DIR: String = "user://saves/"
const MANUAL_SLOTS: int = 2
const AUTO_SLOTS: int = 2
const TOTAL_SLOTS: int = MANUAL_SLOTS + AUTO_SLOTS
const AUTO_SAVE_INTERVAL: float = 120.0
const CURRENT_SAVE_VERSION: int = 1

var _save_block_sources: Dictionary = {}

var _next_auto_slot: int = 0
var _auto_timer: Timer

var _active_slot_index: int = -1

var _cloud_backend: CloudSaveBackend = SteamCloudSaveBackend.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	get_tree().set_auto_accept_quit(false)
	_cleanup_stale_temp_files()

	_sync_cloud_saves()
	_next_auto_slot = _find_next_auto_slot()

	# TODO Change this to only start when gameplay active maybe?
	_auto_timer = Timer.new()
	_auto_timer.name = "AutoSaveTimer"
	_auto_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)
	_auto_timer.start()

	# Saves to quick slot upon pause and quit
	ApplicationStateManager.gameplay_paused.connect(_on_gameplay_paused)
	ApplicationStateManager.quit_requested.connect(_on_quit_requested)


func reset_data_for_new_game(slot_index: int) -> void:
	_active_slot_index = slot_index
	_next_auto_slot = 0
	reset_requested.emit()
	reset_finished.emit()


#region Save Load and Delete
# TODO Change to a request save to slot
func _save_to_active_slot(force: bool) -> void:
	assert(_active_slot_index != -1, "SaveManager: no active slot set in " + name)
	_write_slot(_active_slot_index, false, force)


# TODO Change to a request quick save
func save_to_quick_slot(force: bool) -> bool:
	return _write_slot(MANUAL_SLOTS - 1, false, force)


func load_from_slot(slot_index: int) -> bool:
	assert(not is_save_blocked(), "Saving blocked by " + str(_save_block_sources.keys()))

	assert(
		slot_index >= 0 and slot_index < TOTAL_SLOTS,
		"SaveManager: slot out of range in " + name,
	)
	assert(has_save(slot_index), "Slot index " + str(slot_index) + " doesn't have save")

	var data: SaveData = _load_slot_resource(slot_index)
	assert(data != null, "SaveData missing for slot " + str(slot_index) + " in " + name)

	if data.save_version != CURRENT_SAVE_VERSION:
		if not _migrate(data):
			return false

	_active_slot_index = slot_index
	request_save_block(&"loading")
	_apply(data)

	return true


func delete_slot(slot_index: int) -> void:
	assert(slot_index >= 0 and slot_index < TOTAL_SLOTS, "SaveManager: slot out of range in " + name)
	var base: String = _slot_path(slot_index)
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = base + suffix
		if FileAccess.file_exists(path):
			_safe_remove(path)
	_cloud_backend.delete(_cloud_filename(slot_index))
	save_changed.emit(slot_index)


#endregion


#region Public getters
func has_save(slot_index: int) -> bool:
	var base: String = _slot_path(slot_index)
	return FileAccess.file_exists(base) or FileAccess.file_exists(base + ".bak")


func get_slot_data(slot_index: int) -> SaveData:
	if not has_save(slot_index):
		return null
	return _load_slot_resource(slot_index)


func has_any_save() -> bool:
	for i: int in range(TOTAL_SLOTS):
		if has_save(i):
			return true
	return false


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
	assert(
		slot_index >= 0 and slot_index < TOTAL_SLOTS,
		"SaveManager: slot out of range in " + name,
	)

	if not _can_save(force):
		return false

	var data: SaveData = _build_save(slot_index, is_auto)
	if not _persist_slot(slot_index, data):
		return false

	save_changed.emit(slot_index)
	_cloud_backend.upload(_cloud_filename(slot_index), _slot_path(slot_index))

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
	var base: String = _slot_path(slot_index)
	var tmp: String = _tmp_path(slot_index)
	var bak: String = base + ".bak"
	var bak_prev: String = base + ".bak.old"

	var err: int = ResourceSaver.save(data, tmp)
	if err != OK:
		push_error("SaveManager: failed writing tmp for slot %d (error %d)" % [slot_index, err])
		return false

	var verify: SaveData = ResourceLoader.load(tmp, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
	if verify == null:
		_safe_remove(tmp)
		push_error("SaveManager: tmp verification failed for slot %d, aborting commit" % slot_index)
		return false

	var had_prev_bak: bool = FileAccess.file_exists(bak)
	if had_prev_bak and not _safe_rename(bak, bak_prev):
		_safe_remove(tmp)
		return false

	if FileAccess.file_exists(base) and not _safe_rename(base, bak):
		if had_prev_bak:
			_safe_rename(bak_prev, bak)
		_safe_remove(tmp)
		return false

	if not _safe_rename(tmp, base):
		push_error("SaveManager: failed committing save for slot %d" % slot_index)
		if FileAccess.file_exists(bak):
			_safe_rename(bak, base)
		if had_prev_bak:
			_safe_rename(bak_prev, bak)
		return false

	if had_prev_bak:
		_safe_remove(bak_prev)

	return true


func _build_save(slot_index: int, is_auto: bool) -> SaveData:
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


# PLACEHOLDER
func _migrate(data: SaveData) -> bool:
	data.save_version = CURRENT_SAVE_VERSION
	return true


func _slot_path(slot_index: int) -> String:
	return SAVE_DIR + "slot_%d.tres" % slot_index


func _load_slot_resource(slot_index: int) -> SaveData:
	var base: String = _slot_path(slot_index)
	var data: SaveData = ResourceLoader.load(base) as SaveData
	if data != null:
		return data
	var bak: String = base + ".bak"
	if FileAccess.file_exists(bak):
		push_error("SaveManager: slot %d corrupt, loading backup" % slot_index)
		data = ResourceLoader.load(bak) as SaveData
	return data


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
	return _slot_path(slot_index).replace(".tres", "_tmp.tres")


func _cleanup_stale_temp_files() -> void:
	for i: int in range(TOTAL_SLOTS):
		var path: String = _tmp_path(i)
		if FileAccess.file_exists(path):
			_safe_remove(path)


func _find_next_auto_slot() -> int:
	var oldest_index: int = 0
	var oldest_timestamp: float = INF
	for i: int in range(AUTO_SLOTS):
		var slot: int = MANUAL_SLOTS + i
		var data: SaveData = get_slot_data(slot)
		if data == null:
			return i
		if data.save_timestamp < oldest_timestamp:
			oldest_timestamp = data.save_timestamp
			oldest_index = i
	return oldest_index


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		ApplicationStateManager.request_quit()


func _on_gameplay_paused() -> void:
	_save_to_active_slot(false)


func _on_quit_requested() -> void:
	if _active_slot_index != -1:
		_save_to_active_slot(true)
	else:
		push_warning("Saving on quit tried to save without active slot")


func _sync_cloud_saves() -> void:
	for i: int in range(TOTAL_SLOTS):
		var cloud_name: String = _cloud_filename(i)
		if _cloud_backend.remote_is_newer(cloud_name, _slot_path(i)):
			_cloud_backend.download(cloud_name, _slot_path(i))


func _cloud_filename(slot_index: int) -> String:
	return "slot_%d.tres" % slot_index
#endregion
