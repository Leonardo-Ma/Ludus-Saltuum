extends UIButton

@export var owned_texture: Texture2D
@export var equipped_texture: Texture2D

var _player: PlayerEntity

@onready var _cosmetic: CharacterEntityAsset = owner.chosen_character
@onready var _price: int = _cosmetic.character_price
@onready var _ownership_icon: TextureRect = %OwnershipTextureRect


func _button_ready() -> void:
	text = str(_price)

	ApplicationStateManager.cosmetics_opened.connect(_update_button)


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

	var cosmetic_id: StringName = _cosmetic.character_id
	var already_owned: bool = _player.cosmetics_controller.owns(cosmetic_id)
	var is_equipped: bool = _player.cosmetics_controller.get_equipped_character_id() == cosmetic_id
	var can_afford: bool = _player.economy_controller.gold >= _price

	_ownership_icon.visible = already_owned
	if is_equipped:
		_ownership_icon.texture = equipped_texture
	elif already_owned:
		_ownership_icon.texture = owned_texture

	disabled = is_equipped or (not already_owned and not can_afford)


func _get_player() -> PlayerEntity:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	assert(not players.is_empty(), "Player missing for " + name)
	return players[0] as PlayerEntity
