class_name AudioSettings
extends Resource

## dB added on top of linear_to_db() for audible range sliders use, must match volume_slider.gd
const VOLUME_DB_MAX: float = 6.0

@export var volume_global: float = 1.0
@export var volume_music: float = 1.0
@export var volume_effects: float = 1.0
@export var volume_ui: float = 1.0
