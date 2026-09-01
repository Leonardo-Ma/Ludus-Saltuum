## Player stat upgrade shop
extends Control

const COST_GROW: float = 1.3

## Maps a stat_property StringName to the player resource that owns it
var _stat_targets: Dictionary = {}

@onready var _status_label: Label = %StatusLabel
@onready var _shop_panel: Control = %ShopPanel
@onready var _cards: Array[PanelContainer] = _collect_cards()


func _ready() -> void:
	GameEvents.player_finished_spawning.connect(_on_player_spawned)
	EconomyManager.gold_updated.connect(_on_gold_updated)
	_on_gold_updated(EconomyManager.gold)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()


#func _unhandled_key_input(event: InputEvent) -> void:
#	if event.is_action_pressed("open_shop"):
#		visible = not visible
#		if visible:
#			MouseModeManager.request_mode(&"shop", Input.MOUSE_MODE_VISIBLE)
#		else:
#			MouseModeManager.release(&"shop")


func _on_player_spawned(spawned_player: Node) -> void:
	var player: PlayerEntity = spawned_player as PlayerEntity
	assert(player != null, "Invalid player node for Shop")

	_stat_targets = {
		&"speed": player.movement,
		&"jump_velocity": player.movement,
		&"damage": player.attack,
		&"max_health": player.health,
		&"health_regen": player.health,
	}

	for card: PanelContainer in _cards:
		var upgrade_card: PanelContainer = card as PanelContainer
		var target: Object = _stat_targets.get(upgrade_card.stat_property)
		assert(target != null, "No stat target mapped for property '%s' in %s" % [upgrade_card.stat_property, upgrade_card.name])
		upgrade_card.bind_target(target)
		upgrade_card.upgrade_requested.connect(_on_upgrade_requested)
	_refresh_affordability()


func _on_upgrade_requested(card: PanelContainer) -> void:
	var upgrade_card: PanelContainer = card as PanelContainer
	if EconomyManager.gold < upgrade_card.cost:
		_set_status("Not enough gold! Need %d more." % (upgrade_card.cost - EconomyManager.gold), false)
		return

	EconomyManager.remove_gold(upgrade_card.cost)
	upgrade_card.apply_upgrade(int(ceil(upgrade_card.cost * COST_GROW)))
	_refresh_affordability()
	_set_status("%s upgraded! Now %s %s." % [upgrade_card.stat_name, upgrade_card.get_stat_value(), upgrade_card.unit], true)


func _on_gold_updated(_new_gold: int) -> void:
	_refresh_affordability()


func _refresh_affordability() -> void:
	for card: PanelContainer in _cards:
		var upgrade_card: PanelContainer = card as PanelContainer
		upgrade_card.set_affordable(EconomyManager.gold >= upgrade_card.cost)


func _set_status(msg: String, ok: bool) -> void:
	_status_label.text = msg
	_status_label.modulate = Color(0.35, 0.85, 0.45, 1) if ok else Color(1.0, 0.4, 0.4, 1)


func _on_viewport_size_changed() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var w: float = minf(540.0, vp.x * 0.92)
	var h: float = minf(580.0, vp.y * 0.92)
	_shop_panel.offset_left = -w * 0.5
	_shop_panel.offset_right = w * 0.5
	_shop_panel.offset_top = -h * 0.5
	_shop_panel.offset_bottom = h * 0.5


func _collect_cards() -> Array[PanelContainer]:
	var result: Array[PanelContainer] = []
	for child: Node in find_children("*", "PanelContainer", true, false):
		if child.get_script() and child.get_script().get_global_name() == &"UpgradeCard":
			result.append(child as PanelContainer)
	return result
