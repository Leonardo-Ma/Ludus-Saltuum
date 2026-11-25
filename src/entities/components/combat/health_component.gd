class_name HealthComponent
extends Node

## Manages entity health, invulnerability and regeneration
## Uses Health resource for initial configuration

signal invulnerability_changed(active: bool)
signal max_health_changed(new_max_health: int)
signal health_changed(new_health: int)
signal damaged(attack: Attack)
signal died
signal revived

@export var health: Health:
	set(val):
		health = val
		if health and is_node_ready():
			max_health = health.max_health
			health_regen = health.health_regen

var max_health: int:
	set(val):
		max_health = val
		max_health_changed.emit(max_health)
		if current_health > max_health:
			current_health = max_health
var health_regen: float = 3.0
var current_health: int:
	set(val):
		var prev: int = current_health
		current_health = clamp(val, 0, max_health)
		if current_health != prev:
			health_changed.emit(current_health)

var invulnerable: bool = false

var _regen_buffer: float = 0.0
var _invulnerability_timer: Timer
var _regen_delay_timer: Timer
var _regen_tick_timer: Timer


func _ready() -> void:
	assert(health and health.max_health > 0, "Health property incorrect for " + name)

	_invulnerability_timer = _create_timer(disable_invulnerability)
	_regen_delay_timer = _create_timer(start_regeneration)
	_regen_tick_timer = _create_timer(apply_regeneration_tick)

	# TODO Confirm if this is correct
	max_health = health.max_health
	health_regen = health.health_regen
	current_health = max_health


func take_damage(attack: Attack) -> void:
	if current_health <= 0 or (invulnerable and not attack.hitkill):
		return

	stop_regeneration()
	var remaining_health: int = 0 if attack.hitkill else current_health - attack.damage
	current_health = remaining_health
	damaged.emit(attack)
	if remaining_health <= 0 and current_health <= 0:
		disable_invulnerability()
		died.emit()
	elif current_health > 0:
		if health.invulnerability_duration > 0.0:
			enable_invulnerability(health.invulnerability_duration)
		schedule_regeneration()


func reset() -> void:
	var was_dead: bool = current_health <= 0
	stop_regeneration()
	disable_invulnerability()
	current_health = max_health
	if was_dead:
		revived.emit()


func enable_invulnerability(duration: float = 0.0) -> void:
	_invulnerability_timer.stop()
	if duration > 0.0:
		_invulnerability_timer.start(duration)
	if not invulnerable:
		invulnerable = true
		invulnerability_changed.emit(true)


func disable_invulnerability() -> void:
	_invulnerability_timer.stop()
	if invulnerable:
		invulnerable = false
		invulnerability_changed.emit(false)


func schedule_regeneration() -> void:
	if not _can_regenerate():
		return

	if health.regen_delay > 0.0:
		_regen_delay_timer.start(health.regen_delay)
	else:
		start_regeneration()


func start_regeneration() -> void:
	if _can_regenerate() and _regen_delay_timer.is_stopped() and _regen_tick_timer.is_stopped():
		_regen_tick_timer.start(health.regen_tick_rate)


func stop_regeneration() -> void:
	_regen_buffer = 0.0
	_regen_delay_timer.stop()
	_regen_tick_timer.stop()


func apply_regeneration_tick() -> void:
	if not _can_regenerate():
		stop_regeneration()
		return

	_regen_buffer += health_regen * _regen_tick_timer.wait_time
	var whole: int = int(_regen_buffer)
	_regen_buffer -= whole
	current_health += whole

	if _can_regenerate():
		start_regeneration()
	else:
		stop_regeneration()


func _can_regenerate() -> bool:
	return health_regen > 0.0 and current_health > 0 and current_health < max_health


func _create_timer(on_timeout: Callable) -> Timer:
	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	timer.timeout.connect(on_timeout)
	add_child(timer)
	return timer
