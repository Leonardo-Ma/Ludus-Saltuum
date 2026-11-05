extends UIButton

@export var owned_texture: Texture2D
@export var equipped_texture: Texture2D

var _player: PlayerEntity

@onready var _cosmetic: CharacterEntityAsset = owner.chosen_character
@onready var _price: int = _cosmetic.character_price


func _button_ready() -> void:
	ApplicationStateManager.menu_opened.connect(_on_menu_opened)


func _on_menu_opened(menu: ApplicationStateManager.GameState) -> void:
	if menu == ApplicationStateManager.GameState.COSMETICS_MENU:
		_update_button()


func _button_pressed() -> void:
	var cosmetic_id: StringName = _cosmetic.character_id

	if _player.cosmetics_controller.owns(cosmetic_id):
		_player.cosmetics_controller.equip(cosmetic_id)
	else:
		if not _player.economy_controller.remove_gold(_price):
			assert(false, "Tried to acquire character " + _cosmetic.character_name + " without gold at " + owner.name)
			return

		_player.cosmetics_controller.acquire(cosmetic_id)
		_player.cosmetics_controller.equip(cosmetic_id)

	_update_button()


func _update_button() -> void:
	_player = _get_player()
	# TODO Find better way
	if not _player.cosmetics_controller.equipped_character_changed.is_connected(_on_equipped_character_changed):
		_player.cosmetics_controller.equipped_character_changed.connect(_on_equipped_character_changed)

	var cosmetic_id: StringName = _cosmetic.character_id
	var already_owned: bool = _player.cosmetics_controller.owns(cosmetic_id)
	var is_equipped: bool = _player.cosmetics_controller.get_equipped_character_id() == cosmetic_id
	var can_afford: bool = _player.economy_controller.gold >= _price

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
		text = str(_price)

	disabled = is_equipped or (not already_owned and not can_afford)


func _on_equipped_character_changed(_character_asset: CharacterEntityAsset) -> void:
	_update_button()


func _get_player() -> PlayerEntity:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	assert(not players.is_empty(), "Player missing for " + name)
	return players[0] as PlayerEntity
