extends Node


func _ready() -> void:
	if not OS.is_debug_build() or not owner.should_tests_be_executed:
		queue_free()
		return

	# Wait one frame to ensure all systems are initialized
	await get_tree().process_frame
	_run_all_tests()


# Run tests on demand via console command
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		print("\n🔄 Re-running audio system tests...")
		_run_all_tests()


func _run_all_tests() -> void:
	print("\n========== AUDIO SYSTEM TEST ==========")

	_test_audio_buses()
	_test_volume_controls()

	print("========== ✅ AUDIO ==========\n")


# ============== INDIVIDUAL TESTS ==============
func _test_audio_buses() -> void:
	var required_buses: Array[String] = ["Master", "Music", "SFX", "UI"]

	var bus_indices: Dictionary = { }
	for i: int in range(AudioServer.get_bus_count()):
		bus_indices[AudioServer.get_bus_name(i)] = i

	for bus_name: String in required_buses:
		assert(bus_name in bus_indices, "Audio bus '%s' not found! Check AudioBusLayout (uid://plxel2xf671u)" % bus_name)
		assert(not AudioServer.is_bus_mute(bus_indices[bus_name]), "Audio bus '%s' is muted." % bus_name)

	var music_idx: int = bus_indices["Music"]
	assert(AudioServer.get_bus_send(music_idx) == "Master", "Music bus should send to Master bus.")

	print("✅ Audio buses")


func _test_volume_controls() -> void:
	var categories: Array[Dictionary] = [
		{ "enum": AudioManager.SoundBus.MASTER, "bus": "Master" },
		{ "enum": AudioManager.SoundBus.MUSIC, "bus": "Music" },
		{ "enum": AudioManager.SoundBus.SFX, "bus": "SFX" },
		{ "enum": AudioManager.SoundBus.UI, "bus": "UI" },
	]

	for cat: Dictionary in categories:
		var original_volume: float = AudioManager.get_bus_volume(cat.enum)
		var test_volume: float = -20.0

		AudioManager.set_bus_volume(cat.enum, test_volume)
		var new_volume: float = AudioManager.get_bus_volume(cat.enum)

		assert(abs(new_volume - test_volume) < 0.1, "Volume control broken for bus %s" % cat.bus)

		AudioManager.set_bus_volume(cat.enum, original_volume)

	AudioManager.mute_all()
	var master_idx: int = AudioServer.get_bus_index("Master")
	assert(AudioServer.is_bus_mute(master_idx), "mute_all() didn't mute Master bus")

	AudioManager.unmute_all()
	assert(not AudioServer.is_bus_mute(master_idx), "unmute_all() didn't unmute Master bus")

	print("✅ Volume controls")
