class_name XboxMap
extends GamepadMap

const _BUTTONS: Dictionary = {
	# Button
	JoyButton.JOY_BUTTON_A: preload("uid://dpx55g5ymqsm2"),
	JoyButton.JOY_BUTTON_B: preload("uid://bihk80ed6rlkn"),
	JoyButton.JOY_BUTTON_X: preload("uid://dhb15ko0frh80"),
	JoyButton.JOY_BUTTON_Y: preload("uid://8flurawndj1x"),
	# Shoulder
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: preload("uid://bf38xcjknirgt"),
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: preload("uid://6758ia38iql3"),
	# Stick press
	JoyButton.JOY_BUTTON_LEFT_STICK: preload("uid://c3p5g57hgsf5k"),
	JoyButton.JOY_BUTTON_RIGHT_STICK: preload("uid://bmp5xf2epv4ij"),
	# Misc
	JoyButton.JOY_BUTTON_BACK: preload("uid://dy53jq6k08rjq"),
	JoyButton.JOY_BUTTON_START: preload("uid://b0fa1rx6f2cm7"),
	# Dpad
	JoyButton.JOY_BUTTON_DPAD_UP: preload("uid://ola3hktlwv01"),
	JoyButton.JOY_BUTTON_DPAD_DOWN: preload("uid://dagruurjehs3r"),
	JoyButton.JOY_BUTTON_DPAD_LEFT: preload("uid://466ghu2v5su6"),
	JoyButton.JOY_BUTTON_DPAD_RIGHT: preload("uid://8xketmaqp3d2"),
}

const LEFT_STICK_ICON: CompressedTexture2D = preload("uid://bx4ijaov68u63")
const RIGHT_STICK_ICON: CompressedTexture2D = preload("uid://d1aopeglq7q3y")
const L2_ICON: CompressedTexture2D = preload("uid://bilrcdermk7c7")
const R2_ICON: CompressedTexture2D = preload("uid://c4y8ya2dgjd25")

const _AXES: Dictionary = {
	# Left stick horizontal
	JoyAxis.JOY_AXIS_LEFT_X: LEFT_STICK_ICON,
	# Left stick vertical
	JoyAxis.JOY_AXIS_LEFT_Y: LEFT_STICK_ICON,
	# Right stick horizontal
	JoyAxis.JOY_AXIS_RIGHT_X: RIGHT_STICK_ICON,
	# Right stick vertical
	JoyAxis.JOY_AXIS_RIGHT_Y: RIGHT_STICK_ICON,
	JoyAxis.JOY_AXIS_TRIGGER_LEFT: L2_ICON,
	JoyAxis.JOY_AXIS_TRIGGER_RIGHT: R2_ICON,
}


func get_button_icon(button: JoyButton) -> Texture2D:
	return _BUTTONS.get(button, null)


func get_axis_icon(axis: JoyAxis, _direction: int) -> Texture2D:
	return _AXES.get(axis, null)
