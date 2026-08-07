# Controller / Gamepad support in Godot


## UI
- Need to have a default focus artifact for each screen/menu (usually with a generic control 'focus_grab' with an on ready focus grab script).
- Need to set focus neighbors for each focusable artifact.
- Have a specific focused background or difference (border, color change)

## Input map
### UI
- Add to input map default actions:
ui_accept: Joypad button 0 (confirm, a, cross)
ui_cancel: Joypad button 1 (right action, b)

Optional:
ui_focus_next: Joypad button 10 (R1, RB)
ui_focus_prev: Joypad button 9 (L1, LB)

### Movement
left:	Joypad axis 0 - | Joypad button 13 (D-Pad left)
right:	Joypad axis 0 + | Joypad button 14 (D-Pad right)
forward: Joypad axis 1 - |	Joypad button 11 (D-Pad up)
backward: Joypad axis 1 + |	Joypad button 12 (D-Pad down)

### Camera
look_left: Joypad axis 2 -
look_right:	Joypad axis 2 +
look_down: Joypad axis 3 -
look_up: Joypad axis 3 +

### Menu / Pause
escape: Joypad button 6


jump: Joypad button Button 0
run:	Button B (Circle) / Button 1, or Left Stick Click


## Helpers
### Input manager
- Have an input manager that seamlessly switch between gamepad and keyboard and mouse (optionally accept both inputs at same time)
When changing to gamepad it should change to focus navigation and hide mouse. When a gamepad is disconnected, it should pause the game.

## To be accepted on steam (controller supported tag):
- Requires support for xbox, playstation or steam input (steam proprietary api).
- Requires proper glyph (icons) for each controller supported that dynamically change when connected.
