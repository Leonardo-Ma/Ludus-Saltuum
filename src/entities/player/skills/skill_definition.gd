## Base resource for all skills
class_name SkillDefinition
extends Resource

@export_category("Core")
## The behaviour node attached to the player when this skill is unlocked
@export var skill_script: Script

## HUD icon
@export var icon: Texture2D

@export var max_charges: int = 1
# TODO Change to enum?
## Tags for chunk selector filtering ("movement", "air", "ground", …)
@export var tags: Array[StringName] = []

@export_category("UI")
## Input action name in Project Settings
@export_custom(PROPERTY_HINT_INPUT_NAME, "Input action string") var input_action: StringName

## Optional [br]
## To be shown after the skill input action icon (double jump = spacebar 2x(suffix to show must press twice))
@export var key_hint_suffix: StringName

## HUD display order. Lower = Left
## Must be unique
@export var hud_order: int = 0
