## Displays one save slot
## Empty slots start New Game, occupied slots load
class_name SaveFileItem
extends AspectRatioContainer

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

@onready var _play_button: Button = %PlayButton
@onready var _delete_button: Button = %DeleteButton


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
	_save_date_label.text = Time.get_datetime_string_from_unix_time(data.save_timestamp)
	_play_time_label.text = ""
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


func _on_play_pressed() -> void:
	if _has_data:
		SaveManager.load_from_slot(_slot_index)
	else:
		SaveManager.reset_data_for_new_game()
	ApplicationStateManager.request_play_from_save()


func _on_delete_pressed() -> void:
	# TODO Add confirmation popup
	SaveManager.delete_slot(_slot_index)


func _populate_icons() -> void:
	if is_auto:
		_save_type_icon.texture = DISPLAY
	else:
		_save_type_icon.texture = CURSOR_LINK
