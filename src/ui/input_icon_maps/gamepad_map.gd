## Template for brand gamepad icon maps
@abstract class_name GamepadMap


## Returns icon for digital [JoyButton], or null if unmapped
@abstract func get_button_icon(button: JoyButton) -> Texture2D


## Returns icon for [JoyAxis] and direction (-1 or 1), or null if unmapped
@abstract func get_axis_icon(axis: JoyAxis, direction: int) -> Texture2D
