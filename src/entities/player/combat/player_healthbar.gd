# https://www.youtube.com/watch?v=f90ieBOoIYQ DashNothing - How to Make a Great Health Bar in Godot 4 | Let's Godot
extends ProgressBar

var health: float = 0.0:
	set = _set_health

var health_resource: Health

@onready var timer: Timer = $Timer
@onready var damagebar: ProgressBar = %Damagebar
@onready var shatter_overlay: ColorRect = %ShatterOverlay


func _ready() -> void:
	assert(timer and damagebar and shatter_overlay, " Healthbar misconfigured")
	assert(shatter_overlay.material, "Shatter overlay must have a shatter effect shader as material")
	GameEvents.player_finished_spawning.connect(_on_player_spawned)
	timer.timeout.connect(_on_timer_timeout)

	var players: Array[Node] = get_tree().get_nodes_in_group(Groups.PLAYERS)
	if not players.is_empty():
		_on_player_spawned(players[0])


func _on_player_spawned(player: Node) -> void:
	if health_resource:
		return

	var player_entity: AggressiveEntity = player as AggressiveEntity
	if player_entity == null or player_entity.health == null:
		return

	health_resource = player_entity.health
	health_resource.damaged.connect(_on_damaged)
	health_resource.health_changed.connect(_on_health_changed)
	health_resource.died.connect(_on_death)

	# Initialize health bars in proper order to avoid clamping constraints
	max_value = health_resource.max_health
	damagebar.max_value = health_resource.max_health
	timer.wait_time *= 2.0

	# Explicitly call _set_health setter or do it dynamically via self
	self.health = health_resource.current_health


func _set_health(new_health: float) -> void:
	var prev_health: float = health
	health = clampf(new_health, 0, max_value)
	value = health

	if health < prev_health:
		timer.start()
	elif health > prev_health:
		if damagebar:
			damagebar.value = health


func _on_damaged(_attack: Attack) -> void:
	var tween: Tween = create_tween()
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_health_changed(new_health: int) -> void:
	if new_health > health:
		var tween: Tween = create_tween()
		modulate = Color(0.5, 2.0, 0.5, 1.0)
		tween.tween_property(self, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	self.health = new_health


# TODO Maybe add a 'broken' shape bar style when dead?
func _on_death() -> void:
	self.health = 0.0
	_on_death_visual_effect()


func _on_timer_timeout() -> void:
	# Animate damagebar down to match current health
	var tween: Tween = create_tween()
	tween.tween_property(damagebar, "value", health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# TODO Change this to actually use a broken glass texture progressing instead of tween
func _on_death_visual_effect() -> void:
	var shatter_material: ShaderMaterial = shatter_overlay.material
	shatter_overlay.visible = true
	shatter_material.set_shader_parameter("progress", 0.0)
	var tween: Tween = create_tween()
	tween.tween_method(func(v: float) -> void: shatter_material.set_shader_parameter("progress", v), 0.0, 1.0, 2.0)
	tween.tween_callback(func() -> void: shatter_overlay.visible = false)
