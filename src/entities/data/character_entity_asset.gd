@tool
class_name CharacterEntityAsset
extends CosmeticAsset

enum CharacterType {
	PLAYER = 0,
	FRIENDLY = 1,
	ENEMY = 2,
}

@export var character_mesh: PackedScene
@export var character_type: CharacterType = CharacterType.PLAYER


func get_slot() -> Slot:
	return Slot.CHARACTER
