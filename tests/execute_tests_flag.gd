extends Node

## Launches the isolated test suite before opening gameplay in debug editor runs

@export var run_tests_on_startup: bool = true

# fmt: off
func _ready() -> void:
	if not run_tests_on_startup or not OS.is_debug_build() or not OS.has_feature("editor"):
		return

	var test_directory: DirAccess = DirAccess.create_temp("ludus_tests")
	assert(test_directory != null, "Could not create test directory in " + name)
	var test_path: String = test_directory.get_current_dir()
	var arguments: PackedStringArray = [
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--log-file", test_path.path_join("godot.log"),
		"--script", "res://tests/startup_test_profile.gd",
		"--quit-after", "60000",
		"--", test_path,
	]
	var output: Array[String] = []
	var exit_code: int = OS.execute(OS.get_executable_path(), arguments, output, true)
	var report: String = "".join(output)
	print(report)
	if exit_code != 0 or not report.contains("\nProject tests passed ("):
		push_error("Startup tests did not complete successfully in " + name)
# fmt: on
