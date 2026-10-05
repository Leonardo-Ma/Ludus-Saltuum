class_name MusicPlaylist
extends Resource

@export var tracks: Array[MusicTrack]

var _remaining_tracks: Array[MusicTrack] = []


func get_track_by_key(track_key: String) -> MusicTrack:
	for track: MusicTrack in tracks:
		if track.key == track_key:
			return track

	return null


func pick_next_track(current_track: MusicTrack) -> MusicTrack:
	if tracks.is_empty():
		return null

	if _remaining_tracks.is_empty():
		_refill_track_bag(current_track)

	return _remaining_tracks.pop_back()


func consume_track(track: MusicTrack) -> void:
	_remaining_tracks.erase(track)


func reset() -> void:
	_remaining_tracks.clear()


func _refill_track_bag(current_track: MusicTrack) -> void:
	_remaining_tracks = tracks.duplicate()
	_remaining_tracks.shuffle()

	if _remaining_tracks.size() > 1 and _remaining_tracks.back() == current_track:
		var replacement_index: int = _remaining_tracks.size() - 2
		var replacement_track: MusicTrack = _remaining_tracks[replacement_index]
		_remaining_tracks[replacement_index] = current_track
		_remaining_tracks[_remaining_tracks.size() - 1] = replacement_track
