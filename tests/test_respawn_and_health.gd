extends ProjectTest

## Exercises health timer restarts and respawn through player and vehicle entry points

const PLAYER_SCENE: PackedScene = preload("uid://dwxbechemu2kl") # player.tscn
const CAR_SCENE: PackedScene = preload("uid://c3c0sejgavc7h") # car.tscn
const BOUNDARY_SCENE: PackedScene = preload("uid://cf5ku6le2d84s") # floor_level_boundary.tscn
const OVERLAYS_SCENE: PackedScene = preload("uid://b7xvg4dfpcw5y") # overlays.tscn

var _death_count: int = 0


func run_tests() -> void:
	await _test_health()

	var music_state_changed: Callable = MusicCoordinator._on_game_state_changed
	ApplicationStateManager.state_changed.disconnect(music_state_changed)
	MusicController.stop(0.0)

	var world: Node3D = Node3D.new()
	var player: PlayerEntity = PLAYER_SCENE.instantiate()
	player.position = Vector3(8.0, 30.0, 12.0)
	world.add_child(player)
	player.owner = world
	var boundary: Area3D = BOUNDARY_SCENE.instantiate()
	world.add_child(boundary)
	var car: PlayerCar = CAR_SCENE.instantiate()
	car.position = Vector3(26.0, 30.0, 12.0)
	car.gravity_scale = 0.0
	world.add_child(car)
	var overlays: Control = OVERLAYS_SCENE.instantiate()
	world.add_child(overlays)
	get_tree().root.add_child(world)
	await get_tree().process_frame

	CheckpointManager.reset_checkpoint()
	ApplicationStateManager.request_play_from_save()
	await _test_first_death(player, boundary)
	await _test_overlapping_respawns(player, overlays)
	await _test_vehicle_falls(player, car, boundary)
	player.respawn(1.0, player.starting_transform)
	ApplicationStateManager.request_main_menu()
	assert(not player.is_respawning and not SaveManager.is_save_blocked(), "Leaving gameplay retained a respawn in " + name)
	var transition: Control = overlays.get_node("%ScreenTransition")
	assert(not transition.visible, "Leaving gameplay retained a fade in " + name)
	world.queue_free()
	await get_tree().process_frame
	ApplicationStateManager.state_changed.connect(music_state_changed)


func _test_health() -> void:
	var component: HealthComponent = HealthComponent.new()
	component.health = Health.new()
	component.health.max_health = 20
	component.health.invulnerability_duration = 0.15
	component.health.regen_delay = 0.2
	component.health.regen_tick_rate = 0.15
	component.health.health_regen = 20.0
	add_child(component)
	component.died.connect(_on_died)

	component.enable_invulnerability(0.1)
	component.enable_invulnerability(1.0)
	await _wait(0.18)
	assert(component.invulnerable, "Shorter timer ended replacement invulnerability in " + name)
	component.enable_invulnerability(0.1)
	component.reset()
	component.enable_invulnerability(1.0)
	await _wait(0.18)
	assert(component.invulnerable, "Previous life ended new invulnerability in " + name)

	var lethal: Attack = Attack.new()
	lethal.hitkill = true
	component.take_damage(lethal)
	component.take_damage(lethal)
	assert(_death_count == 1, "Repeated lethal hits emitted death more than once in " + name)
	component.reset()
	var hit: Attack = Attack.new()
	hit.damage = 5
	component.take_damage(hit)
	assert(component.current_health == 15, "Revived health ignored immediate damage in " + name)
	await _wait(0.26)
	component.reset()
	component.take_damage(hit)
	await _wait(0.18)
	assert(component.current_health == 15, "Old regeneration tick healed a new life in " + name)

	component.enable_invulnerability(0.1)
	PauseManager.request_pause("respawn_health_test")
	await _wait(0.4)
	assert(component.current_health == 15 and component.invulnerable, "Health timers advanced while paused in " + name)
	PauseManager.release_pause("respawn_health_test")
	await _wait(0.3)
	assert(component.current_health > 15 and not component.invulnerable, "Health timers did not resume in " + name)
	component.take_damage(lethal)
	assert(_death_count == 2, "New life did not emit its own death in " + name)
	component.queue_free()


func _test_first_death(player: PlayerEntity, boundary: Area3D) -> void:
	assert(not CheckpointManager.has_active_checkpoint(), "Expected an unset checkpoint in " + name)
	assert(CheckpointManager.get_respawn_transform().is_equal_approx(player.starting_transform), "Missing authored fall fallback in " + name)
	assert(is_equal_approx(boundary.global_position.y, player.starting_transform.origin.y - 30.0), "Fall plane did not initialize in " + name)
	var lethal: Attack = Attack.new()
	lethal.hitkill = true
	player.global_position.x += 5.0
	player.health.take_damage(lethal)
	assert(not player.input_controller.is_processing_input(), "Dead player retained input in " + name)
	await _wait(6.8)
	assert(player.health.current_health == player.health.max_health, "First death did not revive player in " + name)
	assert(is_equal_approx(player.global_position.x, player.starting_transform.origin.x), "First death missed authored spawn in " + name)
	assert(player.input_controller.is_processing_input(), "Player input did not return after respawn in " + name)


func _test_overlapping_respawns(player: PlayerEntity, overlays: Control) -> void:
	var fade_rect: ColorRect = overlays.get_node("%FadeRect")
	var first: Transform3D = player.starting_transform.translated(Vector3(5.0, 0.0, 0.0))
	var latest: Transform3D = player.starting_transform.translated(Vector3(11.0, 0.0, 0.0))
	var floor: StaticBody3D = StaticBody3D.new()
	floor.position = latest.origin - Vector3.UP * 0.75
	var floor_collision: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(4.0, 0.5, 4.0)
	floor_collision.shape = floor_shape
	floor.add_child(floor_collision)
	add_child(floor)

	player.respawn(0.1, first)
	player.respawn(0.4, latest)
	await _wait(0.2)
	assert(player.is_respawning and player.global_position.x != first.origin.x, "Superseded respawn reached its destination in " + name)
	var fade_opacity: float = fade_rect.modulate.a
	ApplicationStateManager.request_pause()
	await _wait(0.6)
	assert(player.is_respawning and player.global_position.x != latest.origin.x, "Respawn advanced while paused in " + name)
	assert(fade_opacity > 0.0 and fade_opacity < 1.0 and is_equal_approx(fade_rect.modulate.a, fade_opacity), "Fade advanced while paused in " + name)
	assert(not player.input_controller.is_processing_input() and SaveManager.is_save_blocked(), "Pause unlocked an unfinished respawn in " + name)
	ApplicationStateManager.request_resume()
	await ControlledEntityEvents.player_respawn_arrived
	assert(player.global_position.is_equal_approx(latest.origin), "Latest respawn missed its destination in " + name)
	Input.action_press(&"move_right")
	await _wait(0.4)
	Input.action_release(&"move_right")
	assert(player.is_respawning and not player.input_controller.is_processing_input(), "Input returned during fade-out in " + name)
	assert(is_equal_approx(player.global_position.x, latest.origin.x), "Movement input affected player during fade-out in " + name)
	assert(player.global_position.y < latest.origin.y and player.is_on_floor(), "Player did not fall and land during fade-out in " + name)
	await ControlledEntityEvents.player_finished_respawning
	assert(not player.is_respawning and player.input_controller.is_processing_input(), "Latest respawn left controls locked in " + name)
	assert(not SaveManager.is_save_blocked(), "Completed respawn kept saving blocked in " + name)
	floor.queue_free()


func _test_vehicle_falls(player: PlayerEntity, car: PlayerCar, boundary: Area3D) -> void:
	_drop_car(car, boundary)
	await _wait(0.8)
	assert(car.transform.is_equal_approx(car.initial_local_transform), "Unattended car missed its authored spawn in " + name)
	assert(not SaveManager.is_save_blocked(), "Unattended car started a player transition in " + name)

	car.enter_area.body_entered.emit(player)
	assert(car.is_driven and ControlledEntityEvents.controlled_entity == car, "Vehicle entry failed in " + name)
	_drop_car(car, boundary)
	await _wait(0.8)
	assert(car.freeze and SaveManager.is_save_blocked(), "Driven fall failed to start recovery in " + name)
	await _wait(2.4)
	assert(car.global_position.is_equal_approx(CheckpointManager.get_respawn_position()), "Driven car missed respawn destination in " + name)
	assert(car.is_driven and not car.freeze and car.is_physics_processing(), "Car did not resume driving in " + name)
	assert(
		player.state == PlayerEntity.PlayerState.IN_VEHICLE and not player.input_controller.is_processing_input(),
		"Vehicle fall restored on-foot controls in " + name,
	)
	car.exit(player.starting_transform.origin)


func _drop_car(car: PlayerCar, boundary: Area3D) -> void:
	car.global_position.y = boundary.global_position.y + 2.0
	car.linear_velocity = Vector3.DOWN * 6.0


func _on_died() -> void:
	_death_count += 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout
