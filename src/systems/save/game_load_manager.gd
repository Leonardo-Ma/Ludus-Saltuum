# TODO To confirm, as this works as integration, may not make sense to decouple from the systems it uses
extends Node

var _pending_player_data: PlayerSaveData
var _player: PlayerEntity = null
var _load_applied: bool = false


func _ready() -> void:
	SaveManager.reset_finished.connect(_on_reset_finished)
	SaveManager.load_requested.connect(_on_load_requested)
	CheckpointManager.load_applied.connect(_on_checkpoint_load_applied)
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_finished_spawning)


func _on_reset_finished() -> void:
	LevelChunkManager.initialize_level()


func _on_load_requested(data: SaveData) -> void:
	_pending_player_data = data.player
	_load_applied = false
	_player = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	_try_finish_load()


func _on_checkpoint_load_applied() -> void:
	if _pending_player_data == null:
		return
	_load_applied = true
	_try_finish_load()


func _on_player_finished_spawning(player: PlayerEntity) -> void:
	if _pending_player_data == null:
		return
	_player = player
	_try_finish_load()


func _try_finish_load() -> void:
	if _player == null or not _load_applied:
		return

	_player.player_save_controller.apply_save_data(_pending_player_data)

	if CheckpointManager.has_active_checkpoint():
		_player.global_transform = CheckpointManager.get_respawn_transform()
	else:
		_player.global_transform = CheckpointManager.get_default_spawn_transform()

	_player.finish_load()

	_pending_player_data = null
	_player = null
	_load_applied = false
	SaveManager.release_save_block(&"loading")
