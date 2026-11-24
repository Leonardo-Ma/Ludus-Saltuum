class_name AnimationActionDefinition
extends Resource

## One playable action with editor-authored variants picked per request

## Bottom to top blend order
## Upper-body OneShot filters are relative to AnimationTree root and include any attack tracks the layer owns
enum Layer {
	UPPER_BODY = 0, ## Filtered by OneShot, locomotion keeps playing
	FULL_BODY = 1,
	REACTION = 2,
}

enum VariantMode {
	RANDOM = 0,
	SEQUENTIAL = 1, ## Combo chain
}

@export var id: StringName
## Named Transition inputs without '.' or '/', empty for a layer wired directly to a single clip
@export var inputs: Array[StringName] = []
@export var layer: Layer = Layer.FULL_BODY
@export var variant_mode: VariantMode = VariantMode.RANDOM
## SEQUENTIAL only, seconds after finish before chain restarts, 0 = never
@export_range(0.0, 10.0, 0.05, "suffix:s") var combo_window: float = 0.0
## Restarts if layer busy, else request ignored while busy
@export var interrupt_active: bool = false
## Requires ground contact when starting the action
@export var ground_only: bool = false
