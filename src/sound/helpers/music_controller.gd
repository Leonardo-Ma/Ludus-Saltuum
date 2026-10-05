## Coordinates music state, track selection, playback, and crossfades
## References music catalog resource
extends Node

signal track_changed(track_name: String, author: String)

enum MusicState {
	MAIN_MENU = 0,
	EXPLORATION = 1,
	RACING = 2,
	COMBAT = 3,
	MAZE = 4,
	SILENCE = 5,
}

const _MUTED_VOLUME_DB: float = -80.0
const _MUSIC_BUS_NAME: String = "Music"
const _MUSIC_CATALOG: MusicCatalog = preload("uid://c2prli518odbi")

var _music_catalog: MusicCatalog = _MUSIC_CATALOG

var _current_state: MusicState = MusicState.SILENCE
var _current_track: MusicTrack

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _current_player: AudioStreamPlayer
var _staging_player: AudioStreamPlayer

var _fade_tween: Tween
var _crossfade_duration: float = 1.0


func _ready() -> void:
	_create_music_players()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _create_music_players() -> void:
	assert(_player_a == null, "Music players already initialized in " + name)

	_player_a = AudioStreamPlayer.new()
	_player_a.bus = _MUSIC_BUS_NAME
	_player_a.volume_db = _MUTED_VOLUME_DB
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = _MUSIC_BUS_NAME
	_player_b.volume_db = _MUTED_VOLUME_DB
	add_child(_player_b)

	_current_player = _player_a
	_staging_player = _player_b

#region Public API

func play(track: MusicTrack) -> void:
	assert(track != null, "MusicController received null track in " + name)
	assert(track.stream != null, "Music track has no stream in " + name)

	if _current_track == track and _current_player.playing:
		return

	_stop_fade()

	if _current_player.finished.is_connected(_on_track_finished):
		_current_player.finished.disconnect(_on_track_finished)

	var old_player: AudioStreamPlayer = _current_player
	_current_player = _staging_player
	_staging_player = old_player

	_current_player.stop()
	_current_player.stream = track.stream
	_current_player.volume_db = _MUTED_VOLUME_DB
	_current_player.play()
	_current_player.finished.connect(_on_track_finished, CONNECT_ONE_SHOT)

	_current_track = track
	track_changed.emit(track.song_name, track.author)

	if _crossfade_duration <= 0.0:
		_staging_player.stop()
		_current_player.volume_db = 0.0
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(_current_player, "volume_db", 0.0, _crossfade_duration)
	_fade_tween.parallel().tween_property(_staging_player, "volume_db", _MUTED_VOLUME_DB, _crossfade_duration)
	_fade_tween.tween_callback(
		func() -> void:
			_staging_player.stop(),
	)


## Changes current music state and optionally selects track by resource name
func set_state(new_state: MusicState, track_key: String = "") -> void:
	if new_state == _current_state and track_key.is_empty():
		return

	if new_state == MusicState.SILENCE:
		_current_state = new_state
		_current_track = null
		stop()
		return

	var playlist: MusicPlaylist = _get_playlist(new_state)
	assert(playlist != null, "Music playlist missing for state in " + name)

	var track: MusicTrack

	if not track_key.is_empty():
		track = playlist.get_track_by_key(track_key)
		assert(track != null, "Track key '" + track_key + "' not found in music playlist in " + name)
		playlist.consume_track(track)
	else:
		track = playlist.pick_next_track(_current_track)
		assert(track != null, "No music tracks available for state in " + name)

	_current_state = new_state

	play(track)


func stop(fade_duration: float = 1.0) -> void:
	_stop_fade()

	if _current_player.finished.is_connected(_on_track_finished):
		_current_player.finished.disconnect(_on_track_finished)

	_staging_player.stop()
	_staging_player.volume_db = _MUTED_VOLUME_DB

	if not _current_player.playing:
		_current_track = null
		return

	if fade_duration <= 0.0:
		_current_player.stop()
		_current_track = null
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(_current_player, "volume_db", _MUTED_VOLUME_DB, fade_duration)
	_fade_tween.tween_callback(
		func() -> void:
			_current_player.stop()
			_current_track = null,
	)


func set_crossfade_duration(duration: float) -> void:
	assert(duration >= 0.0, "Invalid crossfade duration in " + name)
	_crossfade_duration = duration


func get_current_track() -> MusicTrack:
	return _current_track


func get_current_track_name() -> String:
	if _current_track == null:
		return ""

	return _current_track.song_name


func get_current_track_author() -> String:
	if _current_track == null:
		return ""

	return _current_track.author

#endregion

#region Private helpers

func _get_playlist(state: MusicState) -> MusicPlaylist:
	match state:
		MusicState.MAIN_MENU:
			return _music_catalog.main_menu
		MusicState.EXPLORATION:
			return _music_catalog.exploration
		MusicState.RACING:
			return _music_catalog.racing
		MusicState.COMBAT:
			return _music_catalog.combat
		MusicState.MAZE:
			return _music_catalog.maze
		MusicState.SILENCE:
			return null

	assert(false, "Unsupported music state in " + name)
	return null


func _on_track_finished() -> void:
	var playlist: MusicPlaylist = _get_playlist(_current_state)

	if playlist == null:
		_current_track = null
		return

	var next_track: MusicTrack = playlist.pick_next_track(_current_track)

	if next_track == null:
		return

	play(next_track)


func _stop_fade() -> void:
	if _fade_tween:
		_fade_tween.kill()
		_fade_tween = null

#endregion
