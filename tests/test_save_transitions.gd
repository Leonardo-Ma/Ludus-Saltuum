extends ProjectTest

## Exercises save and load across gameplay and application menus in isolated profile

const PLAYER_SCENE: PackedScene = preload("uid://dwxbechemu2kl") # player.tscn
const NEW_GAME_BUTTON: GDScript = preload("uid://b8xklo3ubuprp") # new_game.gd
const MANUAL_SLOT: int = SaveManager.MANUAL_SLOTS - 1
const AUTOSAVE_SLOT: int = SaveManager.MANUAL_SLOTS


func run_tests() -> void:
	var music_state_changed: Callable = MusicCoordinator._on_game_state_changed
	ApplicationStateManager.state_changed.disconnect(music_state_changed)
	MusicController.stop(0.0)

	var world: Node = Node.new()
	world.name = "Main"
	var player: PlayerEntity = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.owner = world
	get_tree().root.add_child(world)
	await get_tree().process_frame

	ChunkManager.stage_new_game_seed(4802)
	assert(SaveManager.initialize_new_save(MANUAL_SLOT), "New game failed in " + name)
	ApplicationStateManager.request_play_from_save()
	_test_invalid_loads(player)
	_test_quit_destinations(player)
	_test_legacy_manual_save(player)

	ApplicationStateManager.main_menu_requested.connect(_on_main_menu_requested, CONNECT_ONE_SHOT)
	ApplicationStateManager.request_main_menu()
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.SETTINGS)
	assert(not SaveManager.save_to_quick_slot(), "Settings over main menu enabled saving in " + name)
	ApplicationStateManager.request_close_menu()
	ChunkManager.clear_level()
	world.queue_free()
	await get_tree().process_frame
	ApplicationStateManager.state_changed.connect(music_state_changed)


func _test_invalid_loads(player: PlayerEntity) -> void:
	var snapshot: SaveData = SaveManager._build_save_data(AUTOSAVE_SLOT, true)
	var live_chunk: LevelChunk = ChunkManager.get_active_chunks()[0]
	var live_transform: Transform3D = player.global_transform
	snapshot.player.gold = 200
	snapshot.world.collected_collectible_ids[&"rejected_load"] = true
	snapshot.chunks.generation_version = -1
	_assert_rejected(snapshot)
	snapshot.chunks.generation_version = ChunkManager.GENERATION_VERSION

	var chunk_key: int = snapshot.chunks.active_chunk_keys[0]
	var original_uid: String = snapshot.chunks.chunk_key_to_scene_uid[chunk_key]
	snapshot.chunks.chunk_key_to_scene_uid[chunk_key] = "uid://invalid"
	_assert_rejected(snapshot)
	snapshot.chunks.chunk_key_to_scene_uid[chunk_key] = original_uid

	for active_key: int in snapshot.chunks.active_chunk_keys:
		snapshot.chunks.scored_chunk_keys[active_key] = true
	_assert_rejected(snapshot)
	snapshot.chunks.scored_chunk_keys.clear()

	snapshot.checkpoint.has_checkpoint_position = true
	snapshot.checkpoint.checkpoint_chunk_index = CheckpointSaveData.WORLD_CHECKPOINT_INDEX - 1
	_assert_rejected(snapshot)
	snapshot.checkpoint.checkpoint_chunk_index = snapshot.chunks.active_chunk_keys.size()
	_assert_rejected(snapshot)
	assert(ChunkManager.get_active_chunks()[0] == live_chunk, "Failed load replaced live route in " + name)
	assert(player.global_transform == live_transform and player.economy_controller.gold == 0, "Failed load changed player in " + name)
	assert(not WorldSaveController.is_collectible_collected(&"rejected_load"), "Failed load changed world in " + name)
	assert(SaveManager.save_to_quick_slot(), "Failed load changed manual destination in " + name)
	assert(SaveManager.get_slot_data(MANUAL_SLOT).player.gold == 0, "Manual slot was not written in " + name)

	snapshot.save_timestamp += 10
	assert(ResourceSaver.save(snapshot, SaveManager._slot_path(AUTOSAVE_SLOT)) == OK, "Could not write menu fixture in " + name)
	ApplicationStateManager.request_main_menu()
	var button: UIButton = NEW_GAME_BUTTON.new()
	button._button_pressed()
	button.free()
	assert(ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.MAIN_MENU), "Failed load started gameplay in " + name)


func _assert_rejected(snapshot: SaveData) -> void:
	assert(ResourceSaver.save(snapshot, SaveManager._slot_path(AUTOSAVE_SLOT)) == OK, "Could not write invalid snapshot in " + name)
	assert(not SaveManager.load_from_slot(AUTOSAVE_SLOT), "Invalid snapshot loaded in " + name)
	assert(not SaveManager.is_save_blocked(), "Failed load left saving blocked in " + name)


func _test_quit_destinations(player: PlayerEntity) -> void:
	assert(SaveManager.initialize_new_save(MANUAL_SLOT), "Could not restart gameplay in " + name)
	ApplicationStateManager.request_play_from_save()
	player.economy_controller.gold = 10
	SaveManager._next_auto_slot = 0
	SaveManager._on_auto_save()
	var snapshot: SaveData = SaveManager.get_slot_data(AUTOSAVE_SLOT)
	assert(snapshot.manual_slot_index == MANUAL_SLOT and snapshot.player.gold == 10, "Autosave lost manual destination in " + name)
	snapshot.checkpoint.has_checkpoint_position = true
	snapshot.checkpoint.checkpoint_chunk_index = 0
	snapshot.checkpoint.checkpoint_local_transform.origin = Vector3(0, 5, 0)
	assert(ResourceSaver.save(snapshot, SaveManager._slot_path(AUTOSAVE_SLOT)) == OK, "Could not add checkpoint fixture in " + name)

	ApplicationStateManager.request_pause()
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.SAVE_MENU)
	CheckpointManager.checkpoint_loaded.connect(_on_checkpoint_loaded, CONNECT_ONE_SHOT)
	assert(SaveManager.load_from_slot(AUTOSAVE_SLOT), "Autosave could not resume in " + name)
	assert(player.global_transform.is_equal_approx(CheckpointManager.get_respawn_transform()), "Player missed restored checkpoint in " + name)
	assert(CheckpointManager.get_checkpoint_chunk_index() == 0, "First chunk checkpoint rejected in " + name)
	ApplicationStateManager.request_play_from_save()
	ApplicationStateManager.request_pause()

	player.economy_controller.gold = 20
	ApplicationStateManager.quit_requested.emit()
	assert(SaveManager.get_slot_data(MANUAL_SLOT).player.gold == 20, "Quit from Pause missed manual slot in " + name)
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.SETTINGS)
	player.economy_controller.gold = 30
	ApplicationStateManager.quit_requested.emit()
	assert(SaveManager.get_slot_data(MANUAL_SLOT).player.gold == 30, "Quit from Settings missed manual slot in " + name)
	assert(SaveManager.get_slot_data(AUTOSAVE_SLOT).player.gold == 10, "Quit overwrote rotating autosave in " + name)

	player.economy_controller.gold = 40
	SaveManager.request_save_block(&"player_respawning")
	ApplicationStateManager.quit_requested.emit()
	SaveManager.release_save_block(&"player_respawning")
	assert(SaveManager.get_slot_data(MANUAL_SLOT).player.gold == 30, "Quit saved an incomplete respawn in " + name)

	var quick_save: InputEventAction = InputEventAction.new()
	quick_save.action = &"quick_save"
	quick_save.pressed = true
	SaveManager._unhandled_input(quick_save)
	assert(SaveManager.get_slot_data(MANUAL_SLOT).player.gold == 40, "Quick save missed manual slot in " + name)

	snapshot.manual_slot_index = -1
	snapshot.checkpoint.checkpoint_chunk_index = CheckpointSaveData.WORLD_CHECKPOINT_INDEX
	var world_position: Vector3 = Vector3(18, 5, -12)
	snapshot.checkpoint.checkpoint_local_transform.origin = world_position
	var auto_path: String = SaveManager._slot_path(AUTOSAVE_SLOT)
	assert(ResourceSaver.save(snapshot, auto_path) == OK, "Could not write legacy autosave in " + name)
	assert(not FileAccess.get_file_as_string(auto_path).contains("manual_slot_index"), "Legacy fixture contains manual slot field in " + name)
	assert(SaveManager.get_slot_data(AUTOSAVE_SLOT).manual_slot_index == -1, "Missing manual slot field did not default to -1 in " + name)
	assert(SaveManager.load_from_slot(AUTOSAVE_SLOT), "Legacy autosave could not resume in " + name)
	assert(CheckpointManager.has_active_checkpoint() and player.global_position == world_position, "World checkpoint was not restored in " + name)
	assert(SaveManager.save_to_quick_slot(), "Legacy autosave did not establish a manual destination in " + name)
	assert(SaveManager.get_slot_data(SaveManager.FIRST_MANUAL_SLOT).player.gold == 10, "Legacy autosave missed first manual slot in " + name)


func _on_checkpoint_loaded(_position: Vector3) -> void:
	assert(SaveManager.is_save_blocked(), "Saving was enabled during checkpoint restore in " + name)
	assert(not SaveManager.save_to_quick_slot(true), "Forced save bypassed load block in " + name)


func _on_main_menu_requested() -> void:
	assert(not SaveManager.save_to_quick_slot(), "Saving was enabled during main menu reset in " + name)


func _test_legacy_manual_save(player: PlayerEntity) -> void:
	var slot_index: int = SaveManager.FIRST_MANUAL_SLOT
	var error: Error = DirAccess.copy_absolute("res://tests/saves/slot_0.tres", SaveManager._slot_path(slot_index))
	assert(error == OK, "Could not stage version 1 save in " + name)
	assert(SaveManager.load_from_slot(slot_index), "Could not restore version 1 save in " + name)
	assert(player.economy_controller.gold == 70, "Version 1 player data was not restored in " + name)
	assert(player.global_transform.is_equal_approx(CheckpointManager.get_respawn_transform()), "Version 1 checkpoint was not restored in " + name)
