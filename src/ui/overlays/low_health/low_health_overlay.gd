class_name LowHealthOverlay
extends ColorRect

## Brief pulsing red tint while controlled player health is low

const LOW_HEALTH_RATIO: float = 0.3
const PULSE_IN_DURATION: float = 0.4
const PULSE_OUT_DURATION: float = 0.6
const PULSE_PAUSE_DURATION: float = 1.0
const FADE_OUT_DURATION: float = 0.3

var _health: Health
var _tween: Tween
var _is_pulsing: bool = false
var _is_racing: bool = false


func _ready() -> void:
	assert(material is ShaderMaterial, "ShaderMaterial missing in " + name)

	ControlledEntityEvents.player_finished_spawning.connect(_on_player_spawned)
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)

	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0])

	_set_vein_intensity(0.0)


func _on_player_spawned(player: Node3D) -> void:
	if _health != null:
		return

	var player_entity: PlayerEntity = player as PlayerEntity
	assert(player_entity != null, "PlayerEntity missing in " + name)

	_health = player_entity.health
	assert(_health != null, "Health missing in " + name)

	_health.health_changed.connect(_on_health_changed)
	_refresh()


func _on_health_changed(_new_health: int) -> void:
	_refresh()


func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	_is_racing = new_mode == GameplayStateManager.GameplayMode.RACING
	_refresh()


func _refresh() -> void:
	if _health == null:
		return

	var health_ratio: float = float(_health.current_health) / _health.max_health
	var is_low: bool = _health.current_health > 0 and health_ratio <= LOW_HEALTH_RATIO
	var should_pulse: bool = is_low and not _is_racing

	if should_pulse == _is_pulsing:
		return

	_is_pulsing = should_pulse

	if _tween != null:
		_tween.kill()

	_tween = create_tween()

	if should_pulse:
		_tween.set_loops()
		_tween.tween_method(_set_vein_intensity, 0.08, 0.15, PULSE_IN_DURATION).set_trans(Tween.TRANS_SINE)
		_tween.tween_method(_set_vein_intensity, 0.15, 0.08, PULSE_OUT_DURATION).set_trans(Tween.TRANS_SINE)
		_tween.tween_interval(PULSE_PAUSE_DURATION)
	else:
		_tween.tween_method(_set_vein_intensity, (material as ShaderMaterial).get_shader_parameter("intensity"), 0.0, FADE_OUT_DURATION)


func _set_vein_intensity(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter("intensity", value)
