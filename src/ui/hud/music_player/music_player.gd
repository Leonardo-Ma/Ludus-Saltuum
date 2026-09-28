## Shows current track name briefly when music changes
extends Container

const DISPLAY_DURATION: float = 3.0
const FADE_DURATION: float = 0.5

@onready var song_title: Label = %SongTitle
@onready var song_author: Label = %SongAuthor


func _ready() -> void:
	SoundManager.music.track_changed.connect(_on_track_changed)


func _on_track_changed(track_name: String, author: String) -> void:
	song_title.text = track_name
	song_author.text = author

	await fade_out_effect()


## Visual fade in and out effect
func fade_out_effect() -> void:
	visible = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_interval(DISPLAY_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	visible = false
