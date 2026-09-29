class_name PowerUpView
extends MarginContainer

var _powerup_ui_elements: Dictionary = { }
var _active_trackers: Dictionary = { }

@onready var power_ups_container: GridContainer = %PowerUpsContainer


func _ready() -> void:
	assert(power_ups_container != null, "PowerUps missing container child.")

	for child: Control in power_ups_container.get_children():
		var hbox: HBoxContainer = child as HBoxContainer
		if hbox:
			hbox.hide()
			# re-assign keys when actual identifiers come in
			_powerup_ui_elements[StringName(hbox.name)] = hbox

	CollectiblesEvents.status_buff_collected.connect(_on_status_buff_collected)
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)

	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0] as PlayerEntity)


func _on_status_buff_collected(status_collectible: StatusCollectible) -> void:
	var status_effect: StatusEffect = status_collectible.status_effect
	var icon: Texture2D = status_collectible.icon
	var duration: float = status_collectible.duration

	var identifier: StringName = status_effect.get_id()
	var ui_node: HBoxContainer = _get_ui_node(identifier)

	if ui_node == null:
		assert(false, "Ran out of powerup UI elements in " + name)
		return

	if _active_trackers.has(identifier):
		_kill_active_tweens(identifier)

	ui_node.show()

	var icon_node: TextureRect = ui_node.get_node("PowerUp") as TextureRect
	assert(icon_node != null, "PowerUp missing icon child in " + ui_node.name)

	if icon:
		icon_node.texture = icon

	var cooldown_progress: TextureProgressBar = icon_node.get_node("CooldownProgress") as TextureProgressBar
	assert(cooldown_progress != null, "CooldownProgress missing in " + icon_node.name)

	var is_infinite: bool = duration < 0.0
	cooldown_progress.visible = not is_infinite

	if is_infinite:
		_active_trackers[identifier] = { "node": ui_node, "icon_node": icon_node }
		return

	cooldown_progress.texture_progress = icon_node.texture

	var cooldown_tween: Tween = create_tween()
	cooldown_progress.value = 0.0
	cooldown_tween.tween_property(cooldown_progress, "value", 100.0, duration)
	cooldown_tween.finished.connect(_on_status_ended.bind(identifier))

	var flash_tween: Tween = create_tween().bind_node(icon_node)
	var flash_delay: float = maxf(duration - 3.0, 0.0)

	flash_tween.tween_interval(flash_delay)
	flash_tween.tween_property(icon_node, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.2)
	flash_tween.tween_property(icon_node, "modulate", Color.WHITE, 0.2)
	flash_tween.set_loops()

	_active_trackers[identifier] = {
		"node": ui_node,
		"icon_node": icon_node,
		"cooldown_progress": cooldown_progress,
		"cooldown_tween": cooldown_tween,
		"flash_tween": flash_tween,
	}


func _on_status_ended(identifier: StringName) -> void:
	if not _active_trackers.has(identifier):
		return

	_clear_tracker(identifier)
	_active_trackers.erase(identifier)


func _on_player_spawned(player: PlayerEntity) -> void:
	if not player.status_manager.status_removed.is_connected(_on_status_ended):
		player.status_manager.status_removed.connect(_on_status_ended)


# TODO Refactor to remove this, must be static typed instead of traversing
func _get_ui_node(identifier: StringName) -> HBoxContainer:
	if _powerup_ui_elements.has(identifier):
		return _powerup_ui_elements[identifier] as HBoxContainer

	for key: StringName in _powerup_ui_elements:
		var candidate: HBoxContainer = _powerup_ui_elements[key] as HBoxContainer
		if not candidate.visible and not _active_trackers.has(key):
			_powerup_ui_elements.erase(key)
			_powerup_ui_elements[identifier] = candidate
			return candidate

	return null


func _kill_active_tweens(identifier: StringName) -> void:
	var tracker: Dictionary = _active_trackers[identifier]

	if tracker.has("cooldown_tween"):
		var cooldown_tween: Tween = tracker["cooldown_tween"] as Tween
		if is_instance_valid(cooldown_tween):
			cooldown_tween.kill()

	if tracker.has("flash_tween"):
		var flash_tween: Tween = tracker["flash_tween"] as Tween
		if is_instance_valid(flash_tween):
			flash_tween.kill()

	var icon_node: TextureRect = tracker["icon_node"] as TextureRect
	icon_node.modulate = Color.WHITE


func _clear_tracker(identifier: StringName) -> void:
	var tracker: Dictionary = _active_trackers[identifier]

	if tracker.has("cooldown_tween"):
		var cooldown_tween: Tween = tracker["cooldown_tween"] as Tween
		if is_instance_valid(cooldown_tween):
			cooldown_tween.kill()

	if tracker.has("flash_tween"):
		var flash_tween: Tween = tracker["flash_tween"] as Tween
		if is_instance_valid(flash_tween):
			flash_tween.kill()

	var icon_node: TextureRect = tracker["icon_node"] as TextureRect
	icon_node.modulate = Color.WHITE

	var cooldown_progress: TextureProgressBar = tracker.get("cooldown_progress") as TextureProgressBar
	if cooldown_progress != null:
		cooldown_progress.value = 0.0
		cooldown_progress.visible = false

	var ui_node: HBoxContainer = tracker["node"] as HBoxContainer
	ui_node.hide()
