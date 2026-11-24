extends ProjectTest

## Exercises save and load across gameplay and application menus in isolated profile

const PLAYER_SCENE: PackedScene = preload("uid://dwxbechemu2kl") # player.tscn
const NEW_GAME_BUTTON: GDScript = preload("uid://b8xklo3ubuprp") # new_game.gd
const COIN_SCENE: PackedScene = preload("uid://be65x13d4tlnt") # gold_coin.tscn
const MAGE_SCENE: PackedScene = preload("uid://bylcq0tsjv7o4") # skeleton_mage.tscn
const CHECKPOINT_SCENE: PackedScene = preload("uid://bhbjsqv8pu1x8") # checkpoint_flag.tscn
const MANUAL_SLOT: int = SaveManager.MANUAL_SLOTS - 1
const AUTOSAVE_SLOT: int = SaveManager.MANUAL_SLOTS


func run_tests() -> void:
	var music_state_changed: Callable = MusicCoordinator._on_game_state_changed
	ApplicationStateManager.state_changed.disconnect(music_state_changed)
	MusicController.stop(0.0)

	var world: Node = Node.new()
	world.name = "SaveTestWorld"
	var chunk_container: LevelChunkContainer = LevelChunkContainer.new()
	chunk_container.position = Vector3(12, 4, 21)
	world.add_child(chunk_container)
	chunk_container.owner = world
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
	await _test_recycled_route(player, world)
	await _test_world_states(world)

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
	snapshot.checkpoint.checkpoint_chunk_index = 0
	snapshot.checkpoint.checkpoint_chunk_key = snapshot.chunks.next_chunk_key
	_assert_rejected(snapshot)
	snapshot.checkpoint.checkpoint_chunk_key = CheckpointSaveData.WORLD_CHECKPOINT_KEY
	snapshot.chunks.first_chunk_transform.basis = Basis.from_scale(Vector3.ZERO)
	_assert_rejected(snapshot)
	snapshot.chunks.first_chunk_transform.basis = Basis.IDENTITY
	snapshot.checkpoint.checkpoint_chunk_key = snapshot.chunks.next_chunk_key
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
	assert(CheckpointManager.get_checkpoint_chunk_key() == snapshot.chunks.active_chunk_keys[0], "First chunk checkpoint rejected in " + name)
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


func _test_recycled_route(player: PlayerEntity, world: Node) -> void:
	var fixture: SaveData = SaveManager._build_save_data(MANUAL_SLOT, false)
	fixture.checkpoint.has_checkpoint_position = false
	fixture.chunks.has_first_chunk_transform = false
	fixture.chunks.active_chunk_keys = [0, 1, 2]
	fixture.chunks.next_chunk_key = 3
	fixture.chunks.scored_chunk_keys = { }
	fixture.chunks.chunk_key_to_scene_uid = {
		0: "uid://pj23j5mj4bnh", # 04_short_grass_right.tscn
		1: "uid://dj2polxcruojl", # 01_grass.tscn
		2: "uid://dokj03gad5hdg", # 07_dungeon.tscn
	}
	assert(GameLoadManager.apply_save_data(fixture), "Could not stage turn in " + name)
	var first_survivor: LevelChunk = ChunkManager.get_chunk_by_key(1)
	var chunk_checkpoint: Checkpoint = first_survivor.get_node("GrassPlatform19/Checkpoint")
	var coin: Collectible = first_survivor.get_node("GrassPlatform17/GoldCoin")
	var enemy: NPCEntity = ChunkManager.get_chunk_by_key(2).get_node("Barbarian")
	var coin_id: StringName = coin.collectible_id
	var enemy_id: StringName = enemy.enemy_id
	var retired_planner: WeakRef = weakref(enemy.goap_agent._action_planner)
	assert(coin_id != &"" and enemy_id != &"", "Procedural entities entered with missing IDs in " + name)
	CheckpointManager.on_checkpoint_activated(chunk_checkpoint)
	ChunkManager.recycle_oldest_chunk()
	var survivor_transform: Transform3D = first_survivor.global_transform
	var next_transform: Transform3D = ChunkManager.get_chunk_by_key(2).global_transform
	var checkpoint_transform: Transform3D = CheckpointManager.get_respawn_transform()
	assert(not survivor_transform.basis.is_equal_approx(Basis.IDENTITY), "Turn fixture did not rotate surviving chunk in " + name)
	assert(CheckpointManager.get_checkpoint_chunk_key() == 1, "Recycling changed surviving checkpoint key in " + name)

	var static_checkpoint: Checkpoint = CHECKPOINT_SCENE.instantiate()
	static_checkpoint.position = Vector3(18, 5, -12)
	world.add_child(static_checkpoint)
	CheckpointManager.on_checkpoint_activated(static_checkpoint)
	var static_snapshot: SaveData = SaveManager._build_save_data(MANUAL_SLOT, false)
	static_snapshot.world.collected_collectible_ids[coin_id] = true
	static_snapshot.world.killed_enemy_ids[enemy_id] = true
	assert(GameLoadManager.apply_save_data(static_snapshot), "Static checkpoint restore failed in " + name)
	assert(player.global_position.is_equal_approx(static_checkpoint.global_position), "Static checkpoint moved with route in " + name)
	assert(ChunkManager.get_chunk_by_key(1).global_transform.is_equal_approx(survivor_transform), "Static checkpoint load moved route in " + name)

	first_survivor = ChunkManager.get_chunk_by_key(1)
	coin = first_survivor.get_node("GrassPlatform17/GoldCoin")
	enemy = ChunkManager.get_chunk_by_key(2).get_node("Barbarian")
	assert(coin.collectible_id == coin_id and coin.collected, "Reload missed collected procedural coin in " + name)
	assert(enemy.enemy_id == enemy_id and enemy.health.current_health == 0, "Reload missed killed procedural enemy in " + name)
	await get_tree().process_frame
	assert(retired_planner.get_ref() == null, "Reload leaked retired enemy planner in " + name)
	chunk_checkpoint = first_survivor.get_node("GrassPlatform19/Checkpoint")
	CheckpointManager.on_checkpoint_activated(chunk_checkpoint)
	chunk_checkpoint.save_checkpoint_to_disk = false
	var chunk_snapshot: SaveData = SaveManager._build_save_data(MANUAL_SLOT, false)
	assert(CheckpointManager.has_active_checkpoint(), "Runtime-only checkpoint was deactivated in " + name)
	assert(not chunk_snapshot.checkpoint.has_checkpoint_position, "Runtime-only checkpoint was serialized in " + name)
	chunk_checkpoint.save_checkpoint_to_disk = true
	chunk_snapshot = SaveManager._build_save_data(MANUAL_SLOT, false)
	assert(chunk_snapshot.checkpoint.checkpoint_chunk_key == 1, "Snapshot missed stable checkpoint key in " + name)
	assert(ResourceSaver.save(chunk_snapshot, SaveManager._slot_path(MANUAL_SLOT)) == OK, "Could not save recycled route in " + name)
	assert(SaveManager.load_from_slot(MANUAL_SLOT), "Could not reload recycled route in " + name)
	assert(ChunkManager.get_chunk_by_key(1).global_transform.is_equal_approx(survivor_transform), "Reload moved first survivor in " + name)
	assert(ChunkManager.get_chunk_by_key(2).global_transform.is_equal_approx(next_transform), "Reload moved following chunk in " + name)
	assert(player.global_transform.is_equal_approx(checkpoint_transform), "Reload moved chunk checkpoint in " + name)
	ChunkManager.recycle_oldest_chunk()
	assert(not CheckpointManager.has_active_checkpoint(), "Recycled checkpoint remained active in " + name)


func _test_world_states(world: Node) -> void:
	var coin: Collectible = COIN_SCENE.instantiate()
	coin.is_procedurally_spawned = false
	coin.static_id = &"test_coin"
	world.add_child(coin)
	var mage: NPCEntity = MAGE_SCENE.instantiate()
	mage.is_procedurally_spawned = false
	mage.static_id = &"test_mage"
	world.add_child(mage)
	assert(WorldSaveController.has_valid_entity_ids(), "Authored entities have invalid identities in " + name)
	coin.static_id = &""
	assert(not WorldSaveController.has_valid_entity_ids(), "Empty authored ID passed validation in " + name)
	coin.static_id = mage.static_id
	assert(not WorldSaveController.has_valid_entity_ids(), "Duplicate authored ID passed validation in " + name)
	coin.static_id = coin.collectible_id

	var alive: SaveData = SaveManager._build_save_data(MANUAL_SLOT, false)
	var consumed: SaveData = SaveManager._build_save_data(MANUAL_SLOT, false)
	consumed.world.collected_collectible_ids[coin.collectible_id] = true
	consumed.world.killed_enemy_ids[mage.enemy_id] = true
	mage.health.current_health = 0
	mage.health.died.emit()
	assert(WorldSaveController.is_enemy_killed(mage.enemy_id), "Death was missing during its animation in " + name)
	assert(GameLoadManager.apply_save_data(alive), "Alive snapshot failed during death animation in " + name)
	assert(mage.visible and mage.health.current_health == mage.health.max_health, "Interrupted death did not revive enemy in " + name)
	assert(GameLoadManager.apply_save_data(consumed), "Consumed snapshot failed in " + name)
	await get_tree().process_frame
	assert(coin.collected and not coin.visible, "Collected coin was visible in " + name)
	assert(not coin.monitoring and mage.collision_shape.disabled and not mage.hurtbox.monitoring, "Consumed entities could still collide in " + name)
	assert(not mage.visible and mage.health.current_health == 0 and not mage.is_physics_processing(), "Killed enemy remained active in " + name)
	assert(GameLoadManager.apply_save_data(alive), "Alive snapshot failed in " + name)
	await get_tree().process_frame
	assert(not coin.collected and coin.visible, "Loading missed uncollected coin in " + name)
	assert(
		mage.visible and mage.health.current_health == mage.health.max_health and mage.is_physics_processing(),
		"Loading missed alive enemy in " + name,
	)
	assert(coin.monitoring and not mage.collision_shape.disabled and mage.hurtbox.monitoring, "Restored entities cannot interact in " + name)
	assert(GameLoadManager.apply_save_data(consumed), "Second consumed snapshot failed in " + name)
	WorldSaveController.initialize_new_save_data()
	assert(not coin.collected and coin.visible and mage.visible, "Reset missed consumed entities in " + name)
