extends Node

var _pending_player_data: PlayerSaveData
var _is_loading: bool = false


func _ready() -> void:
	SaveManager.load_requested.connect(_on_load_requested)
	GameEvents.player_finished_spawning.connect(_on_player_finished_spawning)


func _on_load_requested(data: SaveData) -> void:
	_pending_player_data = data.player
	_is_loading = true

	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS) as PlayerEntity
	if player != null:
		_finish_player_load(player)


func _on_player_finished_spawning(player: PlayerEntity) -> void:
	if _is_loading:
		_finish_player_load(player)


func _finish_player_load(player: PlayerEntity) -> void:
	player.player_save_controller.apply_save(_pending_player_data)

	# TODO Refactor this condition and the 3 player assigns below to a GameEvents request spawn?
	if CheckpointManager.has_active_checkpoint():
		player.global_transform = CheckpointManager.get_respawn_transform()
	else:
		player.global_transform = CheckpointManager.get_default_spawn_transform()

	player.finish_load()

	_pending_player_data = null
	_is_loading = false
	SaveManager.release_save_block(&"loading")
