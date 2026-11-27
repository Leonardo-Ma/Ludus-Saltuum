class_name OverlaysView
extends Control

@onready var screen_transition: Control = %ScreenTransition
@onready var fade_rect: ColorRect = %FadeRect
@onready var _low_health: LowHealthOverlay = %LowHealthOverlay
@onready var _damage: DamageOverlay = %DamageOverlay
@onready var _cosmetics: CosmeticAvailableOverlay = %CosmeticAvailableOverlay
@onready var _environment_fade: EnvironmentFadeOverlay = %EnvironmentFade

var _fade_tween: Tween


func _ready() -> void:
	ControlledEntityEvents.player_respawning.connect(_on_player_respawning)
	ControlledEntityEvents.player_respawn_arrived.connect(_on_player_respawn_arrived)
	ControlledEntityEvents.player_finished_respawning.connect(_on_player_finished_respawning)
	visibility_changed.connect(_sync_environment_fade_visibility)
	_sync_environment_fade_visibility()


func bind_player_features(health: HealthComponent, cosmetics: CosmeticsController, transition: EnvironmentTransitionController) -> void:
	_low_health.bind_health(health)
	_damage.bind_health(health)
	_cosmetics.bind_cosmetics(cosmetics)
	_environment_fade.bind_transition(transition)


func _sync_environment_fade_visibility() -> void:
	_environment_fade.visible = is_visible_in_tree()


## Fade in and out effect, to solid color then back
func _on_player_respawning(duration: float) -> void:
	screen_transition.visible = true
	_kill_fade_tween()

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_fade_tween.tween_property(fade_rect, "modulate:a", 1.0, minf(duration, ControlledEntityEvents.RESPAWN_FADE_DURATION)).set_trans(Tween.TRANS_SINE)


func _on_player_respawn_arrived() -> void:
	_kill_fade_tween()

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_fade_tween.tween_property(fade_rect, "modulate:a", 0.0, ControlledEntityEvents.RESPAWN_FADE_DURATION).set_trans(Tween.TRANS_SINE)


func _on_player_finished_respawning() -> void:
	_kill_fade_tween()
	fade_rect.modulate.a = 0.0
	screen_transition.visible = false


func _kill_fade_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
