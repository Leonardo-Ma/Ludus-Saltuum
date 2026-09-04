class_name KeyboardIconMap

const KEYBOARD_ICONS: Dictionary = {
	# Alphabet
	Key.KEY_A: preload("uid://cbpbddqch361j"),
	Key.KEY_B: preload("uid://bh52cc3awvnq5"),
	Key.KEY_C: preload("uid://cbjpq3yjf5tbi"),
	Key.KEY_D: preload("uid://cqww5kwjrck3d"),
	Key.KEY_E: preload("uid://crh2nl7784d4s"),
	Key.KEY_F: preload("uid://bf4errltd5qek"),
	Key.KEY_G: preload("uid://jrpeyl1rptyu"),
	Key.KEY_H: preload("uid://bfxqx1fhdfgdg"),
	Key.KEY_I: preload("uid://hkpp00p7jfd2"),
	Key.KEY_J: preload("uid://walcivhha4of"),
	Key.KEY_K: preload("uid://celbmqlc8of2m"),
	Key.KEY_L: preload("uid://d4k815vsq1utu"),
	Key.KEY_M: preload("uid://i58kcdvecks8"),
	Key.KEY_N: preload("uid://l8821p13egnf"),
	Key.KEY_O: preload("uid://cy12dcua5y11h"),
	Key.KEY_P: preload("uid://bp8gj8eymrap6"),
	Key.KEY_Q: preload("uid://myloplyubls0"),
	Key.KEY_R: preload("uid://5xp0x61oxsd3"),
	Key.KEY_S: preload("uid://b1nromu08hj3y"),
	Key.KEY_T: preload("uid://bfmsnhsn5jrut"),
	Key.KEY_U: preload("uid://b1trfr50jigrl"),
	Key.KEY_V: preload("uid://cf5rcri8qraor"),
	Key.KEY_W: preload("uid://c12ohnfx80foq"),
	Key.KEY_X: preload("uid://xmcbeibwpo02"),
	Key.KEY_Y: preload("uid://cyl5n7l0ohru2"),
	Key.KEY_Z: preload("uid://cebu41d8c1kbr"),
	# Number
	Key.KEY_0: preload("uid://cvx8by1feybrr"),
	Key.KEY_1: preload("uid://dob4c6xwejswi"),
	Key.KEY_2: preload("uid://2xovxanyv7h8"),
	Key.KEY_3: preload("uid://c0k26b6aiw4o5"),
	Key.KEY_4: preload("uid://3yawv348mgb3"),
	Key.KEY_5: preload("uid://blp1ehx3654k5"),
	Key.KEY_6: preload("uid://peqxxbpl78to"),
	Key.KEY_7: preload("uid://bvwgukj8l1x3"),
	Key.KEY_8: preload("uid://giwgca5moqjr"),
	Key.KEY_9: preload("uid://cjybb4cmog5fo"),
	# Misc
	Key.KEY_SPACE: preload("uid://cn5mglaiekqhk"),
	Key.KEY_ENTER: preload("uid://ce7oxc3agefdc"),
	Key.KEY_ESCAPE: preload("uid://bqulx5utcm8jk"),
	Key.KEY_BACKSPACE: preload("uid://dxpl2xjnvrqgu"),
	Key.KEY_TAB: preload("uid://b1ybrpun7jxr1"),
	Key.KEY_SHIFT: preload("uid://brbte8kftifqa"),
	Key.KEY_CTRL: preload("uid://c0tjkdmr7kj73"),
	Key.KEY_ALT: preload("uid://nqthrc1sgajp"),
	# Arrow key
	Key.KEY_UP: preload("uid://de308rriw58px"),
	Key.KEY_DOWN: preload("uid://d03h8ktveg3x1"),
	Key.KEY_LEFT: preload("uid://c8hmnvosvyqyc"),
	Key.KEY_RIGHT: preload("uid://cj46q2iha4i2"),
	# F keys
	Key.KEY_F1: preload("uid://d01x7nonyhnef"),
	Key.KEY_F2: preload("uid://d3kib87ri2m21"),
	Key.KEY_F3: preload("uid://cg61c6afwe4v4"),
	Key.KEY_F4: preload("uid://dkkgytexoek0u"),
	Key.KEY_F5: preload("uid://bexxp5yj73b8w"),
	Key.KEY_F6: preload("uid://bstris80pw55a"),
	Key.KEY_F7: preload("uid://kfavf2jxw5ad"),
	Key.KEY_F8: preload("uid://cv8clv44neukt"),
	Key.KEY_F9: preload("uid://w2lfyfmiypr2"),
	Key.KEY_F10: preload("uid://bn368tc6ya7lo"),
	Key.KEY_F11: preload("uid://dj6jm3rhr0ipv"),
	Key.KEY_F12: preload("uid://foxvuoo3mvx5"),
}
const MOUSE_ICONS: Dictionary = {
	MouseButton.MOUSE_BUTTON_LEFT: preload("uid://hduaes5faspr"),
	MouseButton.MOUSE_BUTTON_RIGHT: preload("uid://cvgmkj3g4p4xs"),
	MouseButton.MOUSE_BUTTON_MIDDLE: preload("uid://jcob2uig6tfe"),
	MouseButton.MOUSE_BUTTON_WHEEL_UP: preload("uid://baea5nadbwwc5"),
	MouseButton.MOUSE_BUTTON_WHEEL_DOWN: preload("uid://87umqfqk4m0c"),
}
## Maps known implicit mouse-motion actions to a static icon (not rebindable)
const MOUSE_MOTION_ICONS: Dictionary = {
	&"look_around": preload("uid://cgiss7x7cle55"), # mouse_right_motion
}


static func get_keyboard_icon(key: Key) -> Texture2D:
	return KEYBOARD_ICONS.get(key, null)


static func get_mouse_icon(button: MouseButton) -> Texture2D:
	return MOUSE_ICONS.get(button, null)


static func get_mouse_motion_icon(action: StringName) -> Texture2D:
	return MOUSE_MOTION_ICONS.get(action, null)
