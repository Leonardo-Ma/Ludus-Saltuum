class_name ChunkFeature

# TODO Add check that for each Feature there should be a FEATURE_NAME below

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
	Feature.CAR: &"car",
	Feature.SPRING: &"spring",
	Feature.DISAPPEARING_PLATFORM: &"disappearing_platform",
	Feature.PORTAL: &"portal",
	Feature.MAZE: &"maze",
	Feature.TORNADO: &"tornado",
	Feature.MOVING_PLATFORM: &"moving_platform",
}
