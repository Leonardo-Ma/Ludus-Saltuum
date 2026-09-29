## Credits category containing first-party contributors or third-party assets
class_name CreditSection
extends Resource

@export var display_name: String
@export var icon: Texture2D
@export var people: Array[CreditPerson] = []
@export var assets: Array[CreditAsset] = []
