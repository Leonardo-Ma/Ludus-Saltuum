# TODO Consider extending a base (non-aggressive) entity? (note: that would probably be way worse)
# subclass sandbox https://www.youtube.com/watch?v=oIrvZDDWxhU&t=50s - GDQuest Five Must Have Code Patterns for Your Godot Game
## Generic abstract class for entities that take damage and attack
## Refer to subclass sandbox https://gameprogrammingpatterns.com/subclass-sandbox.html
@abstract class_name AggressiveEntity
extends CharacterBody3D

@warning_ignore("unused_signal")
signal melee_attacked

## When damaged, called by code
const DAMAGE_SOUNDS: Array[AudioStream] = [
	preload("uid://c2uxva6p1yaxw"),  # chequered_ink/punch.wav
	preload("uid://ygovytmkf0xu"),  # chequered_ink/punch_2.wav
	preload("uid://c4qxkql51g7pm"),  # chequered_ink/punch_3.wav
]

## When attacking, called by animation player
const ATTACK_SOUNDS: Array[AudioStream] = [
	preload("uid://domodec4epc7f"),  # sword_slice.wav
	#preload("uid://doay56c5x3rwr"),  # sword_clash_2.wav
]

@export_category("Core")
@export var attack: Attack
@export var health: Health
@export var movement: Movement

@export_group("Is NPC?")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var is_npc: bool = true
@export_subgroup("Perception System")
@export var perception_config: PerceptionConfig
@export var target_groups: Array[String] = [Groups.PLAYERS]
@export var debug_perception: bool = false

@export_subgroup("AI System")
@export var ai_config: AIConfig

var goap_agent: GoapAgent = null
var spawn_position: Vector3  # saved after chunk alignment; used for save/load matching
var _damage_material: StandardMaterial3D
var _damage_tween: Tween
var _prev_health: int = 0

@onready var collision_shape: CollisionShape3D = %CollisionShape3D

@onready var hitbox: Hitbox = %Hitbox
@onready var hurtbox: Hurtbox = %Hurtbox
@onready var status_manager: StatusManager = %StatusManager
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@onready var navigation_controller: Node
@onready var goap_controller: GoapMemory
@onready var perception_system: PerceptionSystem


## Children should override _child_ready instead of this
func _ready() -> void:
	assert(collision_shape.shape != null, "CollisionShape missing in " + name)
	assert(hitbox, "Hitbox incorrect for " + self.name)
	assert(hurtbox, "Hurtbox incorrect for " + self.name)
	assert(status_manager, "Status Manager missing for " + self.name)
	assert(animation_player, "Animation player missing for " + self.name)
	assert(attack and attack.damage > 0 and attack.type != null, "Attack property incorrect for " + self.name)
	assert(health and health.current_health > 0, "Health property incorrect for " + self.name)
	assert(movement, "Movement incorrect for " + self.name)

	_setup_damage_feedback_visual_material()

	_prev_health = health.current_health
	health.died.connect(_on_death)
	health.damaged.connect(_on_damaged_effects_feedback)
	health.health_changed.connect(_on_health_changed)
	# TODO Double check this
	# Inject timer creation capability into health resource - Dependency Injection
	health.initialize_timer_callback(_create_timer)

	_child_ready()

	if is_npc:
		navigation_controller = $%NavigationController
		goap_controller = $%GoapController
		perception_system = $%PerceptionSystem
		assert(ai_config, "GOAP Not properly configured for " + self.name)
		assert(goap_controller, "GoapController missing for " + self.name)
		assert(navigation_controller, "NavigationController missing for " + self.name)
		assert(perception_system, "Perception system missing for " + self.name)

		goap_agent = GoapAgent.new()
		var goals: Array[GoapGoal] = ai_config.create_goals()
		var actions: Array[GoapAction] = ai_config.create_actions()

		goap_agent.name = self.name
		print("Registering GOAP agent: ", goap_agent.name)

		goap_agent.init(self, goals, goap_controller, actions)
		add_child(goap_agent)

		navigation_controller.set_physics_process(false)

		assert(goap_agent != null, "NPCs must have GoapAgent. " + self.name)
		add_to_group(Groups.ENEMIES)
		# chunk is not yet aligned when _ready() fires
		call_deferred("_record_spawn_position")


## Virtual method for subclasses to override instead of _ready()
@abstract func _child_ready() -> void

## To Override [br]
## Async post-death behavior (e.g. respawn, scene transition) [br]
## Called when _on_death is finished
@abstract func _on_death_complete() -> void


# TODO Disable navigation for GOAP, disable player controller
# Maybe transform into abstract method to force override? Or use entity_enable_disable (player has but not npc)?
# Player already overrides this
func _on_death() -> void:
	print(str(self.name) + " is dead, Jim!")

	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()

	if goap_agent:
		print("Disabling GOAP agent ", goap_agent.name)
		goap_agent.set_process(false)

	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)

	await _death_animation()

	_on_death_complete()


func _record_spawn_position() -> void:
	spawn_position = global_position


#region Visual effects and animations
func _setup_damage_feedback_visual_material() -> void:
	_damage_material = StandardMaterial3D.new()
	_damage_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_damage_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_damage_material.albedo_color = Color(1.0, 1.0, 1.0, 0.0)

	for mesh: MeshInstance3D in _get_all_mesh_instances(self):
		mesh.material_overlay = _damage_material


func _on_damaged_effects_feedback(_attack: Attack) -> void:
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()

	SoundManager.play_combat_sound(DAMAGE_SOUNDS.pick_random(), global_position, 1)

	_damage_material.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
	_damage_tween = create_tween()
	_damage_tween.tween_property(_damage_material, "albedo_color:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _death_animation() -> void:
	var death_tween: Tween = create_tween()

	death_tween.tween_interval(2.0)
	death_tween.tween_property(self, "scale", Vector3(0.001, 0.001, 0.001), 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await death_tween.finished


func _on_health_changed(new_health: int) -> void:
	if new_health > _prev_health:
		if _damage_tween and _damage_tween.is_valid():
			_damage_tween.kill()
		# Flash green on heal (pulse)
		_damage_material.albedo_color = Color(0.3, 1.0, 0.3, 0.4)
		_damage_tween = create_tween()
		_damage_tween.tween_property(_damage_material, "albedo_color:a", 0.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_prev_health = new_health


func play_attack_sound() -> void:
	if ATTACK_SOUNDS.size() > 0:
		SoundManager.play_combat_sound(ATTACK_SOUNDS.pick_random(), global_position)


func _get_all_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(_get_all_mesh_instances(child))
	return result


#endregion


## Timer creation callback for Health resource (dependency injection)
func _create_timer(duration: float, callback: Callable) -> void:
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):  # Entity alive?
		callback.call()
