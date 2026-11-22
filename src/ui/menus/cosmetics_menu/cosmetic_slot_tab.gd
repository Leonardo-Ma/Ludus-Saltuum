@tool
class_name CosmeticSlotTab
extends HFlowContainer

## Builds one CosmeticCard per asset of slot_catalog, ordered by price

@export var slot_catalog: CosmeticSlotCatalog:
	set(value):
		if slot_catalog != null and slot_catalog.changed.is_connected(_rebuild):
			slot_catalog.changed.disconnect(_rebuild)
		slot_catalog = value
		if slot_catalog != null:
			slot_catalog.changed.connect(_rebuild)
		_rebuild()
@export var card_scene: PackedScene:
	set(value):
		card_scene = value
		_rebuild()
@export_tool_button("Rebuild", "Reload") var rebuild_action: Callable = _rebuild


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return

	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

	if slot_catalog == null or card_scene == null:
		return

	for asset: CosmeticAsset in slot_catalog.get_assets_by_price():
		var card: CosmeticCard = card_scene.instantiate() as CosmeticCard
		assert(card != null, "card_scene root must be CosmeticCard in " + name)
		card.asset = asset
		add_child(card)
