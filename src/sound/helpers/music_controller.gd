extends Node

## Coordinates music state, track selection, playback, and crossfades
## References music catalog resource

signal track_changed(track_name: String, author: String)

enum MusicState {
	MAIN_MENU = 0,
	EXPLORATION = 1,
	RACING = 2,
	COMBAT = 3,
	MAZE = 4,
	SILENCE = 5,
	OUTER_SPACE = 6,
}

const _MUTED_VOLUME_DB: float = -80.0
const _MUSIC_CATALOG: MusicCatalog = preload("uid://c2prli518odbi") # music_catalog.tres

var _current_state: MusicState = MusicState.SILENCE
var _current_track: MusicTrack

var _current_player: AudioStreamPlayer
var _staging_player: AudioStreamPlayer

var _fade_tween: Tween
var _crossfade_duration: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_current_player = _create_music_player()
	_staging_player = _create_music_player()


#region Public API

func play(track: MusicTrack) -> void:
	assert(track != null, "MusicController received null track in " + name)
	assert(track.stream != null, "Music track has no stream in " + name)

	if _current_track == track and _current_player.playing:
		return

	_stop_fade()
	_disconnect_finished()

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
	_fade_tween.tween_callback(_staging_player.stop)


## Changes current music state and optionally selects track by resource name
func set_state(new_state: MusicState, track_key: String = "") -> void:
	if new_state == _current_state and track_key.is_empty():
		return

	if new_state == MusicState.SILENCE:
		stop()
		return

	var playlist: MusicPlaylist = _get_playlist(new_state)
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
	_disconnect_finished()

	_current_state = MusicState.SILENCE
	_current_track = null

	_staging_player.stop()
	_staging_player.volume_db = _MUTED_VOLUME_DB

	if not _current_player.playing:
		return

	if fade_duration <= 0.0:
		_current_player.stop()
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(_current_player, "volume_db", _MUTED_VOLUME_DB, fade_duration)
	_fade_tween.tween_callback(_current_player.stop)


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

func _create_music_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.bus = AudioManager.BUS_NAMES[AudioManager.SoundBus.MUSIC]
	player.volume_db = _MUTED_VOLUME_DB
	add_child(player)
	return player


func _get_playlist(state: MusicState) -> MusicPlaylist:
	var playlist: MusicPlaylist

	match state:
		MusicState.MAIN_MENU:
			playlist = _MUSIC_CATALOG.main_menu
		MusicState.EXPLORATION:
			playlist = _MUSIC_CATALOG.exploration
		MusicState.RACING:
			playlist = _MUSIC_CATALOG.racing
		MusicState.COMBAT:
			playlist = _MUSIC_CATALOG.combat
		MusicState.MAZE:
			playlist = _MUSIC_CATALOG.maze
		MusicState.OUTER_SPACE:
			playlist = _MUSIC_CATALOG.outer_space
		_:
			assert(false, "Unsupported music state in " + name)

	assert(playlist != null, "Music playlist not assigned in catalog for " + MusicState.find_key(state) + " in " + name)
	return playlist


func _on_track_finished() -> void:
	var playlist: MusicPlaylist = _get_playlist(_current_state)
	var next_track: MusicTrack = playlist.pick_next_track(_current_track)
	assert(next_track != null, "No music tracks available for state in " + name)

	play(next_track)


func _disconnect_finished() -> void:
	if _current_player.finished.is_connected(_on_track_finished):
		_current_player.finished.disconnect(_on_track_finished)


func _stop_fade() -> void:
	if _fade_tween:
		_fade_tween.kill()
		_fade_tween = null

#endregion
