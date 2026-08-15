extends Node


func _ready() -> void:
	# Wait one frame to ensure all systems are initialized
	await get_tree().process_frame
	_run_all_tests()


# Run tests on demand via console command
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		print("\n🔄 Re-running audio system tests...")
		_run_all_tests()


func _run_all_tests() -> void:
	print("\n========== AUDIO SYSTEM VERIFICATION ==========")

	_test_soundmanager_autoload()
	_test_subsystems_exist()
	_test_audio_buses()
	_test_soundpool_categories()
	_test_music_system()
	_test_combat_system()
	_test_volume_controls()

	print("========== ALL TESTS PASSED! ==========\n")


# ============== INDIVIDUAL TESTS ==============
func _test_soundmanager_autoload() -> void:
	assert(
		SoundManager != null,
		"SoundManager autoload not found! Add SoundManager.gd to Project Settings → Autoload",
	)

	print("✅ Test 1: SoundManager autoload")


func _test_subsystems_exist() -> void:
	assert(
		SoundManager.pool != null,
		"SoundManager.pool is null - SoundPool not created",
	)

	assert(
		SoundManager.music != null,
		"SoundManager.music is null - MusicController not created",
	)

	assert(
		SoundManager.combat != null,
		"SoundManager.combat is null - CombatPrioritySoundController not created",
	)

	print("✅ Test 2: Subsystems")


func _test_audio_buses() -> void:
	var required_buses: Array[String] = ["Master", "Music", "SFX", "Ambient", "UI", "Voice", "Vehicle"]

	assert(
		AudioServer.get_bus_count() == required_buses.size(),
		"Unexpected bus count: %d, expected %d" % [AudioServer.get_bus_count(), required_buses.size()],
	)

	var bus_indices: Dictionary = {}
	for i: int in range(AudioServer.get_bus_count()):
		bus_indices[AudioServer.get_bus_name(i)] = i

	for bus_name: String in required_buses:
		assert(bus_name in bus_indices, "Audio bus '%s' not found! Check AudioBusLayout (uid://plxel2xf671u)" % bus_name)
		assert(not AudioServer.is_bus_mute(bus_indices[bus_name]), "Audio bus '%s' is muted." % bus_name)

	for category: int in SoundManager.pool.BUSES:
		var bus_name: String = SoundManager.pool.BUSES[category]
		assert(bus_name in bus_indices, "SoundPool.BUSES defines category %d -> '%s', but that bus doesn't exist" % [category, bus_name])

	var music_idx: int = bus_indices["Music"]
	assert(AudioServer.get_bus_send(music_idx) == "Master", "Music bus should send to Master bus.")

	print("✅ Test 3: Audio buses")


func _test_soundpool_categories() -> void:
	var pool: SoundPool = SoundManager.pool

	var expected_categories: Array[int] = [
		SoundManager.SoundCategory.MUSIC,
		SoundManager.SoundCategory.SFX,
		SoundManager.SoundCategory.AMBIENT,
		SoundManager.SoundCategory.UI,
		SoundManager.SoundCategory.VOICE,
	]

	for category: int in expected_categories:
		assert(
			pool.CATEGORY_LIMITS.has(category),
			"SoundPool missing CATEGORY_LIMITS for category %d" % category,
		)

		var limit: int = pool.CATEGORY_LIMITS[category]
		assert(
			limit > 0,
			"Category %d has invalid limit: %d" % [category, limit],
		)

	assert(
		not pool._pools.is_empty(),
		"SoundPool._pools is empty - pools not initialized",
	)

	assert(
		not pool._active_players.is_empty(),
		"SoundPool._active_players is empty - tracking not initialized",
	)

	print("✅ Test 4: SoundPool categories")


func _test_music_system() -> void:
	var music: MusicController = SoundManager.music

	assert(
		music.MusicState != null,
		"MusicState enum not accessible",
	)

	assert(
		music._music_library != null,
		"music._music_library is null",
	)

	assert(
		music._current_player != null,
		"music._current_player not created",
	)

	assert(
		music._current_player.bus == "Music",
		"Music player not assigned to Music bus",
	)

	var test_volume: float = -15.0
	music.set_volume(test_volume)
	var actual_volume: float = music._current_player.volume_db
	assert(
		abs(actual_volume - test_volume) < 0.1,
		"Music volume not updating properly",
	)

	music.set_volume(-10.0)

	print("✅ Test 5: MusicController")


func _test_combat_system() -> void:
	var combat: CombatPrioritySoundController = SoundManager.combat

	assert(
		combat.Priority != null,
		"combat priority enum not accessible",
	)

	assert(
		combat._sound_pool != null,
		"CombatPrioritySoundController not initialized with SoundPool reference",
	)

	assert(
		combat._active_sounds != null,
		"CombatPrioritySoundController._active_sounds not initialized",
	)

	assert(
		combat._max_active_sounds > 0,
		"CombatPrioritySoundController._max_active_sounds not set",
	)

	print("✅ Test 6: CombatPrioritySoundController functional")


func _test_volume_controls() -> void:
	var categories: Array[Dictionary] = [
		{"enum": SoundManager.SoundCategory.GLOBAL, "bus": "Master"},
		{"enum": SoundManager.SoundCategory.MUSIC, "bus": "Music"},
		{"enum": SoundManager.SoundCategory.SFX, "bus": "SFX"},
		{"enum": SoundManager.SoundCategory.AMBIENT, "bus": "Ambient"},
		{"enum": SoundManager.SoundCategory.UI, "bus": "UI"},
		{"enum": SoundManager.SoundCategory.VOICE, "bus": "Voice"},
	]

	for cat: Dictionary in categories:
		var original_volume: float = SoundManager.get_category_volume(cat.enum)
		var test_volume: float = -20.0

		SoundManager.set_category_volume(cat.enum, test_volume)
		var new_volume: float = SoundManager.get_category_volume(cat.enum)

		assert(
			abs(new_volume - test_volume) < 0.1,
			"Volume control broken for category %s" % cat.bus,
		)

		SoundManager.set_category_volume(cat.enum, original_volume)

	SoundManager.mute_all()
	var master_idx: int = AudioServer.get_bus_index("Master")
	assert(
		AudioServer.is_bus_mute(master_idx),
		"mute_all() didn't mute Master bus",
	)

	SoundManager.unmute_all()
	assert(
		not AudioServer.is_bus_mute(master_idx),
		"unmute_all() didn't unmute Master bus",
	)

	print(
		"✅ Test 7: Volume controls",
	)
