# BUG Some audios' volume decreases and increases wrongly
class_name SoundPool
extends Node

## Max simultaneous sounds
const CATEGORY_LIMITS: Dictionary = {
	SoundManager.SoundCategory.MUSIC: 1,
	SoundManager.SoundCategory.SFX: 10,
	SoundManager.SoundCategory.AMBIENT: 4,
	SoundManager.SoundCategory.UI: 3,
	SoundManager.SoundCategory.VOICE: 5,
	SoundManager.SoundCategory.VEHICLE: 4,
}

## Audio buses (match these to Audio tab setup)
const BUSES: Dictionary = SoundManager.BUS_NAMES

## Pools: category -> Array of available players
var _pools: Dictionary = {}
## Active players: category -> Array of currently playing players
var _active_players: Dictionary = {}


func _ready() -> void:
	_setup_pools()


func _setup_pools() -> void:
	for category: int in CATEGORY_LIMITS:
		_pools[category] = [] as Array[Node]
		_active_players[category] = [] as Array[Node]

		var limit: int = CATEGORY_LIMITS[category]
		for i: int in range(limit):
			var player: Node = _create_player_for_category(category)
			add_child(player)
			_pools[category].append(player)


func _create_player_for_category(category: int) -> Node:
	assert(BUSES.has(category), "SoundPool: missing bus in " + name)

	var player: Node

	# Use 3D players for positional sounds
	match category:
		SoundManager.SoundCategory.SFX, SoundManager.SoundCategory.AMBIENT, SoundManager.SoundCategory.VOICE, SoundManager.SoundCategory.VEHICLE:
			player = AudioStreamPlayer3D.new()
			player.unit_size = 15.0
			player.max_distance = 200.0

		_:  # MUSIC, UI
			player = AudioStreamPlayer.new()

	player.set("bus", BUSES[category])
	return player


func play_sound(sound: AudioStream, category: int, position: Vector3 = Vector3.ZERO) -> Variant:
	var player: Variant = _get_available_player(category)
	if player == null:
		player = _replace_oldest_sound(category)
		if player == null:
			return null

	if player.finished.is_connected(_on_sound_finished):
		player.finished.disconnect(_on_sound_finished)

	player.stream = sound
	player.pitch_scale = 1.0
	player.stream_paused = false  # Reset paused state

	if player is AudioStreamPlayer3D:
		if position != Vector3.ZERO:
			(player as AudioStreamPlayer3D).global_position = position
			(player as AudioStreamPlayer3D).attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		else:
			# If no position is provided, disable distance attenuation so it's heard cleanly everywhere like UI/Music
			(player as AudioStreamPlayer3D).attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED

	player.play()
	_active_players[category].append(player as Node)

	player.finished.connect(_on_sound_finished.bind(player, category), CONNECT_ONE_SHOT)

	return player


func _get_available_player(category: int) -> Variant:
	# Return type is inferred (will be AudioStreamPlayer or AudioStreamPlayer3D)
	if _pools[category].is_empty():
		return null
	return _pools[category].pop_back()


func _replace_oldest_sound(category: int) -> Variant:
	if _active_players[category].is_empty():
		return null

	var oldest: Variant = _active_players[category].pop_front()

	if oldest.finished.is_connected(_on_sound_finished):
		oldest.finished.disconnect(_on_sound_finished)

	oldest.stop()
	oldest.stream = null
	return oldest


func _on_sound_finished(player: Variant, category: int) -> void:
	var idx: int = _active_players[category].find(player as Node)
	if idx != -1:
		_active_players[category].remove_at(idx)

	player.stream = null
	_pools[category].append(player as Node)

	# Note: Signal already auto-disconnected due to CONNECT_ONE_SHOT


func pause_category(category: int, paused: bool) -> void:
	for player: Variant in _active_players[category]:
		if paused:
			player.stream_paused = true
		else:
			player.stream_paused = false


func stop_category(category: int) -> void:
	for player: Variant in _active_players[category]:
		if player.finished.is_connected(_on_sound_finished):
			player.finished.disconnect(_on_sound_finished)

		player.stop()
		player.stream = null
		_pools[category].append(player as Node)
	_active_players[category].clear()


func get_active_sound_count(category: int) -> int:
	return _active_players[category].size()


func is_category_full(category: int) -> bool:
	return _active_players[category].size() >= CATEGORY_LIMITS[category]
