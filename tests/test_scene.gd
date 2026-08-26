extends Node3D

@onready var unit_test_automatic_scripts: Node = %UnitTestAutomaticScripts


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	var tests_directory: DirAccess = DirAccess.open("res://tests/")
	assert(tests_directory != null, "Tests directory missing in " + self.name)

	var automatic_tests: Node = %UnitTestAutomaticScripts

	for file_name: String in tests_directory.get_files():
		if not file_name.ends_with(".gd") or file_name == "test_scene.gd":
			continue

		var test_script: GDScript = load("res://tests/" + file_name) as GDScript
		assert(test_script != null, "Failed to load test script in " + self.name)

		var found: bool = false

		for child: Node in automatic_tests.get_children():
			if child.get_script() == test_script:
				found = true
				break

		assert(found, "Test script " + file_name + " is not attached in " + self.name + ". Add new node and attach the test script")
