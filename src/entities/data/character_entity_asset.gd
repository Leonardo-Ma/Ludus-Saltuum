class_name CharacterEntityAsset
extends Resource

enum CharacterType {
	PLAYER = 0,
	FRIENDLY = 1,
	ENEMY = 2,
}

## NOTE Do not change after being set under any circumstance
@export var character_id: StringName
@export var character_name: String
@export var character_mesh: PackedScene
@export var character_icon: CompressedTexture2D
@export var character_type: CharacterType = CharacterType.PLAYER
@export var character_price: int
