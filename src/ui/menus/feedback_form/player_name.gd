extends Label

@onready var anonymous_feedback_toggle: CheckButton = %AnonymousFeedbackToggle


func _ready() -> void:
	if SteamWorks.steam_enabled:
		text = Steam.getPersonaName()
		visible = true
		anonymous_feedback_toggle.toggled.connect(_on_anonymous_feedback)


func _on_anonymous_feedback(toggled: bool) -> void:
	visible = !toggled
