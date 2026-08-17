## This label is attached above entity that uses goap
extends Label3D

@onready var animation_tree: AnimationTree = %AnimationTree

@onready var goap_controller: BaseMemory = %GoapController

@onready var label_text: String


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return


func _process(_delta: float) -> void:
	if not self.visible:
		return

	var is_damaged: String = "Not damaged"

	if animation_tree.get("parameters/is_damaged/active"):
		is_damaged = "damaged"
	label_text = is_damaged + " \n "
	label_text += str(owner.health.current_health) + "\n"

	label_text += "GOAP:\n"
	#for values in goap_controller.get_blackboard().values():
	#label_text += str(values) + "\n"

	label_text += "Current goal: "
	if owner.goap_agent._current_goal:
		label_text += str(owner.goap_agent._current_goal.get_custom_class_name()) + "\n"

	if owner.goap_agent._current_goal:
		label_text += "Current goal: " + owner.goap_agent._current_goal.get_custom_class_name()

	self.text = label_text
