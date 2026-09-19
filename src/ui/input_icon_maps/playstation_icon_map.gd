class_name PlaystationMap
extends GamepadMap

const _BUTTONS: Dictionary = {
	# Buttons
	JoyButton.JOY_BUTTON_A: preload("uid://bky233226p78x"),
	JoyButton.JOY_BUTTON_B: preload("uid://c16jn1pgb0gmf"),
	JoyButton.JOY_BUTTON_X: preload("uid://bulgo3y4xxoxa"),
	JoyButton.JOY_BUTTON_Y: preload("uid://bs88hy0k64aiq"),
	# Shoulder
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: preload("uid://b41wr5xhif10u"),
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: preload("uid://juhx1nfoy4t7"),
	# Stick press
	JoyButton.JOY_BUTTON_LEFT_STICK: preload("uid://c3p5g57hgsf5k"),
	JoyButton.JOY_BUTTON_RIGHT_STICK: preload("uid://bmp5xf2epv4ij"),
	# Misc
	JoyButton.JOY_BUTTON_BACK: preload("uid://b8f1v05fs4lw1"),
	JoyButton.JOY_BUTTON_START: preload("uid://ccbv7v7ayacwj"),
	# Dpad
	JoyButton.JOY_BUTTON_DPAD_UP: preload("uid://cny02a2x75xa6"),
	JoyButton.JOY_BUTTON_DPAD_DOWN: preload("uid://bywu3lh1l8ci6"),
	JoyButton.JOY_BUTTON_DPAD_LEFT: preload("uid://b8xbq8o6u6wbf"),
	JoyButton.JOY_BUTTON_DPAD_RIGHT: preload("uid://cipfqkfteovgw"),
}

const LEFT_STICK_ICON: CompressedTexture2D = preload("uid://bx4ijaov68u63")
const RIGHT_STICK_ICON: CompressedTexture2D = preload("uid://d1aopeglq7q3y")
const L2_ICON: CompressedTexture2D = preload("uid://fv54oc8li7ql")
const R2_ICON: CompressedTexture2D = preload("uid://d2kmi1yrbny0v")

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
