class_name CharacterEntityCatalog
extends Resource

## Resolves character IDs to character asset definitions

@export var characters: Array[CharacterEntityAsset] = []


func get_character_asset(character_id: StringName) -> CharacterEntityAsset:
	for character_asset: CharacterEntityAsset in characters:
		assert(character_asset != null, "Null character asset in catalog " + resource_path)

		if character_asset.character_id == character_id:
			return character_asset

	assert(false, "Character ID " + String(character_id) + " missing from catalog " + resource_path)
	return null
