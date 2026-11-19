extends UIButton

@export var owned_texture: Texture2D
@export var equipped_texture: Texture2D

var _player: PlayerEntity

@onready var _card: CosmeticCard = owner as CosmeticCard
@onready var _asset: CosmeticAsset = _card.asset


func _button_ready() -> void:
	ApplicationStateManager.menu_opened.connect(_on_menu_opened)


func _on_menu_opened(menu: ApplicationStateManager.GameState) -> void:
	if menu == ApplicationStateManager.GameState.COSMETICS_MENU:
		_update_button()


func _button_pressed() -> void:
	var cosmetic_id: StringName = _asset.cosmetic_id

	if _player.cosmetics_controller.owns(cosmetic_id):
		_player.cosmetics_controller.equip(cosmetic_id)
	else:
		if not _player.economy_controller.remove_gold(_asset.price):
			assert(false, "Tried to acquire cosmetic " + _asset.display_name + " without gold at " + owner.name)
			return

		_player.cosmetics_controller.acquire(cosmetic_id)
		_player.cosmetics_controller.equip(cosmetic_id)

	_update_button()


func _update_button() -> void:
	_player = _get_player()
	# TODO Find better way
	if not _player.cosmetics_controller.equipped_changed.is_connected(_on_equipped_changed):
		_player.cosmetics_controller.equipped_changed.connect(_on_equipped_changed)

	var cosmetic_id: StringName = _asset.cosmetic_id
	var already_owned: bool = _player.cosmetics_controller.owns(cosmetic_id)
	var is_equipped: bool = _player.cosmetics_controller.get_equipped_id(_asset.get_slot()) == cosmetic_id
	var can_afford: bool = _player.economy_controller.gold >= _asset.price

	var font_color: Color = Color.LIGHT_CORAL if not can_afford else Color.WHITE

	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_disabled_color", font_color)

	if is_equipped:
		icon = equipped_texture
		text = ""
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif already_owned:
		icon = owned_texture
		text = ""
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		text = str(_asset.price)

	disabled = is_equipped or (not already_owned and not can_afford)


func _on_equipped_changed(_equipped: CosmeticAsset) -> void:
	_update_button()


func _get_player() -> PlayerEntity:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	assert(not players.is_empty(), "Player missing for " + name)
	return players[0] as PlayerEntity
