class_name AnimParams

## Node names and parameter paths shared with editor-authored graphs

const BODY: StringName = &"body"
const JUMP: StringName = &"jump"
const FALL: StringName = &"fall"
const DEAD: StringName = &"dead"
const RESPAWN: StringName = &"respawn"
const DEATH_SELECT: StringName = &"death_select"

const LAYER_NAMES: Dictionary[AnimationActionDefinition.Layer, StringName] = {
	AnimationActionDefinition.Layer.UPPER_BODY: &"upper_body",
	AnimationActionDefinition.Layer.FULL_BODY: &"full_body",
	AnimationActionDefinition.Layer.REACTION: &"reaction",
}


static func playback() -> StringName:
	return StringName("parameters/%s/playback" % BODY)


static func blend_position(stance: StringName) -> StringName:
	return StringName("parameters/%s/%s/blend_position" % [BODY, stance])


static func stance_condition(stance: StringName) -> StringName:
	return StringName("parameters/%s/conditions/%s" % [BODY, stance])


static func death_select() -> StringName:
	return StringName("parameters/%s/%s/%s/transition_request" % [BODY, DEAD, DEATH_SELECT])


static func layer_request(layer: AnimationActionDefinition.Layer) -> StringName:
	return StringName("parameters/%s/request" % LAYER_NAMES[layer])


static func layer_observer(layer: AnimationActionDefinition.Layer) -> StringName:
	return StringName("parameters/%s/observer" % LAYER_NAMES[layer])


static func selector_name(layer: AnimationActionDefinition.Layer) -> StringName:
	return StringName("%s_select" % LAYER_NAMES[layer])


static func layer_select(layer: AnimationActionDefinition.Layer) -> StringName:
	return StringName("parameters/%s/transition_request" % selector_name(layer))
