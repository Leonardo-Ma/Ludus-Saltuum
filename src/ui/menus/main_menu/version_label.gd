extends Label


func _ready() -> void:
	var version: String = ProjectSettings.get_setting("application/config/version")
	assert(version != "", "VersionLabel: application/config/version not set in project.godot")
	self.text = version
