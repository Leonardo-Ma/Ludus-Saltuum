# TODO Consider a better way to place this
class_name HUDView
extends Control

@onready var skills_panel: SkillsView = %SkillsPanel
@onready var player_healthbar: PlayerHealthbar = %PlayerHealthbar
@onready var power_ups: PowerUpView = %PowerUps
@onready var _score: ScoreView = %Score
@onready var _gold: GoldView = %Gold
@onready var _return_progress: ReturnCheckpointIndicator = %ReturnCheckpoingProgress

@onready var _jump_instructions: HBoxContainer = %JumpInstructions
@onready var _attack_instructions: HBoxContainer = %AttackInstructions
@onready var _vehicle_instructions: HBoxContainer = %VehicleInstructions
@onready var _look_around_instruction: HBoxContainer = %LookAroundInstructions


func _ready() -> void:
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_changed)
	_set_racing_hud(GameplayStateManager.is_in_mode(GameplayStateManager.GameplayMode.RACING))


func bind_player_features(
	economy: EconomyController,
	skills: SkillsController,
	input: InputController,
	health: HealthComponent,
	status: StatusManager,
) -> void:
	_score.bind_economy(economy)
	_gold.bind_economy(economy)
	skills_panel.bind_skills(skills)
	_return_progress.bind_input(input)
	player_healthbar.bind_health(health)
	power_ups.bind_status(status)


func _on_gameplay_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	_set_racing_hud(new_mode == GameplayStateManager.GameplayMode.RACING)


func _set_racing_hud(is_racing: bool) -> void:
	power_ups.visible = not is_racing
	player_healthbar.visible = not is_racing
	_jump_instructions.visible = not is_racing
	_attack_instructions.visible = not is_racing
	_look_around_instruction.visible = not is_racing
	_vehicle_instructions.visible = is_racing
