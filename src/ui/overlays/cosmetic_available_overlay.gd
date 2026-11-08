class_name CosmeticAvailableOverlay
extends Control

## Toast shown when player can afford an unowned cosmetic

const TOTAL_DURATION: float = 5.0
const FADE_DURATION: float = 0.4

var _tween: Tween


func _ready() -> void:
	hide()
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0] as Node3D)


func _on_player_spawned(player: Node3D) -> void:
	var controller: CosmeticsController = (player as PlayerEntity).cosmetics_controller
	if not controller.affordable_cosmetic_reminded.is_connected(_on_reminder):
		controller.affordable_cosmetic_reminded.connect(_on_reminder)


func _on_reminder() -> void:
	if _tween != null:
		_tween.kill()

	modulate.a = 0.0
	show()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_interval(TOTAL_DURATION - 2.0 * FADE_DURATION)
	_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(hide)
