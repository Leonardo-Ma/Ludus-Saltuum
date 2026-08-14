# https://refactoring.guru/design-patterns/observer
extends Node

#region Player
@warning_ignore("unused_signal")
signal player_spawned(player: Node3D)
@warning_ignore("unused_signal")
signal counter_collectible_collected(identifier: StringName, amount: int, icon: Texture2D)
@warning_ignore("unused_signal")
signal status_buff_collected(status_effect: StatusEffect, icon: Texture2D)
signal score_updated(new_score: int)
@warning_ignore("unused_signal")
signal easter_egg_found(easter_egg_name: StringName)
@warning_ignore("unused_signal")
signal player_respawning(duration: float)
signal gold_updated(new_total: int)
@warning_ignore("unused_signal")
signal collectible_consumed(world_position: Vector3)
@warning_ignore("unused_signal")
signal enemy_killed(world_position: Vector3)
signal controlled_entity_changed(entity: Node3D)
#endregion

var procedural_seed: int = 0
var score: int = 0
var gold: int = 0
var easter_eggs_found: int = 0
var found_easter_eggs: Dictionary = {}
var controlled_entity: Node3D = null


func _ready() -> void:
	easter_egg_found.connect(_on_easter_egg_found)


func add_score(points: int) -> void:
	score += points
	score_updated.emit(score)


func remove_score(points: int) -> void:
	score -= points
	if score <= 0:
		score = 0
	score_updated.emit(score)


func add_gold(amount: int) -> void:
	gold += amount
	gold_updated.emit(gold)


## Returns false if insufficient gold
func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_updated.emit(gold)
	return true


func set_controlled_entity(entity: Node3D) -> void:
	controlled_entity = entity
	controlled_entity_changed.emit(entity)


# BUG If something passes is_death = true and doesn't kill the player, it bypasses health and restores player health to max
## Request respawn for currently controlled entity
## Entity must implement respawn
func request_respawn(delay: float, target_position: Vector3, is_death: bool = false) -> void:
	assert(controlled_entity != null, "No controlled entity to respawn")
	assert(
		controlled_entity.has_method("respawn"),
		"Controlled entity " + controlled_entity.name + " must implement respawn(delay: float, target_position: Vector3, is_death: bool)"
	)
	controlled_entity.respawn(delay, target_position, is_death)


func _on_easter_egg_found(easter_egg_name: StringName) -> void:
	if not found_easter_eggs.has(easter_egg_name):
		found_easter_eggs[easter_egg_name] = true
		easter_eggs_found += 1
		print(easter_eggs_found)
