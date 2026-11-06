# TODO Consider a better way to place this
extends Control

@onready var skills_panel: VBoxContainer = %SkillsPanel
@onready var player_healthbar: ProgressBar = %PlayerHealthbar
@onready var power_ups: MarginContainer = %PowerUps

@onready var _jump_instructions: HBoxContainer = %JumpInstructions
@onready var _attack_instructions: HBoxContainer = %AttackInstructions
@onready var _vehicle_instructions: HBoxContainer = %VehicleInstructions
@onready var _look_around_instruction: HBoxContainer = %LookAroundInstructions


func _ready() -> void:
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_changed)
	_set_racing_prompts(GameplayStateManager.is_in_mode(GameplayStateManager.GameplayMode.RACING))


func _on_gameplay_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		skills_panel.hide()
		power_ups.hide()
		player_healthbar.hide()
		_set_racing_prompts(true)
	else:
		skills_panel.show()
		power_ups.show()
		player_healthbar.show()
		_set_racing_prompts(false)


func _set_racing_prompts(is_racing: bool) -> void:
	_jump_instructions.visible = not is_racing
	_attack_instructions.visible = not is_racing
	_look_around_instruction.visible = not is_racing
	_vehicle_instructions.visible = is_racing
