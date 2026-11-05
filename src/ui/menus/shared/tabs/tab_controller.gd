class_name TabController
extends Control

## Shows panel of last activated child TabButton of tab_container, hides the others

signal tab_changed(tab: TabButton)

@export var tab_container: Container


func _ready() -> void:
	assert(tab_container != null, "TabController: tab_container not assigned in " + name)
	var group: ButtonGroup = ButtonGroup.new()
	var first: TabButton = null

	for child: Node in tab_container.get_children():
		var tab: TabButton = child as TabButton
		if tab == null:
			continue
		tab.toggle_mode = true
		tab.button_group = group
		tab.tab_activated.connect(_on_tab_activated)
		if first == null:
			first = tab

	assert(first != null, "TabController: no TabButton children in " + name)
	first.button_pressed = true
	_on_tab_activated(first)


func _on_tab_activated(active_tab: TabButton) -> void:
	for child: Node in tab_container.get_children():
		var tab: TabButton = child as TabButton
		if tab != null:
			tab.panel.visible = tab.panel == active_tab.panel
	tab_changed.emit(active_tab)
