class_name AnimationController
extends Node

## Plays editor-authored AnimationTree through its declared profile [br]
## Fed by AnimationBridge nodes

signal action_finished(action_id: StringName)
signal action_interrupted(action_id: StringName)

@export var profile: AnimationProfile

var _is_dead: bool = false
var _is_airborne: bool = false
var _stance: StringName
var _move_direction: Vector2 = Vector2.ZERO
var _playback: AnimationNodeStateMachinePlayback
var _definitions: Dictionary[StringName, AnimationActionDefinition] = { }
var _running: Dictionary[AnimationActionDefinition.Layer, StringName] = { }
var _combo_index: Dictionary[StringName, int] = { }
var _finished_msec: Dictionary[StringName, int] = { }

@onready var _tree: AnimationTree = %AnimationTree
@onready var _player: AnimationPlayer = %AnimationPlayer


func _ready() -> void:
	assert(profile != null, "AnimationProfile missing in " + name)
	assert(_tree != null and _player != null, "AnimationTree or AnimationPlayer missing in " + name)
	assert(_tree.get_node(_tree.anim_player) == _player, "AnimationTree linked to wrong AnimationPlayer in " + name)
	profile.validate(name)
	_validate_graph()

	var observed_layers: Array[AnimationActionDefinition.Layer] = []
	for definition: AnimationActionDefinition in profile.actions:
		_definitions[definition.id] = definition
		if observed_layers.has(definition.layer):
			continue
		var observer: AnimationNodeObserverOneShot = AnimationNodeObserverOneShot.new()
		_tree.set(AnimParams.layer_observer(definition.layer), observer)
		observer.finished.connect(_on_layer_finished.bind(definition.layer))
		observed_layers.append(definition.layer)

	_playback = _tree.get(AnimParams.playback())
	assert(_playback != null, "Body playback missing in " + name)
	set_stance(profile.default_stance)
	_tree.active = true
	_playback.start(_stance)


func _on_layer_finished(layer: AnimationActionDefinition.Layer) -> void:
	if _running.has(layer):
		action_finished.emit(_clear_layer(layer))


#region Public API
# BUG If player uses shift + movement, strafe animation gets stuck if: shift + a/d + w then releasing w
# removed strafe left and right on animation tree movement
## Blend space position, x left (-1) to right (1), y backward (-1) to forward (1)
func set_movement(direction: Vector2) -> void:
	if direction == _move_direction:
		return
	_move_direction = direction
	_tree.set(AnimParams.blend_position(_stance), direction)


func set_stance(stance: StringName) -> void:
	assert(profile.stances.has(stance), "Stance '%s' missing in AnimationProfile of %s" % [stance, name])
	if stance == _stance:
		return
	_stance = stance
	_tree.set(AnimParams.blend_position(stance), _move_direction)
	for state: StringName in profile.stances:
		_tree.set(AnimParams.stance_condition(state), state == stance)


## Ground jump start, restarts jump state
func jump() -> void:
	assert(profile.has_air_states, "Air states missing in AnimationProfile of " + name)
	_is_airborne = true
	if _is_dead:
		return
	_playback.start(AnimParams.JUMP)


func set_airborne(airborne: bool) -> void:
	if airborne == _is_airborne:
		return
	_is_airborne = airborne
	if not profile.has_air_states or _is_dead:
		return
	_playback.travel(AnimParams.FALL if airborne else _stance)


func set_dead(dead: bool) -> void:
	if dead == _is_dead:
		return
	_is_dead = dead
	if dead:
		for layer: AnimationActionDefinition.Layer in _running.keys():
			_stop_layer(layer)
		_combo_index.clear()
		_finished_msec.clear()
		if profile.has_death:
			if not profile.death_inputs.is_empty():
				_tree.set(AnimParams.death_select(), profile.death_inputs.pick_random())
			_playback.start(AnimParams.DEAD)
		return

	_is_airborne = false
	_playback.start(AnimParams.RESPAWN if profile.has_respawn else _stance)


func request_action(action_id: StringName) -> void:
	var definition: AnimationActionDefinition = _definitions.get(action_id)
	assert(definition != null, "Action '%s' missing in AnimationProfile of %s" % [action_id, name])

	# TODO Consider input buffering, so if you attack when about to hit ground, it triggers attack
	if _is_dead or (definition.ground_only and _is_airborne):
		return
	var previous_action: StringName = _running.get(definition.layer, &"")
	if previous_action != &"" and not definition.interrupt_active:
		return

	if not definition.inputs.is_empty():
		_tree.set(AnimParams.layer_select(definition.layer), _pick_variant(definition))
	_running[definition.layer] = action_id
	_tree.set(AnimParams.layer_request(definition.layer), AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if previous_action != &"":
		_finished_msec[previous_action] = Time.get_ticks_msec()
		action_interrupted.emit(previous_action)


## No action_finished emitted, used for held actions (block, bow hold)
func abort_action(action_id: StringName) -> void:
	var definition: AnimationActionDefinition = _definitions.get(action_id)
	if definition != null and _running.get(definition.layer) == action_id:
		_stop_layer(definition.layer)


func is_action_running(action_id: StringName) -> bool:
	return _running.values().has(action_id)
#endregion


func _pick_variant(definition: AnimationActionDefinition) -> StringName:
	if definition.variant_mode == AnimationActionDefinition.VariantMode.RANDOM:
		return definition.inputs.pick_random()

	var index: int = _combo_index.get(definition.id, 0)
	if _is_combo_expired(definition):
		index = 0
	_combo_index[definition.id] = (index + 1) % definition.inputs.size()
	return definition.inputs[index]


func _is_combo_expired(definition: AnimationActionDefinition) -> bool:
	if definition.combo_window <= 0.0:
		return false
	var finished_msec: int = _finished_msec.get(definition.id, 0)
	return Time.get_ticks_msec() - finished_msec > roundi(definition.combo_window * 1000.0)


func _stop_layer(layer: AnimationActionDefinition.Layer) -> void:
	_tree.set(AnimParams.layer_request(layer), AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	action_interrupted.emit(_clear_layer(layer))


func _clear_layer(layer: AnimationActionDefinition.Layer) -> StringName:
	var action_id: StringName = _running[layer]
	_running.erase(layer)
	_finished_msec[action_id] = Time.get_ticks_msec()
	return action_id


func _validate_graph() -> void:
	assert(_tree.tree_root is AnimationNodeBlendTree, "BlendTree root missing in " + name)
	var root: AnimationNodeBlendTree = _tree.tree_root
	assert(root.has_node(AnimParams.BODY) and root.get_node(AnimParams.BODY) is AnimationNodeStateMachine, "Body state machine missing in " + name)
	var body: AnimationNodeStateMachine = root.get_node(AnimParams.BODY)
	for stance: StringName in profile.stances:
		assert(
			body.has_node(stance) and body.get_node(stance) is AnimationNodeBlendSpace2D,
			"Expected BlendSpace2D '%s' in %s for %s/%s" % [stance, root.resource_path, owner.name, name],
		)
		assert(
			_tree.get(AnimParams.stance_condition(stance)) is bool,
			"Condition for '%s' missing in %s for %s/%s" % [stance, root.resource_path, owner.name, name],
		)
	assert(not profile.has_air_states or (body.has_node(AnimParams.JUMP) and body.has_node(AnimParams.FALL)), "Air states missing in " + name)
	assert(not profile.has_death or body.has_node(AnimParams.DEAD), "Dead state missing in " + name)
	assert(not profile.has_respawn or body.has_node(AnimParams.RESPAWN), "Respawn state missing in " + name)
	if not profile.death_inputs.is_empty():
		assert(body.get_node(AnimParams.DEAD) is AnimationNodeBlendTree, "Death BlendTree missing in " + name)
		var death: AnimationNodeBlendTree = body.get_node(AnimParams.DEAD)
		_validate_inputs(death, AnimParams.DEATH_SELECT, profile.death_inputs)

	var direct_layers: Array[AnimationActionDefinition.Layer] = []
	for action: AnimationActionDefinition in profile.actions:
		var layer_name: StringName = AnimParams.LAYER_NAMES[action.layer]
		assert(root.has_node(layer_name) and root.get_node(layer_name) is AnimationNodeOneShot, "OneShot '%s' missing in %s" % [layer_name, name])
		if action.layer == AnimationActionDefinition.Layer.UPPER_BODY:
			var one_shot: AnimationNodeOneShot = root.get_node(layer_name)
			assert(one_shot.filter_enabled, "Upper-body OneShot filter disabled in " + name)
		var selector_name: StringName = AnimParams.selector_name(action.layer)
		if action.inputs.is_empty():
			assert(
				not root.has_node(selector_name) and not direct_layers.has(action.layer),
				"Layer '%s' needs named inputs in %s" % [layer_name, name],
			)
			direct_layers.append(action.layer)
		else:
			_validate_inputs(root, selector_name, action.inputs)


## Validates named inputs before runtime writes to a Transition
func _validate_inputs(graph: AnimationNodeBlendTree, selector_name: StringName, inputs: Array[StringName]) -> void:
	assert(
		graph.has_node(selector_name) and graph.get_node(selector_name) is AnimationNodeTransition,
		"Transition '%s' missing in %s" % [selector_name, name],
	)
	var selector: AnimationNodeTransition = graph.get_node(selector_name)
	for input: StringName in inputs:
		assert(selector.find_input(input) >= 0, "Input '%s' missing in '%s' of %s" % [input, selector_name, name])
