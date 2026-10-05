## Shows current track name briefly when music changes
extends Container

@onready var song_title: Label = %SongTitle
@onready var song_author: Label = %SongAuthor


func _ready() -> void:
	MusicController.track_changed.connect(_on_track_changed)


func _on_track_changed(track_name: String, author: String) -> void:
	song_title.text = track_name
	song_author.text = author
