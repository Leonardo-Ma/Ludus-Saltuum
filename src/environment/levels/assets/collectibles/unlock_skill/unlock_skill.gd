extends Collectible


func _child_ready() -> void:
	collect_sounds = [
		preload("uid://cag33c6eom3kf"),  # harpsichord_chime_positive.wav
	]
	var skill_data: SkillCollectible = data as SkillCollectible
	# BUG Since these levels are generated procedurally, it doesn't catch it until generated
	assert(skill_data != null, "UnlockSkill: SkillCollectible resource required on " + name)
	assert(
		skill_data.resource_path.ends_with(".tres"),
		"UnlockSkill: SkillCollectible must be an external .tres resource, not inline/sub-resource on " + name
	)
	assert(skill_data.definition != null, "UnlockSkill: SkillCollectible definition required on " + name)
	# TODO Add a festive animation effect when picking up this (tween?)
