# TODO Change to use a centralized autoload that already identify player or anonymous
## Handles feedback identity, analytics, and submission
extends UIButton

const INTERNAL_FEEDBACK_CATEGORY: String = "feedback_form"
const SUCCESS_OVERLAY_DURATION: float = 10.0

@onready var feedback_text_input: TextEdit = %FeedbackTextInput
@onready var anonymous_feedback_toggle: CheckButton = %AnonymousFeedbackToggle

@onready var like_button: Button = %LikeButton
@onready var dislike_button: Button = %DislikeButton

@onready var sucess_overlay: PanelContainer = %SucessOverlay
@onready var success_overlay_timer: Timer = %SuccessOverlayTimer

var _is_submitting: bool = false


func _button_ready() -> void:
	sucess_overlay.hide()
	success_overlay_timer.timeout.connect(_on_success_overlay_timer_timeout)


func _button_pressed() -> void:
	if _is_submitting:
		return

	_is_submitting = true

	var feedback_text: String = feedback_text_input.text
	var feedback_props: Dictionary[String, String] = gather_analytics()

	await _identify_feedback_player()

	var result: FeedbackAPI.FeedbackSendResult = await Talo.feedback.send(INTERNAL_FEEDBACK_CATEGORY, feedback_text, feedback_props)

	_handle_submission_result(result)
	_is_submitting = false


func _identify_feedback_player() -> void:
	var current_alias: Variant = Talo.current_alias

	if anonymous_feedback_toggle.button_pressed or not SteamWorks.steam_enabled:
		if current_alias != null and current_alias.service == "anonymous":
			return

		await Talo.players.identify("anonymous", Talo.players.generate_identifier())
		return

	var identifier: String = SteamWorks.get_persona_name()

	if current_alias != null and current_alias.service == "username" and current_alias.identifier == identifier:
		return

	await Talo.players.identify("username", identifier)


func _handle_submission_result(result: FeedbackAPI.FeedbackSendResult) -> void:
	if not result.success:
		for prop: TaloRejectedProp in result.rejected_props:
			print("Rejected prop '%s': %s (%s)" % [prop.key, prop.message, prop.code])
		return

	print("Feedback sent for %s" % INTERNAL_FEEDBACK_CATEGORY)
	_show_success_overlay()


func _show_success_overlay() -> void:
	sucess_overlay.show()
	success_overlay_timer.start(SUCCESS_OVERLAY_DURATION)


func _on_success_overlay_timer_timeout() -> void:
	sucess_overlay.hide()


func gather_analytics() -> Dictionary[String, String]:
	var feedback_props: Dictionary[String, String]

	var game_version: String = str(ProjectSettings.get_setting("application/config/version"))
	feedback_props["game_version"] = game_version

	if like_button.button_pressed:
		feedback_props["like_dislike"] = "like"
	elif dislike_button.button_pressed:
		feedback_props["like_dislike"] = "dislike"

	var game_type: String = "full_game"
	if OS.has_feature("demo"):
		game_type = "demo"
	feedback_props["game_type"] = game_type

	var playtime_minutes: float = GameplayStateManager.get_play_time() / 60
	if playtime_minutes > 0.0:
		feedback_props["playtime_minutes"] = str(playtime_minutes)

	var input_device: String = str(InputManager.active_device)
	feedback_props["input_device"] = input_device

	var platform: String = OS.get_name().to_lower()
	feedback_props["platform"] = platform

	return feedback_props
