extends MarginContainer

# Dictionary to map collectible identifier (StringName) to its instantiated UI element (TextureRect)
var _counter_ui_elements: Dictionary = {}

@onready var collectibles_container: GridContainer = %CollectiblesContainer


func _ready() -> void:
	assert(collectibles_container != null, "CollectiblesInterface missing container child.")

	for child: Control in collectibles_container.get_children():
		var hbox: HBoxContainer = child as HBoxContainer
		if hbox:
			hbox.hide()
			# re-assign keys when actual identifiers come in
			_counter_ui_elements[StringName(hbox.name)] = hbox

	CollectiblesEvents.counter_collectible_collected.connect(_on_counter_collected)


# TODO This shouldn't be here
func _on_counter_collected(identifier: StringName, amount: int, icon: Texture2D) -> void:
	# If an UI element exists for this collectible, just update counter
	if _counter_ui_elements.has(identifier):
		var ui_node: HBoxContainer = _counter_ui_elements[identifier]
		var label: Label = ui_node.get_node("CounterLabel") as Label

		# Show the node if it was hidden
		if not ui_node.visible:
			ui_node.show()
			var collectible_icon: TextureRect = ui_node.get_node("Collectible") as TextureRect
			if collectible_icon:
				collectible_icon.texture = icon

		var current_count: int = label.text.to_int()
		var new_count: int = current_count + amount
		label.text = str(new_count)
	else:
		# If this is a newly discovered collectible, try to find an unused UI element
		var found_unused: bool = false
		for key: Variant in _counter_ui_elements.keys():
			var ui_node: HBoxContainer = _counter_ui_elements[key]
			if not ui_node.visible:
				# Re-bind this ui node to the new identifier
				_counter_ui_elements.erase(key)
				_counter_ui_elements[identifier] = ui_node

				ui_node.show()
				var collectible_icon: TextureRect = ui_node.get_node("Collectible") as TextureRect
				if collectible_icon:
					collectible_icon.texture = icon

				var label: Label = ui_node.get_node("CounterLabel") as Label
				label.text = str(amount)

				found_unused = true
				break

		assert(found_unused, "Ran out of pre-defined collectible UI elements in HUD for " + str(identifier))
