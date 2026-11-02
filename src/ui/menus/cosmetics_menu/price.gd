extends Label

@onready var price: int = owner.chosen_character.character_price


func _ready() -> void:
	text = str(price)

	ApplicationStateManager.cosmetics_opened.connect(update_prices)


func update_prices() -> void:
	update_price_color()


func update_price_color() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	var player: PlayerEntity = players[0]
	if player.economy_controller.gold >= price:
		self_modulate = Color.GREEN

	self_modulate = Color.GRAY
