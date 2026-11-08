extends Container

## Shows current track name briefly when music changes

@onready var song_title: Label = %SongTitle
@onready var song_author: Label = %SongAuthor


func _ready() -> void:
	MusicController.track_changed.connect(_on_track_changed)
	_on_track_changed(MusicController.get_current_track_name(), MusicController.get_current_track_author())


func _on_track_changed(track_name: String, author: String) -> void:
	song_title.text = track_name
	song_author.text = author
