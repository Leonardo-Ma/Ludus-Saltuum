class_name DebugView
extends Control

## Displays player diagnostics and on-demand procedural chunk history

enum HistoryColumn {
	SCENE = 0,
	SHAPE = 1,
	HEIGHT = 2,
	SOURCE = 3,
	TAGS = 4,
}

const CHUNK_HISTORY_PAUSE: String = "chunk_history"

var _previous_focus: Control
var _decision_history: ChunkDecisionHistory
var _history_keys: Array[int] = []

@onready var _label: PlayerDebugLabel = %Label
@onready var _history_panel: Control = %ChunkHistory
@onready var _history_tree: Tree = %ChunkHistoryTree
@onready var _decision_details: Label = %DecisionDetails
@onready var _close_history: Button = %CloseHistory


#region Lifecycle
func _ready() -> void:
	if not OS.is_debug_build():
		set_process_unhandled_key_input(false)
		queue_free()
		return

	_decision_history = ChunkDecisionHistory.new(ChunkManager.get_chunk_selector(), ChunkManager.get_next_chunk_key)
	_decision_history.set_recording(true)
	_history_tree.item_selected.connect(_show_selected_decision)
	_close_history.pressed.connect(_set_history_open.bind(false))
	SaveManager.save_loaded.connect(_on_save_loaded)
	ChunkManager.level_loaded.connect(_refresh_history, CONNECT_DEFERRED)
	# Refresh after the replacement chunk has been activated and restored
	ChunkManager.chunk_recycled.connect(_refresh_history.unbind(1), CONNECT_DEFERRED)


func _exit_tree() -> void:
	if _decision_history != null:
		_decision_history.set_recording(false)
	if is_instance_valid(_history_panel) and _history_panel.visible:
		_release_history_input()
#endregion


func bind_player(player: PlayerEntity, movement: PlayerMovementComponent) -> void:
	_label.bind_player(player, movement)


#region Chunk History Controls
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_chunk_history") or (_history_panel.visible and event.is_action_pressed(&"ui_cancel")):
		_set_history_open(not _history_panel.visible)
		get_viewport().set_input_as_handled()


func _set_history_open(open: bool) -> void:
	if open:
		_previous_focus = get_viewport().gui_get_focus_owner()
		_history_panel.show()
		_refresh_history()
		PauseManager.request_pause(CHUNK_HISTORY_PAUSE)
		MouseModeManager.request_mode(MouseModeManager.Source.DEBUG, Input.MOUSE_MODE_VISIBLE)
		_history_tree.grab_focus()
	else:
		_history_panel.hide()
		_release_history_input()
		if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
			_previous_focus.grab_focus()


func _release_history_input() -> void:
	MouseModeManager.release(MouseModeManager.Source.DEBUG)
	PauseManager.release_pause(CHUNK_HISTORY_PAUSE)
#endregion


#region Chunk History List
func _on_save_loaded(data: SaveData) -> void:
	_decision_history.record_loaded_chunks(data.chunks)


func _refresh_history() -> void:
	if not _history_panel.is_visible_in_tree():
		return

	_history_tree.clear()
	var history_root: TreeItem = _history_tree.create_item()
	var scenes: Dictionary[int, String] = _decision_history.get_recent_scenes()
	_history_keys.assign(scenes.keys())
	_history_keys.reverse()
	_history_keys = _history_keys.slice(0, ChunkSelector.RECENT_CHUNK_HISTORY_SIZE)
	for chunk_key: int in _history_keys:
		_add_history_row(history_root, chunk_key, scenes[chunk_key])

	var newest: TreeItem = history_root.get_first_child()
	if newest != null:
		newest.select(HistoryColumn.SCENE)
	else:
		_decision_details.text = "No chunks generated yet"


func _add_history_row(history_root: TreeItem, chunk_key: int, scene_uid: String) -> void:
	var row: TreeItem = _history_tree.create_item(history_root)
	var decision: ChunkSelectionDetails = _decision_history.get_decision(chunk_key)
	var restored: bool = decision != null and not decision.restored_scene_uid.is_empty()
	row.set_text(HistoryColumn.SOURCE, "Loaded" if restored else "Generated")
	# Catalog metadata can be missing for a restored UID
	var chunk: ChunkData = ChunkManager.get_chunk_data_by_uid(scene_uid)
	if chunk == null:
		row.set_text(HistoryColumn.SCENE, scene_uid)
		return

	row.set_text(HistoryColumn.SCENE, chunk.scene_path.get_file().get_basename())
	row.set_tooltip_text(HistoryColumn.SCENE, chunk.scene_path)
	row.set_text(HistoryColumn.SHAPE, "Turn" if chunk.is_turn else "Straight")
	row.set_text(HistoryColumn.HEIGHT, "%+.2f" % chunk.height_shift)
	var tags: PackedStringArray = []
	for feature: ChunkFeature.Feature in chunk.features:
		var feature_name: Variant = ChunkFeature.Feature.find_key(feature)
		if feature_name != null:
			tags.append(str(feature_name).capitalize())
	var tag_text: String = ", ".join(tags)
	row.set_text(HistoryColumn.TAGS, tag_text)
	row.set_tooltip_text(HistoryColumn.TAGS, tag_text)
#endregion


#region Decision Details
func _show_selected_decision() -> void:
	var row: TreeItem = _history_tree.get_selected()
	if row == null:
		return
	var chunk_key: int = _history_keys[row.get_index()]
	var decision: ChunkSelectionDetails = _decision_history.get_decision(chunk_key)
	if decision == null:
		_decision_details.text = "No decision recorded for this pick"
		return
	if not decision.restored_scene_uid.is_empty():
		_decision_details.text = "Loaded from save  ·  Chunk key %d  ·  Chunk seed %d" % [chunk_key, decision.chunk_seed]
		return

	var relaxed_rules: PackedStringArray = []
	if decision.scheduled_count == 0:
		relaxed_rules.append("skill unlock scheduling")
	if decision.turn_spaced_count == 0:
		relaxed_rules.append("turn spacing")

	var recency: String = "Unseen %d" % decision.unseen_count if decision.unseen_count > 0 else "Least recently generated"
	var relaxed: String = "none" if relaxed_rules.is_empty() else ", ".join(relaxed_rules)
	_decision_details.text = (
		"Chunk seed %d  ·  Score %d\n" + "Since turn %d  ·  Last skill threshold %d  ·  Forced unlock %s\n"
		+ "Eligible %d of %d  ·  Scheduled %d  ·  Turn spacing %d\n" + "%s  ·  Final pool %d\nRelaxed rules  %s"
	) % [
		decision.chunk_seed,
		decision.score,
		decision.chunks_since_turn,
		decision.last_skill_score_threshold,
		"yes" if decision.force_skill_unlock else "no",
		decision.eligible_count,
		decision.catalog_count,
		decision.scheduled_count,
		decision.turn_spaced_count,
		recency,
		decision.final_count,
		relaxed,
	]
#endregion
