## Template class for objects that receive the player_interact() raycast prompt
## Since RayCast3D detects bodies directly, this defaults to StaticBody3D for physical presence
@abstract class_name Interactable
extends StaticBody3D


## To override
@abstract func player_interact() -> void
