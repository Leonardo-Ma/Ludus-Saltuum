# TODO Refactor to decouple from player spawn
## [img]res://docs/diagrams/saving/saving.drawio.png[/img] [br]
## Slot save system: slots 2 manual, 2 auto
## Write to .tmp → rename to .tres, keep .bak of previous good save
extends Node

signal save_changed(slot_index: int)

const SAVE_DIR: String = "user://saves/"
const MANUAL_SLOTS: int = 2
const AUTO_SLOTS: int = 2
const TOTAL_SLOTS: int = MANUAL_SLOTS + AUTO_SLOTS
const AUTO_SAVE_INTERVAL: float = 120.0
const CURRENT_SAVE_VERSION: int = 1

var _next_auto_slot: int = 0
var _auto_timer: Timer


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	_sync_cloud_saves()
	_next_auto_slot = _find_next_auto_slot()

	_auto_timer = Timer.new()
	_auto_timer.name = "AutoSaveTimer"
	_auto_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_timer.timeout.connect(_on_auto_save)
	add_child(_auto_timer)
	_auto_timer.start()


func reset_data_for_new_game() -> void:
	_next_auto_slot = 0
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	player.player_save_controller.reset_data()
	WorldSaveController.reset_data()
	LevelChunkManager.reset_data()
	CheckpointSaveController.reset_data()
	# TODO Maybe change this trigger to signal based?
	LevelChunkManager.initialize_level()


#region Save Load and Delete
# TODO Change to a request save to slot
func save_to_slot(slot_index: int) -> bool:
	assert(
		slot_index >= 0 and slot_index < MANUAL_SLOTS,
		"SaveManager: manual slot must be 0–%d in %s" % [MANUAL_SLOTS - 1, name],
	)
	return _write_slot(slot_index, false)


# TODO Change to a request quick save
func save_to_quick_slot() -> bool:
	return _write_slot(MANUAL_SLOTS - 1, false)


func load_from_slot(slot_index: int) -> bool:
	assert(
		slot_index >= 0 and slot_index < TOTAL_SLOTS,
		"SaveManager: slot out of range in " + name,
	)
	assert(has_save(slot_index), "Slot index " + str(slot_index) + " doesn't have save")

	var data: SaveData = _load_slot_resource(slot_index)
	assert(data, "Data from slot" + str(slot_index) + "missing or corrupted")

	if data.save_version != CURRENT_SAVE_VERSION:
		if not _migrate(data):
			return false

	_apply(data)

	return true


func delete_slot(slot_index: int) -> void:
	assert(
		slot_index >= 0 and slot_index < TOTAL_SLOTS,
		"SaveManager: slot out of range in " + name,
	)
	var base: String = _slot_path(slot_index)
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = base + suffix
		if FileAccess.file_exists(path):
			_safe_remove(path)
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


#endregion


#region Private helpers
func _on_auto_save() -> void:
	if get_tree().paused:
		return
	var target_slot: int = MANUAL_SLOTS + _next_auto_slot
	_write_slot(target_slot, true)
	_next_auto_slot = (_next_auto_slot + 1) % AUTO_SLOTS


func _write_slot(slot_index: int, is_auto: bool) -> bool:
	var data: SaveData = _build_save(slot_index, is_auto)
	var base: String = _slot_path(slot_index)
	var tmp: String = base.replace(".tres", "_tmp.tres")
	var bak: String = base + ".bak"

	var err: int = ResourceSaver.save(data, tmp)
	if err != OK:
		push_error("SaveManager: failed writing tmp for slot %d (error %d)" % [slot_index, err])
		return false

	var verify: SaveData = ResourceLoader.load(tmp, "", ResourceLoader.CACHE_MODE_IGNORE) as SaveData
	if verify == null:
		push_error("SaveManager: tmp verification failed for slot %d, aborting commit" % slot_index)
		_safe_remove(tmp)
		return false

	if FileAccess.file_exists(base):
		if not _safe_rename(base, bak):
			_safe_remove(tmp)
			return false

	if not _safe_rename(tmp, base):
		push_error("SaveManager: failed committing save for slot %d" % slot_index)
		if FileAccess.file_exists(bak):
			_safe_rename(bak, base)
		return false

	print_debug("Saved slot ", slot_index)
	save_changed.emit(slot_index)
	SteamCloudSave.upload(_cloud_filename(slot_index), base)
	return true


func _build_save(slot_index: int, is_auto: bool) -> SaveData:
	var data: SaveData = SaveData.new()
	data.save_version = CURRENT_SAVE_VERSION
	data.slot_index = slot_index
	data.is_auto_save = is_auto
	data.save_timestamp = int(Time.get_unix_time_from_system())

	# TODO Check how to decouple this
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	player.player_save_controller.build_save(data.player)
	WorldSaveController.build_save(data.world)
	LevelChunkManager.build_save(data.chunks)
	CheckpointSaveController.build_save(data.checkpoint)

	return data


func _on_player_spawned_after_load(spawned_player: Node3D) -> void:
	GameEvents.player_spawned.disconnect(_on_player_spawned_after_load)
	var player: PlayerEntity = spawned_player as PlayerEntity
	CheckpointSaveController.on_player_spawned_after_load(player)


func _apply(data: SaveData) -> void:
	# TODO Check how to decouple this
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	player.player_save_controller.apply_save(data.player)
	WorldSaveController.apply_save(data.world)
	LevelChunkManager.apply_save(data.chunks)
	CheckpointSaveController.apply_save(data.checkpoint, player)

	# If player not yet spawned, hook into spawn signal for deferred placement
	if not player or not is_instance_valid(player):
		GameEvents.player_spawned.connect(_on_player_spawned_after_load)
	else:
		# Player already exists, apply immediately
		CheckpointSaveController.on_player_spawned_after_load(player)


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


func _sync_cloud_saves() -> void:
	for i: int in range(TOTAL_SLOTS):
		var cloud_name: String = _cloud_filename(i)
		if SteamCloudSave.remote_is_newer(cloud_name, _slot_path(i)):
			SteamCloudSave.download(cloud_name, _slot_path(i))


func _cloud_filename(slot_index: int) -> String:
	return "slot_%d.tres" % slot_index
#endregion
