class_name EasterEgg
extends TriggerArea3D

enum Name {
	UNDEFINED = 0,
	FOURTY_TWO = 1,
}

@export var easter_egg_name: Name = 0 as Name


func _child_ready() -> void:
	assert(easter_egg_name != 0, "Easter egg name not defined in " + owner.name)


func _on_trigger_entered(body: Node3D) -> void:
	if body is PlayerEntity and body.is_in_group(Groups.CONTROLLED):
		var player: PlayerEntity = body
		var discovery: EasterEggController = player.get_node(^"%EasterEggController")
		assert(discovery, "EasterEggController missing in " + player.name)
		discovery.discover(easter_egg_name)
