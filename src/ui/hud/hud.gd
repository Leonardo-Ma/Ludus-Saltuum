extends Control

@onready var skills_panel: VBoxContainer = %SkillsPanel
@onready var player_healthbar: ProgressBar = %PlayerHealthbar
@onready var power_ups: MarginContainer = %PowerUps
@onready var score: HBoxContainer = %Score
@onready var gold: HBoxContainer = %Gold


func _ready() -> void:
	ControlledEntityEvents.player_finished_spawning.connect(_on_player_finished_spawning)


func _on_player_finished_spawning(player: PlayerEntity) -> void:
	gold.setup(player.economy_controller)
	score.setup(player.economy_controller)


func setup(player: PlayerEntity) -> void:
	gold.setup(player.economy_controller)
	score.setup(player.economy_controller)
	player_healthbar.setup(player)


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
