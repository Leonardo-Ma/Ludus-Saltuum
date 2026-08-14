extends Control

@onready var skills_panel: VBoxContainer = %SkillsPanel
@onready var player_healthbar: ProgressBar = %PlayerHealthbar
@onready var power_ups: MarginContainer = %PowerUps


func _ready() -> void:
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_changed)


@warning_ignore("unused_parameter")
func _on_gameplay_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		skills_panel.hide()
		power_ups.hide()
		player_healthbar.hide()
	else:
		skills_panel.show()
		power_ups.show()
		player_healthbar.show()
