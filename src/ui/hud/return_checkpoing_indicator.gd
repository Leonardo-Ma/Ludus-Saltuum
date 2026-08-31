## Clock progress bar while holding return to checkpoint
extends TextureProgressBar

var _tween: Tween


func _ready() -> void:
	hide()
	GameEvents.player_finished_spawning.connect(_on_player_spawned)
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0])


func _on_player_spawned(player: Node) -> void:
	var controller: InputController = (player as PlayerEntity).input_controller
	controller.return_hold_started.connect(_on_hold_started)
	controller.return_hold_cancelled.connect(_on_hold_cancelled)


func _on_hold_started(duration: float) -> void:
	if _tween:
		_tween.kill()
	value = 0.0
	show()
	_tween = create_tween()
	_tween.tween_property(self, "value", 100.0, duration).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_callback(hide)


func _on_hold_cancelled() -> void:
	if _tween:
		_tween.kill()
	hide()
