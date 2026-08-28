## Shows the panel for whichever tab last fired tab_activated
class_name OptionsTabController
extends VBoxContainer

signal active_section_changed(section: SettingsManager.SettingsSection)

@export var tab_container: HBoxContainer


func _ready() -> void:
	assert(tab_container != null, "OptionsTabController: tab_container not assigned in " + name)
	var group: ButtonGroup = ButtonGroup.new()
	var first: SettingsTabButton = null

	for tab: Node in tab_container.get_children():
		if tab is not SettingsTabButton:
			continue
		tab.toggle_mode = true
		tab.button_group = group
		tab.tab_activated.connect(_on_tab_activated)
		if first == null:
			first = tab

	assert(first != null, "OptionsTabController: no SettingsTabButton children in " + name)
	first.button_pressed = true
	_on_tab_activated(first.panel, first.section)


func _on_tab_activated(active_panel: VBoxContainer, section: SettingsManager.SettingsSection) -> void:
	for tab: Node in tab_container.get_children():
		if tab is SettingsTabButton:
			tab.panel.visible = tab.panel == active_panel
	active_section_changed.emit(section)
