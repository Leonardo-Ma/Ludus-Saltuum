extends MarginContainer

var _powerup_ui_elements: Dictionary = {}
var _active_trackers: Dictionary = {}

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
	ControlledEntityEvents.player_respawning.connect(_on_player_respawning)
	set_process(false)


func _process(delta: float) -> void:
	var keys_to_remove: Array[StringName] = []

	for identifier: StringName in _active_trackers:
		var tracker: Dictionary = _active_trackers[identifier]
		if tracker.is_infinite:
			continue

		tracker.remaining_time -= delta
		if tracker.remaining_time <= 0.0:
			tracker.node.hide()
			keys_to_remove.append(identifier)
		elif tracker.remaining_time <= 3.0 and not tracker.has("flash_tween"):
			var icon_node: TextureRect = tracker.node.get_node("PowerUp") as TextureRect
			if icon_node:
				var flash_tween: Tween = create_tween().bind_node(icon_node).set_loops()
				flash_tween.tween_property(icon_node, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.2)
				flash_tween.tween_property(icon_node, "modulate", Color.WHITE, 0.2)
				tracker["flash_tween"] = flash_tween

	for key: StringName in keys_to_remove:
		if _active_trackers[key].has("flash_tween"):
			var flash_tween: Tween = _active_trackers[key]["flash_tween"]
			if is_instance_valid(flash_tween):
				flash_tween.kill()
			var icon_node: TextureRect = _active_trackers[key].node.get_node("PowerUp") as TextureRect
			if icon_node:
				icon_node.modulate = Color.WHITE
		_active_trackers.erase(key)

	if _active_trackers.is_empty():
		set_process(false)


func _on_status_buff_collected(status_effect: StatusEffect, icon: Texture2D) -> void:
	if status_effect == null:
		return

	var identifier: StringName = status_effect.get_id()
	var ui_node: HBoxContainer = null

	# If this powerup already tracked, use that, else use an empty space
	if _powerup_ui_elements.has(identifier):
		ui_node = _powerup_ui_elements[identifier]
	else:
		for key: Variant in _powerup_ui_elements.keys():
			var candidate: HBoxContainer = _powerup_ui_elements[key]
			# Only pick a candidate if it's hidden and not currently being tracked
			if not candidate.visible and not _active_trackers.has(key):
				_powerup_ui_elements.erase(key)
				_powerup_ui_elements[identifier] = candidate
				ui_node = candidate
				break

	if ui_node == null:
		assert(false, "Ran out of powerup UI elements in HUD")
		return

	ui_node.show()
	var icon_node: TextureRect = ui_node.get_node("PowerUp") as TextureRect
	var cooldown_progress: TextureProgressBar = null

	if icon_node:
		if icon:
			icon_node.texture = icon
		cooldown_progress = icon_node.get_node("CooldownProgress") as TextureProgressBar

	var is_infinite: bool = status_effect.is_infinite()

	if cooldown_progress:
		if is_infinite:
			cooldown_progress.visible = false
		else:
			cooldown_progress.visible = true
			cooldown_progress.texture_progress = icon_node.texture

			if _active_trackers.has(identifier):
				if _active_trackers[identifier].has("tween"):
					var old_tween: Tween = _active_trackers[identifier]["tween"]
					if is_instance_valid(old_tween):
						old_tween.kill()
				if _active_trackers[identifier].has("flash_tween"):
					var old_flash: Tween = _active_trackers[identifier]["flash_tween"]
					if is_instance_valid(old_flash):
						old_flash.kill()
						icon_node.modulate = Color.WHITE

			var tween: Tween = create_tween()
			cooldown_progress.value = 0.0
			tween.tween_property(cooldown_progress, "value", 100.0, status_effect.duration)

			_active_trackers[identifier] = {
				"node": ui_node,
				"remaining_time": status_effect.duration,
				"is_infinite": is_infinite,
				"tween": tween,
			}

	if not _active_trackers.has(identifier):
		_active_trackers[identifier] = {
			"node": ui_node,
			"remaining_time": status_effect.duration,
			"is_infinite": is_infinite,
		}

	set_process(true)


func _on_player_respawning(_duration: float) -> void:
	for identifier: StringName in _active_trackers:
		var tracker: Dictionary = _active_trackers[identifier]
		for key: String in ["tween", "flash_tween"]:
			if tracker.has(key) and is_instance_valid(tracker[key]):
				(tracker[key] as Tween).kill()
		(tracker.node as Control).hide()
		var icon_node: TextureRect = tracker.node.get_node("PowerUp") as TextureRect
		if icon_node:
			icon_node.modulate = Color.WHITE
	_active_trackers.clear()
	set_process(false)
