extends Sprite3D

@export var skill_reference: SkillDefinition
## Keeps skill icons at consistent world-space size regardless of texture resolution
@export var world_size: float = 0.2


func _ready() -> void:
	assert(skill_reference != null, "Skill reference missing in " + owner.name)
	texture = skill_reference.icon
	assert(texture != null, "Skill icon missing in " + owner.name)

	var texture_size: Vector2 = texture.get_size()
	pixel_size = world_size / maxf(texture_size.x, texture_size.y)
