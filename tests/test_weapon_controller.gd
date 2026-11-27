extends ProjectTest

## Exercises loadout selection and repeated equipment changes on inherited NPC scene

const BARBARIAN: PackedScene = preload("uid://nd1uo24vt6d5") # barbarian.tscn
const CLUB: WeaponAsset = preload("uid://6m8vbwphmr1c") # stone_spiked_club.tres
const SWORD: WeaponAsset = preload("uid://bgdv4xkrfy3vg") # stone_sword.tres


func run_tests() -> void:
	for randomize_weapon: bool in [false, true]:
		var npc: NPCEntity = BARBARIAN.instantiate()
		var controller: WeaponController = npc.get_node("%WeaponController")
		controller.weapons = [SWORD, CLUB]
		controller.randomize_weapon = randomize_weapon
		controller.apply_weapon_damage = true
		controller.apply_weapon_attack_rate = true
		add_child(npc)
		var animation_player: AnimationPlayer = npc.get_node(^"%AnimationPlayer")
		var reset: Animation = animation_player.get_animation(&"RESET")
		var bounds_track: int = reset.find_track(^"Rig_Medium/Skeleton3D/RightHandAttachment/WeaponSwingTrail:custom_aabb", Animation.TYPE_VALUE)
		var trail: Trail3D = npc.weapon_visual.swing_trail
		assert(trail and bounds_track >= 0, "Missing trail or bounds reset in " + name)
		assert(reset.track_get_key_value(bounds_track, 0) == AABB(), "Trail RESET must clear generated bounds in " + name)
		assert(controller.weapons.has(controller.equipped_weapon), "Weapon outside loadout in " + name)
		assert(randomize_weapon or controller.equipped_weapon == SWORD, "Expected first weapon in " + name)

		for weapon: WeaponAsset in [CLUB, SWORD, CLUB]:
			controller.equip_weapon(weapon)
			var base: Attack = npc.attack_component.attack
			assert(npc.attack.damage == maxi(1, roundi(base.damage * weapon.damage_multiplier)), "Wrong melee damage in " + name)
			assert(is_equal_approx(npc.attack.rate, base.rate / weapon.attack_speed_multiplier), "Wrong attack rate in " + name)
			assert(npc.weapon_visual.socket.get_child_count() == 1, "Weapon meshes accumulated in " + name)
		for apply_damage: bool in [false, true]:
			for apply_rate: bool in [false, true]:
				controller.apply_weapon_damage = apply_damage
				controller.apply_weapon_attack_rate = apply_rate
				controller.equip_weapon(CLUB)
				var base: Attack = npc.attack_component.attack
				var damage: int = roundi(base.damage * CLUB.damage_multiplier) if apply_damage else base.damage
				var rate: float = base.rate / CLUB.attack_speed_multiplier if apply_rate else base.rate
				assert(npc.attack.damage == damage and is_equal_approx(npc.attack.rate, rate), "Wrong weapon modifiers in " + name)
		npc.free()
	print("Weapon controller test completed")
