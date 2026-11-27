class_name BuyCosmeticButton
extends UIButton

## Displays purchase and equip state for one cosmetic

@export var owned_texture: Texture2D
@export var equipped_texture: Texture2D
@export var owned_icon_alignment: HorizontalAlignment
@export var affordable_font_color: Color
@export var unaffordable_font_color: Color

var _cosmetics: CosmeticsController
var _economy: EconomyController

@onready var _card: CosmeticCard = owner if owner is CosmeticCard else null
@onready var _purchase_icon: Texture2D = icon
@onready var _purchase_icon_alignment: HorizontalAlignment = icon_alignment


func _button_ready() -> void:
	if _card != null:
		_card.asset_changed.connect(_update_button)
	_update_button()


func _button_pressed() -> void:
	if not disabled and is_instance_valid(_cosmetics) and is_instance_valid(_economy) and _card != null and _card.asset != null:
		_cosmetics.buy_or_equip(_card.asset.cosmetic_id)


## Binds button to selected player's cosmetic and wallet state
func bind_player_features(economy: EconomyController, cosmetics: CosmeticsController) -> void:
	# TODO Find better way
	if is_instance_valid(_cosmetics):
		_cosmetics.equipped_changed.disconnect(_on_equipped_changed)
		_cosmetics.owned_changed.disconnect(_update_button)
	if is_instance_valid(_economy):
		_economy.gold_changed.disconnect(_on_gold_changed)
	_cosmetics = cosmetics
	_economy = economy
	if _cosmetics != null:
		_cosmetics.equipped_changed.connect(_on_equipped_changed)
		_cosmetics.owned_changed.connect(_update_button)
	if _economy != null:
		_economy.gold_changed.connect(_on_gold_changed)
	_update_button()


func _update_button() -> void:
	var asset: CosmeticAsset = _card.asset if _card != null else null
	if not is_instance_valid(_cosmetics) or not is_instance_valid(_economy) or asset == null:
		icon = _purchase_icon
		icon_alignment = _purchase_icon_alignment
		text = str(asset.price) if asset != null else ""
		remove_theme_color_override("font_color")
		remove_theme_color_override("font_disabled_color")
		disabled = true
		return

	var cosmetic_id: StringName = asset.cosmetic_id
	var already_owned: bool = _cosmetics.owns(cosmetic_id)
	var is_equipped: bool = _cosmetics.get_equipped_id(asset.get_slot()) == cosmetic_id
	var can_afford: bool = _economy.gold >= asset.price

	var font_color: Color = affordable_font_color if can_afford else unaffordable_font_color

	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_disabled_color", font_color)

	if already_owned or is_equipped:
		icon = equipped_texture if is_equipped else owned_texture
		text = ""
		icon_alignment = owned_icon_alignment
	else:
		icon = _purchase_icon
		icon_alignment = _purchase_icon_alignment
		text = str(asset.price)

	disabled = is_equipped or (not already_owned and not can_afford)


func _on_equipped_changed(_equipped: CosmeticAsset) -> void:
	_update_button()


func _on_gold_changed(_gold: int) -> void:
	_update_button()
