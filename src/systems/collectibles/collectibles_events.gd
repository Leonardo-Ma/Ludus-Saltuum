extends Node

@warning_ignore("unused_signal")
signal counter_collectible_collected(identifier: StringName, amount: int, icon: Texture2D)
@warning_ignore("unused_signal")
signal collectible_collected(collectible_id: StringName)
@warning_ignore("unused_signal")
signal status_buff_collected(status_effect: StatusEffect, icon: Texture2D)
@warning_ignore("unused_signal")
signal skill_collected(skill: SkillDefinition)
