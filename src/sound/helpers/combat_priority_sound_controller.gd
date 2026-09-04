class_name CombatPrioritySoundController
extends Node

enum Priority {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
	CRITICAL = 3,
	ULTIMATE = 4,
}


# Sound data structure
class CombatSound:
	var player: Variant # Can be AudioStreamPlayer or AudioStreamPlayer2D
	var priority: int
	var timestamp: int
	var sound_id: String


	func _init(p: Variant, prio: int, id: String = "") -> void:
		player = p
		priority = prio
		timestamp = Time.get_ticks_msec()
		sound_id = id if id != "" else str(timestamp)


var _sound_pool: SoundPool
var _active_sounds: Array[CombatSound] = []
var _max_active_sounds: int = 10 # Max combat sounds at once

# Special effects for intense combat
var _intensity_level: int = 0 # 0-3
var _intensity_timer: float = 0.0


func initialize(pool: SoundPool) -> void:
	_sound_pool = pool


func play_with_priority(sound: AudioStream, position: Vector3, priority: int, sound_id: String = "", source_node: Node3D = null) -> bool:
	var actual_pos: Vector3 = position
	if source_node:
		actual_pos = source_node.global_position

	# Check if we should replace an existing sound
	if _active_sounds.size() >= _max_active_sounds:
		var lowest_priority_idx: int = _find_lowest_priority_sound()
		var lowest_priority: int = _active_sounds[lowest_priority_idx].priority

		if priority <= lowest_priority:
			return false # New sound not important enough

		# Replace the lowest priority sound
		var old_sound: CombatSound = _active_sounds[lowest_priority_idx]
		old_sound.player.stop()
		_return_to_pool(old_sound.player)
		_active_sounds.remove_at(lowest_priority_idx)

	# Get a player from the pool
	var player: Variant = _sound_pool.play_sound(sound, SoundManager.SoundCategory.SFX, actual_pos)
	if player == null:
		return false

	player.set_meta("priority", priority)
	player.set_meta("timestamp", Time.get_ticks_msec())

	# Track active sound
	var combat_sound: CombatSound = CombatSound.new(player, priority, sound_id)
	_active_sounds.append(combat_sound)

	# Auto-remove when finished
	player.finished.connect(_on_combat_sound_finished.bind(player), CONNECT_ONE_SHOT)

	_update_combat_intensity(priority)

	return true


# Play multiple sounds in sequence (e.g., combo attacks)
func play_combo(sounds: Array[AudioStream], positions: Array[Vector3], priorities: Array[int], delay_ms: float = 100.0) -> void:
	for i: int in range(sounds.size()):
		var pos: Vector3 = positions[i] if i < positions.size() else Vector3.ZERO
		var prio: int = priorities[i] if i < priorities.size() else Priority.MEDIUM

		if i == 0:
			play_with_priority(sounds[i], pos, prio)
		else:
			await get_tree().create_timer(delay_ms / 1000.0).timeout
			play_with_priority(sounds[i], pos, prio)


# Clear all combat sounds (e.g., when combat ends)
func clear_all_combat_sounds() -> void:
	for sound_data: CombatSound in _active_sounds:
		sound_data.player.stop()
		_return_to_pool(sound_data.player)
	_active_sounds.clear()
	_intensity_level = 0


# Combat intensity system
func get_combat_intensity() -> int:
	return _intensity_level


func _update_combat_intensity(priority: int) -> void:
	# Increase intensity based on sound priority
	var intensity_increase: int = 0
	match priority:
		Priority.LOW:
			intensity_increase = 1
		Priority.MEDIUM:
			intensity_increase = 2
		Priority.HIGH:
			intensity_increase = 3
		Priority.CRITICAL, Priority.ULTIMATE:
			intensity_increase = 4

	_intensity_level = min(_intensity_level + intensity_increase, 3)
	_intensity_timer = 3.0 # Intensity decays after 3 seconds


func _process(delta: float) -> void:
	# Decay combat intensity over time
	if _intensity_level > 0:
		_intensity_timer -= delta
		if _intensity_timer <= 0:
			_intensity_level = max(_intensity_level - 1, 0)
			_intensity_timer = 2.0


# Priority helpers
func _find_lowest_priority_sound() -> int:
	var lowest_idx: int = 0
	var lowest_priority: int = Priority.ULTIMATE + 1

	for i: int in range(_active_sounds.size()):
		var prio: int = _active_sounds[i].priority
		if prio < lowest_priority:
			lowest_priority = prio
			lowest_idx = i

	return lowest_idx


func _on_combat_sound_finished(player: Variant) -> void:
	for i: int in range(_active_sounds.size()):
		if _active_sounds[i].player == player:
			_active_sounds.remove_at(i)
			_return_to_pool(player)
			break


func _return_to_pool(player: Variant) -> void:
	player.stream = null
	# The pool handles recycling automatically through SoundPool
