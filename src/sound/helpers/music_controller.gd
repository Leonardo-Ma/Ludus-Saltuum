# TODO: Improve methods and variables names
## Dual player music controller for fade in out effect
class_name MusicController
extends Node

signal track_changed(track_name: String, author: String)

enum MusicState {
	MAIN_MENU,
	EXPLORATION,
	RACING,
	COMBAT,
	MAZE,
	SILENCE,
}
# TODO Maybe an export instead?
const _TRANSITION_COOLDOWN_DURATION: float = 1.0

const _MUTED_VOLUME_DB: float = -80.0

var _music_library: Dictionary = {
	MusicState.MAIN_MENU:
	{
		"alley_cat":
		{
			"stream": preload("uid://cni0gxe58qh34"),
			"song_name": "Alley Cat",
			"author": "Abstraction",
		},
		"mischief_melody":
		{
			"stream": preload("uid://o646wkfcd157"),
			"song_name": "Mischief Melody",
			"author": "Abstraction",
		},
		"seaside_endless_waves":
		{
			"stream": preload("uid://dak2jjcwx0w15"),
			"song_name": "Seaside Endless Waves",
			"author": "Abstraction",
		},
	},
	MusicState.EXPLORATION:
	{
		"start":
		{
			"stream": preload("uid://bxyvub1x8yjhp"),
			"song_name": "Start",
			"author": "chajamakesmusic",
		},
		"blossom":
		{
			"stream": preload("uid://cp0si1iqrye43"),
			"song_name": "Blossom",
			"author": "chajamakesmusic",
		},
		"journey":
		{
			"stream": preload("uid://bqcm6jip7ppr1"),
			"song_name": "Journey",
			"author": "chajamakesmusic",
		},
		"regrowth_wip":
		{
			"stream": preload("uid://dhkwf2sf675tb"),
			"song_name": "Regrowth Wip",
			"author": "chajamakesmusic",
		},
		"shop":
		{
			"stream": preload("uid://cewvxcw8hwrj1"),
			"song_name": "Shop",
			"author": "chajamakesmusic",
		},
		"town":
		{
			"stream": preload("uid://bbdc8a1gy34l"),
			"song_name": "Town",
			"author": "chajamakesmusic",
		},
	},
	MusicState.RACING:
	{
		"never_miss_fire":
		{
			"stream": preload("uid://d03gq72qvxvbv"),
			"song_name": "Never Miss Fire",
			"author": "Abstraction",
		},
		"cloak_of_darness_stage_1":
		{
			"stream": preload("uid://cynalefhnsrfh"),
			"song_name": "Cloak of Darness",
			"author": "Abstraction",
		},
		"sketchbook_2025_12_11_neuro":
		{
			"stream": preload("uid://d3807y65y3uky"),
			"song_name": "Sketchbook 2025 12 11 NEURO",
			"author": "Abstraction",
		}
	},
	#MusicState.COMBAT: {},
	MusicState.MAZE:
	{
		"ceiling_stars":
		{
			"stream": preload("uid://cv6xjgx8a5ir8"),
			"song_name": "Ceiling Stars",
			"author": "Crow Shade",
		},
		"sealed":
		{
			"stream": preload("uid://652qd4h6o1xt"),
			"song_name": "Sealed",
			"author": "Crow Shade",
		},
	}
	#MusicState.NIGHT: {},
}

var _current_state: MusicState = MusicState.SILENCE

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _current_player: AudioStreamPlayer
var _staging_player: AudioStreamPlayer

var _fade_tween: Tween
var _transition_cooldown: bool = false
var _sound_pool: SoundPool
var _crossfade_duration: float = 2.0
var _music_volume_db: float = 0.0


func initialize(pool: SoundPool) -> void:
	assert(_sound_pool == null, "MusicController already initialized in " + name)
	_sound_pool = pool
	_create_music_players()

	process_mode = Node.PROCESS_MODE_ALWAYS


func _create_music_players() -> void:
	assert(_player_a == null, "Music players already initialized in " + name)

	_player_a = AudioStreamPlayer.new()
	_player_a.bus = "Music"
	_player_a.volume_db = _MUTED_VOLUME_DB
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = "Music"
	_player_b.volume_db = _MUTED_VOLUME_DB
	add_child(_player_b)

	_current_player = _player_a
	_staging_player = _player_b


func play(track: AudioStream, fade_duration: float = 1.0, track_key: String = "") -> void:
	if _current_player.stream == track and _current_player.playing:
		return

	var display_name: String = track_key
	var author_name: String = ""
	if track_key.is_empty():
		display_name = _track_display_name(track)
		author_name = _get_track_author(track)
	else:
		for state_tracks: Dictionary in _music_library.values():
			if state_tracks.has(track_key):
				display_name = state_tracks[track_key].get("song_name", track_key.capitalize())
				author_name = state_tracks[track_key].get("author", "Unknown")
				break

	track_changed.emit(display_name, author_name)

	if _fade_tween:
		_fade_tween.kill()

	if _current_player.finished.is_connected(_on_track_finished):
		_current_player.finished.disconnect(_on_track_finished)

	var old_player: AudioStreamPlayer = _current_player
	_current_player = _staging_player
	_staging_player = old_player

	_current_player.stop()
	_current_player.stream = track
	_current_player.volume_db = _MUTED_VOLUME_DB
	_current_player.play()
	_current_player.finished.connect(_on_track_finished, CONNECT_ONE_SHOT)

	if fade_duration <= 0.0:
		_staging_player.stop()
		_current_player.volume_db = _music_volume_db
		return

	_fade_tween = create_tween()
	(
		_fade_tween
		. tween_property(
			_current_player,
			"volume_db",
			_music_volume_db,
			fade_duration,
		)
	)

	(
		_fade_tween
		. parallel()
		. tween_property(
			_staging_player,
			"volume_db",
			_MUTED_VOLUME_DB,
			fade_duration,
		)
	)

	_fade_tween.tween_callback(func() -> void: _staging_player.stop())


func change_state(new_state: MusicState, immediate: bool = false, track_key: String = "") -> void:
	if new_state == _current_state and track_key.is_empty():
		return

	if _transition_cooldown and not immediate:
		return

	if new_state == MusicState.SILENCE:
		_current_state = new_state
		stop()
		return

	var tracks: Dictionary = _music_library.get(new_state, {})
	if tracks.is_empty():
		return

	var track: AudioStream
	if not track_key.is_empty():
		assert(tracks.has(track_key), "Track key '" + track_key + "' not found in state " + str(new_state) + " in " + name)
		track = tracks[track_key]["stream"]
	else:
		var track_values: Array = []
		for track_data: Dictionary in tracks.values():
			track_values.append(track_data["stream"])

		if _current_player.playing and _current_player.stream in track_values:
			track_values.erase(_current_player.stream)
		if track_values.is_empty():
			return
		track = track_values.pick_random()

	_current_state = new_state
	var fade_duration: float = 0.0 if immediate else _crossfade_duration
	play(track, fade_duration, track_key)

	_transition_cooldown = true
	get_tree().create_timer(_TRANSITION_COOLDOWN_DURATION).timeout.connect(_on_transition_cooldown_finished)


func stop(fade_duration: float = 1.0) -> void:
	if not _current_player.playing:
		return

	if _fade_tween:
		_fade_tween.kill()

	if _current_player.finished.is_connected(_on_track_finished):
		_current_player.finished.disconnect(_on_track_finished)

	_staging_player.stop()
	_staging_player.volume_db = _MUTED_VOLUME_DB

	if fade_duration <= 0.0:
		_current_player.stop()
		return

	_fade_tween = create_tween()
	(
		_fade_tween
		. tween_property(
			_current_player,
			"volume_db",
			_MUTED_VOLUME_DB,
			fade_duration,
		)
	)

	_fade_tween.tween_callback(func() -> void: _current_player.stop())


func set_volume(volume_db: float) -> void:
	_music_volume_db = volume_db

	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
		_fade_tween = null

	_current_player.volume_db = volume_db
	_staging_player.volume_db = volume_db


func set_crossfade_duration(duration: float) -> void:
	_crossfade_duration = duration


func get_current_track_name() -> String:
	if not _current_player.playing:
		return ""
	return _track_display_name(_current_player.stream)


func get_current_track_author() -> String:
	if not _current_player.playing:
		return ""

	for state_tracks: Dictionary in _music_library.values():
		for key: String in state_tracks:
			if state_tracks[key]["stream"] == _current_player.stream:
				return state_tracks[key].get("author", "Unknown")

	return "Unknown"


func get_current_track_full_info() -> Dictionary:
	if not _current_player.playing:
		return {}

	for state_tracks: Dictionary in _music_library.values():
		for key: String in state_tracks:
			if state_tracks[key]["stream"] == _current_player.stream:
				return {
					"key": key,
					"name": state_tracks[key].get("song_name", key),
					"author": state_tracks[key].get("author", "Unknown"),
					"state": _current_state
				}

	return {"error": "Track not found in library"}


func on_combat_started() -> void:
	change_state(MusicState.COMBAT)


func on_combat_ended() -> void:
	change_state(MusicState.EXPLORATION)


#region Private helper
func _on_track_finished() -> void:
	var tracks: Dictionary = _music_library.get(_current_state, {})
	var candidates: Array = []
	if not tracks.is_empty():
		for key: String in tracks:
			if _current_player.stream != tracks[key]["stream"]:
				candidates.append(key)

	# Fallback: if current state has no candidates, try any state with tracks
	if candidates.is_empty():
		for state_tracks: Dictionary in _music_library.values():
			for key: String in state_tracks:
				if _current_player.stream != state_tracks[key]["stream"]:
					candidates.append(key)

	if candidates.is_empty():
		return

	var next_key: String = candidates.pick_random()
	# Find the stream for the picked key across all states
	var next_stream: AudioStream = null
	for state_tracks: Dictionary in _music_library.values():
		if state_tracks.has(next_key):
			next_stream = state_tracks[next_key]["stream"]
			break
	assert(next_stream != null, "Track '" + next_key + "' not found in library in " + name)
	play(next_stream, _crossfade_duration, next_key)


func _on_transition_cooldown_finished() -> void:
	_transition_cooldown = false


func _track_display_name(track: AudioStream) -> String:
	for state_tracks: Dictionary in _music_library.values():
		for key: String in state_tracks:
			if state_tracks[key]["stream"] == track:
				return state_tracks[key].get("song_name", key.capitalize())
	assert(false, "Track key not found")
	return "Error"


func _get_track_author(track: AudioStream) -> String:
	for state_tracks: Dictionary in _music_library.values():
		for key: String in state_tracks:
			if state_tracks[key]["stream"] == track:
				return state_tracks[key].get("author", "Unknown")
	return "Unknown"
#endregion
