extends SceneTree

## Configures isolated storage and offline services before test-process autoloads start

const TEST_PROFILE: String = "res://tests/config/override.cfg"
const TEST_SCENE: String = "res://tests/unit_tests.tscn"
const TEST_DATA_DIRECTORY: String = "Ludus Saltuum Test Runs"


func _init() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var profile: ConfigFile = ConfigFile.new()
	if arguments.size() != 1 or not DirAccess.dir_exists_absolute(arguments[0]) or profile.load(TEST_PROFILE) != OK:
		OS.crash("Cannot initialize the isolated startup test profile in " + get_script().resource_path)

	for section: String in profile.get_sections():
		for key: String in profile.get_section_keys(section):
			ProjectSettings.set_setting(section.path_join(key), profile.get_value(section, key))

	var original_data_path: String = OS.get_user_data_dir()
	var test_root: String = arguments[0]
	OS.set_environment("XDG_DATA_HOME", test_root)
	if not OS.get_user_data_dir().begins_with(test_root + "/"):
		test_root = OS.get_data_dir().path_join(TEST_DATA_DIRECTORY)
		ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
		ProjectSettings.set_setting("application/config/custom_user_dir_name", TEST_DATA_DIRECTORY.path_join(arguments[0].get_file()))

	var test_data_path: String = OS.get_user_data_dir()
	if (
		test_data_path == original_data_path or not test_data_path.begins_with(test_root + "/")
		or DirAccess.make_dir_recursive_absolute(test_data_path) != OK
	):
		OS.crash("Cannot isolate startup test data in " + get_script().resource_path)
	OS.set_environment("LUDUS_TEST_DATA_DIR", test_root)


func _initialize() -> void:
	var error: Error = change_scene_to_file(TEST_SCENE)
	if error != OK:
		push_error("Cannot open startup test scene %s (%s)" % [TEST_SCENE, error])
		quit(1)
