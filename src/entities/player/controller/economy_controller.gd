## Score and gold
class_name EconomyController
extends Node

signal score_changed(new_score: int)
signal gold_changed(new_gold: int)

var score: int = 0
var gold: int = 0


func _ready() -> void:
	CombatEvents.enemy_killed.connect(_on_enemy_killed)


func add_score(points: int) -> void:
	assert(points >= 1, "Tried to add less than 1")
	score += points
	score_changed.emit(score)


func remove_score(points: int) -> void:
	assert(points <= -1, "Tried to remove more than -1")
	score = maxi(0, score - points)
	score_changed.emit(score)


func add_gold(amount: int) -> void:
	assert(amount >= 1, "Tried to add less than 1")
	gold += amount
	gold_changed.emit(gold)


## Returns false if insufficient gold
func remove_gold(amount: int) -> bool:
	assert(amount <= -1, "Tried to remove more than -1")
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func _on_enemy_killed(_position: Vector3) -> void:
	add_score(5)
