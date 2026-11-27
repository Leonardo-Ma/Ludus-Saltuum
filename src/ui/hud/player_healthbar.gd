class_name PlayerHealthbar
extends ProgressBar

var health: float = 0.0:
	set = _set_health

var health_resource: HealthComponent
var _damage_tween: Tween
var _shatter_tween: Tween
var _flash_tween: Tween

@onready var timer: Timer = $Timer
@onready var damagebar: ProgressBar = %Damagebar
@onready var shatter_overlay: ColorRect = %ShatterOverlay


func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time *= 2.0
	GameplayStateManager.gameplay_mode_changed.connect(_on_gameplay_mode_changed)


func bind_health(source: HealthComponent) -> void:
	if is_instance_valid(health_resource):
		health_resource.damaged.disconnect(_on_damaged)
		health_resource.health_changed.disconnect(_on_health_changed)
		health_resource.died.disconnect(_on_death)
	health_resource = source
	if source != null:
		source.damaged.connect(_on_damaged)
		source.health_changed.connect(_on_health_changed)
		source.died.connect(_on_death)

	# Initialize health bars in proper order to avoid clamping constraints
	max_value = float(source.max_health) if source != null else 100.0
	damagebar.max_value = max_value
	for tween: Tween in [_damage_tween, _shatter_tween, _flash_tween]:
		if tween != null:
			tween.kill()
	modulate = Color.WHITE
	shatter_overlay.hide()

	# Explicitly call _set_health setter or do it dynamically via self
	self.health = float(source.current_health) if source != null else 0.0
	timer.stop()
	damagebar.value = health


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
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_health_changed(new_health: int) -> void:
	if new_health > health:
		if _flash_tween != null:
			_flash_tween.kill()
		_flash_tween = create_tween()
		modulate = Color(0.5, 2.0, 0.5, 1.0)
		_flash_tween.tween_property(self, "modulate", Color.WHITE, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	self.health = new_health


func _on_death() -> void:
	self.health = 0.0
	_on_death_visual_effect()


#region VFX
func _on_timer_timeout() -> void:
	# Animate damagebar down to match current health
	if _damage_tween != null:
		_damage_tween.kill()
	_damage_tween = create_tween()
	_damage_tween.tween_property(damagebar, "value", health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# TODO Change this to actually use a broken glass texture progressing instead of tween
func _on_death_visual_effect() -> void:
	var shatter_material: ShaderMaterial = shatter_overlay.material
	if shatter_material == null:
		return
	if _shatter_tween != null:
		_shatter_tween.kill()
	shatter_overlay.visible = true
	shatter_material.set_shader_parameter("progress", 0.0)
	_shatter_tween = create_tween()
	_shatter_tween.tween_method(
		func(v: float) -> void:
			shatter_material.set_shader_parameter("progress", v),
		0.0,
		1.0,
		2.0,
	)
	_shatter_tween.tween_callback(
		func() -> void:
			shatter_overlay.visible = false,
	)
#endregion


func _on_gameplay_mode_changed(new_mode: GameplayStateManager.GameplayMode, _previous_mode: GameplayStateManager.GameplayMode) -> void:
	if new_mode == GameplayStateManager.GameplayMode.RACING:
		visible = false
	else:
		visible = true
