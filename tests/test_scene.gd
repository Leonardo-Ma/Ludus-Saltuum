extends Node

## Runs suites serially in an isolated project and fails on script errors

const TEST_DIRECTORY: String = "res://tests/"


class ScriptErrorLogger extends Logger:
	var _mutex: Mutex = Mutex.new()
	var _failed: bool = false


	func _log_error(
		_function: String,
		_file: String,
		_line: int,
		_code: String,
		_rationale: String,
		_editor_notify: bool,
		error_type: int,
		_script_backtraces: Array[ScriptBacktrace],
	) -> void:
		if error_type == Logger.ERROR_TYPE_SCRIPT:
			_mutex.lock()
			_failed = true
			_mutex.unlock()


	func has_failed() -> bool:
		_mutex.lock()
		var failed: bool = _failed
		_mutex.unlock()
		return failed


func _ready() -> void:
	var test_data_dir: String = OS.get_environment("LUDUS_TEST_DATA_DIR")
	if (
		not OS.is_debug_build() or not ProjectSettings.get_setting("testing/isolated_run", false)
		or test_data_dir.is_empty() or not OS.get_user_data_dir().begins_with(test_data_dir + "/") or SteamWorks.steam_enabled
		or not (SaveManager._cloud_backend is NullCloudSaveBackend) or not Talo.settings.offline_mode
	):
		push_error("Open %s with the isolated test profile documented in docs/architecture/unit_test.md" % name)
		get_tree().quit(1)
		return

	_run_suites.call_deferred()


func _run_suites() -> void:
	var error_logger: ScriptErrorLogger = ScriptErrorLogger.new()
	OS.add_logger(error_logger)

	# Wait one frame to ensure all systems are initialized
	await get_tree().process_frame

	var suite_files: PackedStringArray = []
	for file_name: String in DirAccess.get_files_at(TEST_DIRECTORY):
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_scene.gd":
			suite_files.append(file_name)

	var suites_run: int = 0
	for file_name: String in suite_files:
		var test_script: GDScript = load(TEST_DIRECTORY.path_join(file_name))
		if test_script == null or not test_script.can_instantiate():
			push_error("Cannot instantiate %s in %s" % [file_name, name])
			break

		var instance: Object = test_script.new()
		if not (instance is ProjectTest):
			instance.free()
			push_error("%s must extend ProjectTest in %s" % [file_name, name])
			break

		var suite: ProjectTest = instance
		suite.name = file_name.get_basename()
		add_child(suite)
		await suite.run_tests()
		suite.queue_free()
		if error_logger.has_failed():
			break
		suites_run += 1

	OS.remove_logger(error_logger)
	if suites_run > 0 and suites_run == suite_files.size() and not error_logger.has_failed():
		print("Project tests passed (%d suites)" % suites_run)
		get_tree().quit()
		return

	push_error("Project tests failed in %s after %d completed suites" % [name, suites_run])
	get_tree().quit(1)
