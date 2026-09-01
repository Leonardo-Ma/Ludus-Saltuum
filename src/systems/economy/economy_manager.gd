extends Node

signal score_updated(new_score: int)
signal gold_updated(new_total: int)

var score: int = 0
var gold: int = 0


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
