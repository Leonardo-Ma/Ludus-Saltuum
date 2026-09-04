## Displays one save slot
## Empty slots start New Game, occupied slots load
class_name SaveFileItem
extends AspectRatioContainer

signal play_requested(slot_index: int)
signal delete_requested(slot_index: int)

const CURSOR_LINK: CompressedTexture2D = preload("uid://8hkrepcpd520")
const DISPLAY: CompressedTexture2D = preload("uid://bkg1s07hgwn6s")
const PLUS: CompressedTexture2D = preload("uid://dl4tpaxj10pb5")
const PLAY: CompressedTexture2D = preload("uid://cqgd6g3oujuj")

var is_auto: bool
var is_quick: bool

var _slot_index: int = -1
var _has_data: bool = false

@onready var _save_name_label: Label = %SaveNameValueLabel

@onready var _score_label: Label = %ScoreLabel
@onready var _gold_label: Label = %GoldLabel

@onready var _save_type_icon: TextureRect = %SaveTypeIcon
@onready var _play_time_label: Label = %PlayTimeValueLabel
@onready var _save_date_label: Label = %SaveDateValueLabel

@onready var _play_button: UIButton = %PlayButton
@onready var _delete_button: UIButton = %DeleteButton


func _ready() -> void:
	_play_button.pressed.connect(_on_play_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)


## Used by [SaveMenu] on visibility changed
func setup(slot_index: int, data: SaveData) -> void:
	_slot_index = slot_index
	_has_data = data != null
	is_auto = slot_index >= SaveManager.MANUAL_SLOTS

	if not _has_data:
		_show_empty()
		return

	var prefix: String
	_populate_icons()

	_save_name_label.text = prefix
	_score_label.text = str(data.player.score)
	_gold_label.text = str(data.player.gold)
	_save_date_label.text = _format_save_date(data.save_timestamp)
	_play_time_label.text = _format_play_time(data.play_time_seconds)
	_play_button.icon = PLAY
	_play_button.disabled = false
	_delete_button.disabled = false


func _show_empty() -> void:
	var prefix: String
	_populate_icons()

	_save_name_label.text = prefix
	_score_label.text = "-"
	_gold_label.text = "-"
	_save_date_label.text = "-"
	_play_time_label.text = "-"
	_play_button.icon = PLUS
	_play_button.disabled = is_auto or is_quick
	_delete_button.disabled = true


## Goes to save menu parent
func _on_play_pressed() -> void:
	play_requested.emit(_slot_index)


## Goes to save menu parent
func _on_delete_pressed() -> void:
	delete_requested.emit(_slot_index)


func _populate_icons() -> void:
	if is_auto:
		_save_type_icon.texture = DISPLAY
	else:
		_save_type_icon.texture = CURSOR_LINK


func _format_save_date(unix_time: int) -> String:
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	if OS.get_locale_language() == "en":
		return "%02d/%02d/%04d %02d:%02d" % [dt.month, dt.day, dt.year, dt.hour, dt.minute]
	return "%02d/%02d/%04d %02d:%02d" % [dt.day, dt.month, dt.year, dt.hour, dt.minute]


func _format_play_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	@warning_ignore("integer_division") var hours: int = total_seconds / 3600
	@warning_ignore("integer_division") var minutes: int = (total_seconds % 3600) / 60
	var secs: int = total_seconds % 60
	return "%03d:%02d:%02d" % [hours, minutes, secs]
