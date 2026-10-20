extends Label


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	assert(version != "", "VersionLabel: application/config/version not set in project.godot")
	text = version

	if OS.is_debug_build():
		text += " debug"

	if OS.has_feature("web"):
		text += " web"

	if OS.has_feature("demo"):
		text += " demo"
