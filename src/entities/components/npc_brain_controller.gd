class_name NPCBrainController
extends Node

## Builds and owns GoapAgent from AIConfig

var goap_agent: GoapAgent

var _actor: NPCEntity
var _ai_config: AIConfig
var _memory: GoapMemory


func setup(actor: NPCEntity, ai_config: AIConfig, memory: GoapMemory) -> void:
	_actor = actor
	_ai_config = ai_config
	_memory = memory


func _ready() -> void:
	assert(_actor, "Actor missing in " + name)
	assert(_ai_config, "AIConfig missing in " + name)
	assert(_memory, "GoapMemory missing in " + name)

	var goals: Array[GoapGoal] = _ai_config.create_goals()
	var actions: Array[GoapAction] = _ai_config.create_actions()

	goap_agent = GoapAgent.new()
	goap_agent.name = _actor.name
	print("Registering GOAP agent: ", goap_agent.name)

	goap_agent.init(_actor, goals, _memory, actions)
	add_child(goap_agent)


func set_active(active: bool) -> void:
	goap_agent.set_process(active)
