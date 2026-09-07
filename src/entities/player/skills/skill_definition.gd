## Base resource for all skills
class_name SkillDefinition
extends Resource

## The behaviour node attached to the player when this skill is unlocked
@export var skill_script: Script

## HUD icon
@export var icon: Texture2D

## Number of uses
@export var max_charges: int = 1

# TODO Reconsider this
## Input action name in Project Settings
@export var input_action: StringName = &""

## HUD display order. Lower = Left
## Must be unique
@export var hud_order: int = 0

## Tags for chunk selector filtering ("movement", "air", "ground", …)
@export var tags: Array[StringName] = []
