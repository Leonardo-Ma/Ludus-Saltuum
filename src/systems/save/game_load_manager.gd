# TODO To confirm, as this works as integration, may not make sense to decouple from the systems it uses
extends Node

## Preflights snapshots and applies sections in dependency order


func apply_save_data(data: SaveData) -> bool:
	var player: PlayerEntity = get_tree().get_first_node_in_group(Groups.PLAYERS)
	if player == null or not player.is_node_ready():
		return false
	if data.player.health <= 0 or data.player.score < 0 or data.player.gold < 0:
		return false
	if not CheckpointSaveController.can_apply_save_data(data.checkpoint, data.chunks.active_chunk_keys):
		return false

	var chunks: Array[LevelChunk] = ChunkManager.prepare_saved_chunks(data.chunks)
	if chunks.is_empty():
		return false

	CheckpointManager.reset_checkpoint()
	WorldSaveController.apply_save_data(data.world)
	ChunkManager.restore_level(data.chunks, chunks, player)
	WorldSaveController.apply_saved_entity_states()
	CheckpointSaveController.apply_save_data(data.checkpoint, data.chunks.active_chunk_keys)

	if player.vehicle_rider.is_in_vehicle:
		player.vehicle_rider.vehicle.exit(player.global_position)

	player.revive()
	player.player_save_controller.apply_save_data(data.player)
	player.global_transform = CheckpointManager.get_respawn_transform()
	player.finish_load()

	GameplayStateManager.set_play_time(data.play_time_seconds)
	return true
