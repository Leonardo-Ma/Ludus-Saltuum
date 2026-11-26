extends ProjectTest

## Exercises attack input, animation timing and hit delivery through authored player scene

const PLAYER: PackedScene = preload("uid://dwxbechemu2kl") # player.tscn
const FAST_WEAPON: WeaponAsset = preload("uid://cr636gvdsdnu3") # stone_katana.tres
const SLOW_WEAPON: WeaponAsset = preload("uid://6m8vbwphmr1c") # stone_spiked_club.tres

var _accepted: int = 0
var _attack_sounds: int = 0
var _hit_source: Node3D


func run_tests() -> void:
	var music_state_changed: Callable = MusicCoordinator._on_game_state_changed
	ApplicationStateManager.state_changed.disconnect(music_state_changed)
	MusicController.stop(0.0)
	var was_paused: bool = get_tree().paused

	var floor: StaticBody3D = StaticBody3D.new()
	var floor_collision: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(24.0, 1.0, 24.0)
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.5
	floor.add_child(floor_collision)
	add_child(floor)

	var player: PlayerEntity = PLAYER.instantiate()
	var animation: AnimationController = player.get_node("%AnimationController")
	# Use a deterministic combo to exercise every authored variant
	animation.profile = animation.profile.duplicate()
	var actions: Array[AnimationActionDefinition] = animation.profile.actions.duplicate()
	for index: int in actions.size():
		if actions[index].id == AnimKeys.MELEE:
			actions[index] = actions[index].duplicate()
			actions[index].variant_mode = AnimationActionDefinition.VariantMode.SEQUENTIAL
	animation.profile.actions = actions
	player.position.y = 0.2
	add_child(player)
	player.melee_attacked.connect(
		func() -> void:
			_accepted += 1,
	)
	var tree: AnimationTree = player.get_node("%AnimationTree")

	player.input_controller.attack_pressed.emit()
	assert(_accepted == 0 and player.attack_component.can_attack(), "Inactive input spent cooldown in " + name)
	ApplicationStateManager.request_play_from_save()
	await player.player_movement_controller.landed
	assert(player.is_on_floor(), "Player did not land in " + name)
	await _test_shift_strafe(tree, player.player_movement_controller)
	await _test_rejection_and_interruption(player, animation)
	await _test_timing_and_damage(player, animation)
	await _test_airborne_attack(player, animation, tree)
	var projectile: Projectile = _test_projectile_source(player)
	await _test_lifecycle(player, animation)

	ApplicationStateManager.request_main_menu()
	if not was_paused:
		PauseManager.release_pause("gameplay")
	player.queue_free()
	await get_tree().process_frame
	var projectile_hitbox: Hitbox = projectile.get_node("%Hitbox")
	assert(not projectile_hitbox.source_override and projectile_hitbox.owner == projectile, "Projectile lost its source when caster left in " + name)
	projectile.queue_free()
	ApplicationStateManager.state_changed.connect(music_state_changed)
	print("Melee combat test completed")


func _test_rejection_and_interruption(player: PlayerEntity, animation: AnimationController) -> void:
	assert(animation.request_action(AnimKeys.MAGIC), "Could not occupy full-body layer in " + name)
	player.input_controller.attack_pressed.emit()
	assert(_accepted == 0 and player.attack_component.can_attack(), "Busy animation spent cooldown in " + name)
	animation.abort_action(AnimKeys.MAGIC)

	player.input_controller.attack_pressed.emit()
	assert(_accepted == 1 and not player.attack_component.can_attack(), "Accepted input missed cooldown in " + name)
	var rate: float = player.attack.rate
	var elapsed: float = 0.0
	while player.hitbox.animated_shape.disabled and elapsed < rate:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	assert(not player.hitbox.animated_shape.disabled, "Swing never opened hitbox in " + name)
	animation.set_airborne(true)
	assert(not animation.is_action_running(AnimKeys.MELEE) and player.hitbox.attack == null, "Interruption retained a swing in " + name)
	await get_tree().process_frame
	elapsed += get_process_delta_time()
	assert(player.hitbox.animated_shape.disabled, "Interruption left the shape enabled in " + name)
	animation.set_airborne(false)
	player.input_controller.attack_pressed.emit()
	assert(_accepted == 1, "Interruption bypassed cooldown in " + name)
	# SceneTree timers update after process_frame
	while not player.attack_component.can_attack() and elapsed <= rate + get_process_delta_time():
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	assert(player.attack_component.can_attack(), "Interrupted swing exceeded configured cooldown in " + name)


func _test_timing_and_damage(player: PlayerEntity, animation: AnimationController) -> void:
	var target: Node3D = Node3D.new()
	var health: HealthComponent = HealthComponent.new()
	health.health = Health.new()
	health.health.max_health = 100
	target.add_child(health)
	var hurtbox: Hurtbox = Hurtbox.new()
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 32768
	hurtbox.health = health
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	collision.shape = shape
	hurtbox.add_child(collision)
	var separate_branch: Node3D = Node3D.new()
	separate_branch.add_child(hurtbox)
	target.add_child(separate_branch)
	hurtbox.owner = target
	hurtbox.hit_received.connect(
		func(source: Node3D) -> void:
			_hit_source = source,
	)
	add_child(target)
	target.global_position = player.hitbox.animated_shape.global_position

	var variants: Array[StringName] = [&"slice_horizontal", &"stab", &"slice_diagonal"]
	var tree: AnimationTree = player.get_node("%AnimationTree")
	for index: int in variants.size():
		var weapon: WeaponAsset = SLOW_WEAPON if index == 1 else FAST_WEAPON
		player.weapon_controller.equip_weapon(weapon)
		var attack: Attack = player.attack
		var expected_accepted: int = _accepted + 1
		var expected_health: int = health.max_health - attack.damage
		health.reset()
		_hit_source = null
		player.input_controller.attack_pressed.emit()
		assert(_accepted == expected_accepted and player.hitbox.attack == attack, "Next swing was not accepted in " + name)
		player.weapon_controller.equip_weapon(SLOW_WEAPON if weapon == FAST_WEAPON else FAST_WEAPON)
		var elapsed: float = 0.0
		var frame: float = get_process_delta_time()
		while animation.is_action_running(AnimKeys.MELEE) and elapsed <= attack.rate + frame * 3.0:
			await get_tree().process_frame
			elapsed += get_process_delta_time()
		assert(not animation.is_action_running(AnimKeys.MELEE), "Swing exceeded attack rate in " + name)
		assert(tree.get(&"parameters/full_body_select/current_state") == variants[index], "Expected different swing variant in " + name)
		assert(absf(elapsed - attack.rate) <= frame * 3.0, "Swing took %f instead of %f seconds in %s" % [elapsed, attack.rate, name])
		assert(health.current_health == expected_health and _hit_source == player, "Swing lost accepted damage or source in " + name)
		await get_tree().process_frame
		assert(player.attack_component.can_attack() and player.hitbox.animated_shape.disabled, "Swing did not release cooldown and hitbox in " + name)
	assert(animation.request_action(AnimKeys.MAGIC), "Could not request magic after melee in " + name)
	assert(tree.get(AnimParams.layer_speed(AnimationActionDefinition.Layer.FULL_BODY)) == 1.0, "Magic inherited melee speed in " + name)
	animation.abort_action(AnimKeys.MAGIC)
	target.queue_free()


func _test_airborne_attack(player: PlayerEntity, animation: AnimationController, tree: AnimationTree) -> void:
	var jump_chop_shape: CollisionShape3D = player.get_node("%JumpChopShape")
	AudioManager.sound_played.connect(_on_attack_sound)
	for attempt: int in 2:
		player.movement.jump(player.movement.get_jump_velocity())
		await player.movement.in_air
		assert(not player.is_on_floor(), "Jump left player grounded in " + name)

		var expected_accepted: int = _accepted + 1
		var expected_sounds: int = _attack_sounds + 1
		player.input_controller.attack_pressed.emit()
		assert(
			_accepted == expected_accepted and player.hitbox.attack == player.attack,
			"Airborne attack was not armed in %s on attempt %d" % [name, attempt + 1],
		)
		player.input_controller.attack_pressed.emit()
		assert(_accepted == expected_accepted, "Airborne attack bypassed cooldown in " + name)

		var collision_checked: bool = false
		while animation.is_action_running(AnimKeys.MELEE):
			await get_tree().process_frame
			assert(player.hitbox.animated_shape.disabled, "Airborne attack opened ground hitbox in " + name)
			if not collision_checked and not jump_chop_shape.disabled and _hitbox_contains(player.hitbox, jump_chop_shape.position):
				assert(not _hitbox_contains(player.hitbox, Vector3(0.0, 0.7, 0.8)), "Jump chop reached behind player in " + name)
				collision_checked = true
				if attempt == 1:
					player.interrupt_melee_attack()
		await get_tree().process_frame
		assert(tree.get(&"parameters/full_body_select/current_state") == &"jump_chop", "Airborne attack selected another clip in " + name)
		assert(collision_checked and jump_chop_shape.disabled and player.hitbox.attack == null, "Jump chop hitbox did not close in " + name)
		assert(_attack_sounds == expected_sounds, "Airborne attack sound did not play once in " + name)

		while not player.is_on_floor() or not player.attack_component.can_attack():
			await get_tree().process_frame
	AudioManager.sound_played.disconnect(_on_attack_sound)


func _hitbox_contains(hitbox: Hitbox, local_point: Vector3) -> bool:
	var query: PhysicsPointQueryParameters3D = PhysicsPointQueryParameters3D.new()
	query.position = hitbox.to_global(local_point)
	query.collision_mask = hitbox.collision_layer
	query.collide_with_bodies = false
	query.collide_with_areas = true
	for result: Dictionary in hitbox.get_world_3d().direct_space_state.intersect_point(query):
		if result[&"collider"] == hitbox:
			return true
	return false


func _on_attack_sound(_position: Vector3) -> void:
	_attack_sounds += 1


func _test_projectile_source(player: PlayerEntity) -> Projectile:
	var attack: ProjectileAttack = player.projectile_attack_component.projectile_attack
	var projectile: Projectile = attack.projectile_scene.instantiate()
	projectile.position = Vector3.UP * 30.0
	add_child(projectile)
	projectile.launch(attack, player, Vector3.FORWARD)
	projectile.set_physics_process(false)
	var hitbox: Hitbox = projectile.get_node("%Hitbox")
	assert(hitbox.source_override == player, "Projectile lost caster attribution in " + name)
	var health_before: int = player.health.current_health
	player.hurtbox.area_entered.emit(hitbox)
	assert(player.health.current_health == health_before and not projectile.is_queued_for_deletion(), "Projectile hit its caster in " + name)
	return projectile


func _test_lifecycle(player: PlayerEntity, animation: AnimationController) -> void:
	player.disable_entity()
	player.input_controller.attack_pressed.emit()
	assert(player.attack_component.can_attack() and not animation.is_action_running(AnimKeys.MELEE), "Disabled entity could attack in " + name)
	player.revive()
	player.respawn(PlayerRespawnController.CHECKPOINT_RETURN_DELAY, player.global_transform)
	player.input_controller.attack_pressed.emit()
	assert(player.attack_component.can_attack() and not animation.is_action_running(AnimKeys.MELEE), "Respawn startup spent cooldown in " + name)
	await ControlledEntityEvents.player_respawn_arrived
	player.input_controller.attack_pressed.emit()
	assert(player.attack_component.can_attack() and not animation.is_action_running(AnimKeys.MELEE), "Respawn fade spent cooldown in " + name)
	await ControlledEntityEvents.player_finished_respawning

	player.input_controller.attack_pressed.emit()
	assert(animation.is_action_running(AnimKeys.MELEE), "Respawn blocked next valid swing in " + name)
	var lethal: Attack = Attack.new()
	lethal.hitkill = true
	player.health.take_damage(lethal)
	assert(player.hitbox.attack == null and not animation.is_action_running(AnimKeys.MELEE), "Death retained an active swing in " + name)
	assert(not player.input_controller.is_processing_input(), "Death left input enabled in " + name)
	player.attack_component.reset_cooldown()
	player.input_controller.attack_pressed.emit()
	assert(player.attack_component.can_attack() and not animation.is_action_running(AnimKeys.MELEE), "Dead input spent cooldown in " + name)


func _test_shift_strafe(tree: AnimationTree, movement: PlayerMovementComponent) -> void:
	var blend_path: StringName = AnimParams.blend_position(AnimKeys.STANDING)
	for key: Key in [KEY_A, KEY_D]:
		_send_key(KEY_SHIFT, true, true)
		_send_key(key, true, true)
		_send_key(KEY_W, true, true)
		await movement.movement_direction_changed
		var diagonal: Vector2 = tree.get(blend_path)
		_send_key(KEY_W, false, true)
		await movement.movement_direction_changed
		var lateral: Vector2 = tree.get(blend_path)
		_send_key(key, false, true)
		_send_key(KEY_SHIFT, false, false)
		await movement.movement_direction_changed
		var idle: Vector2 = tree.get(blend_path)
		assert(
			diagonal.length() > 0.9 and lateral.length() > 0.9 and not diagonal.is_equal_approx(lateral),
			"Shift sequence did not update movement blend in " + name,
		)
		assert(idle.is_zero_approx(), "Shift sequence retained movement blend after release in " + name)
	print("Shift strafe regression test completed")


func _send_key(key: Key, pressed: bool, shift: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = pressed
	event.shift_pressed = shift
	Input.parse_input_event(event)
	Input.flush_buffered_events()
