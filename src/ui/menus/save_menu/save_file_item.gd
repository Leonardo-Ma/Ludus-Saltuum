## Displays one save slot
## Empty slots start New Game, occupied slots load
class_name SaveFileItem
extends AspectRatioContainer

@warning_ignore("unused_signal")
signal item_focused

var _slot_index: int = -1
var _has_data: bool = false

@onready var _save_name_label: Label = %SaveNameValueLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _play_time_label: Label = %PlayTimeValueLabel
@onready var _save_date_label: Label = %SaveDateValueLabel
@onready var _load_button: Button = %LoadButton
@onready var _delete_button: Button = %DeleteButton


func _ready() -> void:
	_load_button.pressed.connect(_on_load_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)


func setup(slot_index: int, data: SaveData) -> void:
	_slot_index = slot_index
	_has_data = data != null
	var is_auto: bool = slot_index >= SaveManager.MANUAL_SLOTS and slot_index < SaveManager.QUICK_SAVE_SLOT
	var is_quick: bool = slot_index == SaveManager.QUICK_SAVE_SLOT

	if not _has_data:
		_show_empty(slot_index, is_auto, is_quick)
		return

	var prefix: String
	if is_auto:
		prefix = "Auto %d" % (slot_index - SaveManager.MANUAL_SLOTS + 1)
	elif is_quick:
		prefix = "Quick Save"
	else:
		prefix = "Slot %d" % (slot_index + 1)

	_save_name_label.text = prefix
	_score_label.text = str(data.score)
	_gold_label.text = str(data.gold)
	_save_date_label.text = Time.get_datetime_string_from_unix_time(data.save_timestamp)
	_play_time_label.text = ""
	_load_button.text = "Load"
	_load_button.disabled = false
	_delete_button.disabled = false


func _show_empty(slot_index: int, is_auto: bool, is_quick: bool) -> void:
	var prefix: String
	if is_auto:
		prefix = "Auto %d" % (slot_index - SaveManager.MANUAL_SLOTS + 1)
	elif is_quick:
		prefix = "Quick Save"
	else:
		prefix = "Slot %d" % (slot_index + 1)

	_save_name_label.text = prefix
	_score_label.text = "-"
	_gold_label.text = "-"
	_save_date_label.text = "-"
	_play_time_label.text = "-"
	_load_button.text = "New Game" if (not is_auto and not is_quick) else "-"
	_load_button.disabled = is_auto or is_quick
	_delete_button.disabled = true


func _on_load_pressed() -> void:
	if _has_data:
		SaveManager.load_from_slot(_slot_index)
	else:
		SaveManager.reset_for_new_game()
	ApplicationStateManager.request_play_from_save()


func _on_delete_pressed() -> void:
	# TODO Add confirmation popup
	SaveManager.delete_slot(_slot_index)
