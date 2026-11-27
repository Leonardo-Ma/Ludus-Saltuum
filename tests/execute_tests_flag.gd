extends Node

## Runs isolated startup tests alongside gameplay in debug editor runs

const MAX_FAILURE_OUTPUT_LENGTH: int = 2000
const PROCESS_POLL_INTERVAL_SECONDS: float = 0.1

@export var run_tests_on_startup: bool = true

var _test_pid: int = -1

# fmt: off
func _ready() -> void:
	if not run_tests_on_startup or not OS.is_debug_build() or not OS.has_feature("editor"):
		return

	var test_directory: DirAccess = DirAccess.create_temp("ludus_tests")
	assert(test_directory != null, "Could not create test directory in " + name)
	var test_path: String = test_directory.get_current_dir()
	var log_path: String = test_path.path_join("godot.log")
	var arguments: PackedStringArray = [
		"--headless",
		"--fixed-fps", "60",
		"--path", ProjectSettings.globalize_path("res://"),
		"--log-file", log_path,
		"--script", "res://tests/startup_test_profile.gd",
		"--quit-after", "60000",
		"--", test_path,
	]
	print("Running isolated startup tests")
	var test_pid: int = OS.create_process(OS.get_executable_path(), arguments)
	assert(test_pid > 0, "Could not launch startup tests in " + name)
	_test_pid = test_pid
	while _test_pid == test_pid and OS.is_process_running(test_pid):
		await get_tree().create_timer(PROCESS_POLL_INTERVAL_SECONDS, true, false, true).timeout
	if _test_pid != test_pid:
		return

	var exit_code: int = OS.get_process_exit_code(test_pid)
	_test_pid = -1
	var report: String = FileAccess.get_file_as_string(log_path) if FileAccess.file_exists(log_path) else ""
	var passed_at: int = report.find("\nProject tests passed (")
	if exit_code == 0 and passed_at != -1:
		print(report.substr(passed_at + 1).get_slice("\n", 0).strip_edges())
		return

	push_error("Startup tests did not complete successfully in %s (exit code %d)\n%s" % [name, exit_code, report.right(MAX_FAILURE_OUTPUT_LENGTH)])
# fmt: on


func _exit_tree() -> void:
	if _test_pid > 0 and OS.is_process_running(_test_pid):
		OS.kill(_test_pid)
	_test_pid = -1
