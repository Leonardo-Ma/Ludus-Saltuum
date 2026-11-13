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

var _is_regenerating: bool = false
var _regen_buffer: float = 0.0
var _waiting_for_regen_delay: bool = false
var _last_damage_time: int = 0


func _ready() -> void:
	assert(health != null and health.max_health > 0, "Health property incorrect for " + owner.name)

	# TODO Confirm if this is correct
	max_health = health.max_health
	health_regen = health.health_regen
	current_health = max_health

	if _can_regenerate():
		start_regeneration()


func take_damage(attack: Attack) -> void:
	if invulnerable and not attack.hitkill:
		return

	if attack.hitkill:
		current_health = 0
	else:
		current_health -= attack.damage

	_last_damage_time = Time.get_ticks_msec()
	damaged.emit(attack)
	enable_invulnerability(health.invulnerability_duration)
	stop_regeneration()

	if current_health <= 0:
		died.emit()
	else:
		schedule_regeneration()


func reset() -> void:
	var was_dead: bool = current_health <= 0
	current_health = max_health
	if was_dead:
		revived.emit()
	stop_regeneration()
	disable_invulnerability()
	_waiting_for_regen_delay = false


func enable_invulnerability(duration: float = 0.0) -> void:
	invulnerable = true
	invulnerability_changed.emit(true)
	if duration > 0.0:
		get_tree().create_timer(duration).timeout.connect(disable_invulnerability)


func disable_invulnerability() -> void:
	invulnerable = false
	invulnerability_changed.emit(false)


func schedule_regeneration() -> void:
	if not _can_regenerate() or _waiting_for_regen_delay:
		return

	_waiting_for_regen_delay = true
	get_tree().create_timer(health.regen_delay).timeout.connect(start_regeneration)


func start_regeneration() -> void:
	_waiting_for_regen_delay = false

	if not _can_regenerate() or _is_regenerating:
		return

	var time_since_damage: float = (Time.get_ticks_msec() - _last_damage_time) / 1000.0
	if time_since_damage < health.regen_delay:
		_waiting_for_regen_delay = true
		get_tree().create_timer(health.regen_delay - time_since_damage).timeout.connect(start_regeneration)
		return

	_is_regenerating = true
	get_tree().create_timer(health.regen_tick_rate).timeout.connect(apply_regeneration_tick)


func stop_regeneration() -> void:
	_regen_buffer = 0.0
	_is_regenerating = false
	_waiting_for_regen_delay = false


func apply_regeneration_tick() -> void:
	if not _is_regenerating:
		return

	if current_health >= max_health:
		_is_regenerating = false
		return

	_regen_buffer += health_regen * health.regen_tick_rate
	var whole: int = int(_regen_buffer)
	_regen_buffer -= whole
	current_health += whole

	if current_health < max_health and health_regen > 0.0:
		get_tree().create_timer(health.regen_tick_rate).timeout.connect(apply_regeneration_tick)
	else:
		_is_regenerating = false


func _can_regenerate() -> bool:
	return health_regen > 0.0 and current_health < max_health
