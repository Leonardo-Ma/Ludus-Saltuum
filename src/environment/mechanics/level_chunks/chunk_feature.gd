class_name ChunkFeature
extends Node

enum Feature {
	CAR = 0,
	SPRING = 1,
	DISAPPEARING_PLATFORM = 2,
	PORTAL = 3,
	MAZE = 4,
	TORNADO = 5,
	MOVING_PLATFORM = 6,
}

const FEATURE_NAME: Dictionary = {
	Feature.CAR: &"car", Feature.SPRING: &"spring", Feature.DISAPPEARING_PLATFORM: &"disappearing_platform", Feature.PORTAL: &"portal"
}
