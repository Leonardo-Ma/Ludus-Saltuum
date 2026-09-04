@icon("uid://c71vj0fgk7gfw") # heart.png

class_name Health
extends Resource

signal invulnerability_changed(active: bool)
signal max_health_changed(new_max_health: int)
signal health_changed(new_health: int)
signal damaged(attack: Attack)
signal died
signal revived

@export var max_health: int:
	set(val):
		max_health = val
		max_health_changed.emit(max_health)
		current_health = max_health
@export_range(0, 9999, 0.01, "suffix:health/second") var health_regen: float

var current_health: int = max_health:
	set(val):
		var prev: int = current_health
		current_health = clamp(val, 0, max_health)
		if current_health != prev:
			health_changed.emit(current_health)

var invulnerable: bool = false
var _timer_callback: Callable # Reference to entity's timer creation method
var _is_regenerating: bool = false
var _regen_tick_rate: float = 0.5 # Regenerate every 0.5 seconds
var _regen_delay: float = 15.0 # Seconds to wait after damage before regenerating
var _waiting_for_regen_delay: bool = false
var _last_damage_time: int = 0


func take_damage(attack: Attack) -> void:
	if invulnerable:
		return
	if attack.hitkill:
		current_health = 0
	else:
		current_health -= attack.damage

	_last_damage_time = Time.get_ticks_msec()
	damaged.emit(attack)
	enable_invulnerability(1.0)
	stop_regeneration() # Stop any active regen and reset delay
	if current_health <= 0:
		died.emit()
	else:
		schedule_regeneration()


# Revived warns HUD
func reset() -> void:
	var was_dead: bool = current_health <= 0
	current_health = max_health
	if was_dead:
		revived.emit()
	stop_regeneration()
	disable_invulnerability()
	_waiting_for_regen_delay = false


## Called by entity during _ready() to inject timer dependency
## Used to avoid _process
func initialize_timer_callback(callback: Callable) -> void:
	_timer_callback = callback
	start_regeneration()

#region Invulnerability
func enable_invulnerability(duration: float = 0.0) -> void:
	invulnerable = true
	invulnerability_changed.emit(true)
	if duration > 0 and _timer_callback.is_valid():
		# Ask the entity to create a timer
		_timer_callback.call(duration, disable_invulnerability)


func disable_invulnerability() -> void:
	invulnerable = false
	invulnerability_changed.emit(false)

#endregion

#region Health Regeneration

## Schedule regeneration to start after delay
func schedule_regeneration() -> void:
	if not _can_regenerate():
		return

	if not _waiting_for_regen_delay:
		_waiting_for_regen_delay = true
		_timer_callback.call(_regen_delay, start_regeneration)


func start_regeneration() -> void:
	_waiting_for_regen_delay = false

	if not _can_regenerate() or _is_regenerating:
		return

	var time_since_damage: float = (Time.get_ticks_msec() - _last_damage_time) / 1000.0
	if time_since_damage < _regen_delay:
		_waiting_for_regen_delay = true
		_timer_callback.call(_regen_delay - time_since_damage, start_regeneration)
		return

	_is_regenerating = true
	_timer_callback.call(_regen_tick_rate, apply_regeneration_tick)


func stop_regeneration() -> void:
	_is_regenerating = false
	_waiting_for_regen_delay = false


func apply_regeneration_tick() -> void:
	if not _is_regenerating:
		return

	if current_health >= max_health:
		_is_regenerating = false
		return

	current_health += int(health_regen * _regen_tick_rate)

	if current_health < max_health and health_regen > 0:
		_timer_callback.call(_regen_tick_rate, apply_regeneration_tick)
	else:
		_is_regenerating = false


func _can_regenerate() -> bool:
	return health_regen > 0 and _timer_callback.is_valid() and current_health < max_health
#endregion
