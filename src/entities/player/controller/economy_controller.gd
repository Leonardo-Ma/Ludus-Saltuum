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
	score += points
	score_changed.emit(score)


func remove_score(points: int) -> void:
	score = maxi(0, score - points)
	score_changed.emit(score)


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


## Returns false if insufficient gold
func remove_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func _on_enemy_killed(_position: Vector3) -> void:
	add_score(5)
