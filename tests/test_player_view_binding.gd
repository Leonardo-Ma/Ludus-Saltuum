extends ProjectTest

## Verifies late HUD binding and switching between two live players

const PLAYER_SCENE: PackedScene = preload("uid://dwxbechemu2kl") # player.tscn
const UI_SCENE: PackedScene = preload("uid://cwgqh61gpa36j") # ui.tscn
const SKILL_CATALOGUE: SkillCatalogue = preload("uid://6ygr0ieawafb") # skill_catalogue.tres
const SPEED_BUFF: StatusEffect = preload("uid://62y38laatth2") # speed_up.tres


func run_tests() -> void:
	var first: PlayerEntity = PLAYER_SCENE.instantiate()
	var second: PlayerEntity = PLAYER_SCENE.instantiate()
	var first_economy: EconomyController = first.get_node(^"%EconomyController")
	var second_economy: EconomyController = second.get_node(^"%EconomyController")
	var first_skills: SkillsController = first.get_node(^"%SkillsController")
	var second_skills: SkillsController = second.get_node(^"%SkillsController")
	var first_input: InputController = first.get_node(^"%InputController")
	var second_input: InputController = second.get_node(^"%InputController")
	var skill: SkillDefinition = SKILL_CATALOGUE.definitions[0]
	first_skills.startup_skills = [skill]
	ControlledEntityEvents.player_finished_spawning.connect(
		func(spawned: Node3D) -> void:
			assert(spawned == first and first_skills.get_skill(skill) != null, "Spawn completed before startup skills in " + name)
			assert(not first_input.is_processing_input(), "Player input active during menu spawn in " + name),
		CONNECT_ONE_SHOT,
	)
	add_child(first)
	add_child(second)

	first_economy.add_score(25)
	first_economy.add_gold(4)
	second_economy.add_score(50)
	second_economy.add_gold(8)

	var pickup: StatusCollectible = StatusCollectible.new()
	pickup.status_effect = SPEED_BUFF
	pickup.stack_mode = StatusEffect.StackMode.ADD_DURATION
	pickup.tick_interval = 0.0
	pickup.apply_effect(first)
	var active_buff: ActiveStatusEffect = first.status_manager.get_active_statuses()[0]
	active_buff.process_time(2.0)

	ControlledEntityEvents.set_controlled_entity(first)
	var ui: UIView = UI_SCENE.instantiate()
	add_child(ui)
	var hud: HUDView = ui.get_node(^"%HUD")
	var score_view: ScoreView = hud.get_node(^"%Score")
	var gold_view: GoldView = hud.get_node(^"%Gold")
	var score: Label = score_view.get_node(^"%ScoreCounter")
	var gold: Label = gold_view.get_node(^"%GoldCounter")
	var checkpoint: ReturnCheckpointIndicator = hud.get_node(^"%ReturnCheckpoingProgress")
	var buff_slot: PowerUpSlot = hud.power_ups.power_ups_container.get_child(0)
	var buff_progress: TextureProgressBar = buff_slot.get_node(^"%CooldownProgress")

	assert(score.text == "25" and gold.text == "4" and hud.skills_panel.visible, "Late HUD missed assigned player's initial state in " + name)
	assert(buff_slot.visible and buff_progress.texture_progress == SPEED_BUFF.hud_icon, "Late HUD missed active buff in " + name)
	assert(is_equal_approx(buff_progress.value, 20.0), "Late HUD missed elapsed buff time in " + name)
	pickup.apply_effect(first)
	assert(is_equal_approx(buff_progress.value, 10.0), "HUD missed extended buff timer in " + name)

	ControlledEntityEvents.set_controlled_entity(null)
	assert(score.text == "0" and gold.text == "0" and not hud.skills_panel.visible, "HUD retained state after control was cleared in " + name)
	ControlledEntityEvents.set_controlled_entity(first)
	assert(score.text == "25" and gold.text == "4" and hud.skills_panel.visible, "HUD missed reassigned player's state in " + name)

	ControlledEntityEvents.set_controlled_entity(second)
	assert(
		is_equal_approx(Achievements.get_progress_ratio(AchievementDefinition.Id.SCORE_100), 0.5),
		"Achievements missed selected player's score in " + name,
	)
	first_economy.add_score(10)
	first_economy.add_gold(10)
	first_skills.unlock(skill)
	first_input.return_hold_started.emit(1.0)
	first.health.current_health -= 1
	pickup.apply_effect(first)
	assert(score.text == "50" and gold.text == "8", "Old player's economy updated rebound HUD in " + name)
	assert(not hud.skills_panel.visible and not checkpoint.visible, "Old player's skills or input updated rebound HUD in " + name)
	assert(hud.player_healthbar.value == second.health.current_health, "Old player's health updated rebound HUD in " + name)
	assert(not buff_slot.visible, "Old player's buff updated rebound HUD in " + name)

	second_economy.add_score(20)
	second_economy.add_gold(8)
	second_skills.unlock(skill)
	second_input.return_hold_started.emit(1.0)
	second.health.current_health -= 1
	assert(score.text == "70" and gold.text == "16", "New player's economy did not update HUD in " + name)
	assert(
		is_equal_approx(Achievements.get_progress_ratio(AchievementDefinition.Id.SCORE_100), 0.7),
		"Selected player's points did not update achievements in " + name,
	)
	assert(hud.skills_panel.visible and checkpoint.visible, "New player's skills or input did not update HUD in " + name)
	assert(hud.player_healthbar.value == second.health.current_health, "New player's health did not update HUD in " + name)
	second.status_manager.apply_status(SPEED_BUFF, 5.0, StatusEffect.StackMode.REPLACE, 1, 0.0)
	assert(buff_slot.visible and is_zero_approx(buff_progress.value), "Direct status application did not update HUD in " + name)
	var second_buff: ActiveStatusEffect = second.status_manager.get_active_statuses()[0]
	second_buff.process_time(5.0)
	assert(not buff_slot.visible, "Expired buff stayed visible in " + name)

	_test_cosmetics(ui, second_economy)
	second.free()
	assert(score.text == "0" and gold.text == "0" and not checkpoint.visible, "Unbound HUD retained player state in " + name)
	assert(ControlledEntityEvents.controlled_entity == null, "Freed player remained assigned as controlled entity in " + name)
	ui.free()


func _test_cosmetics(ui: UIView, economy: EconomyController) -> void:
	var menus: MenusView = ui.get_node(^"%Menus")
	var cosmetics_menu: CosmeticsMenuView = menus.get_node(^"%CosmeticsMenu")
	var weapon_cards: CosmeticSlotTab = cosmetics_menu.get_node(^"%WeaponsTab")
	var gold_view: GoldView = cosmetics_menu.get_node(^"%Gold")
	var card: CosmeticCard = weapon_cards.get_child(2)
	var button: BuyCosmeticButton = card.get_node(^"%BuyCosmetic")
	var gold_label: Label = gold_view.get_node(^"%GoldCounter")
	var gold_icon: TextureRect = gold_view.get_node(^"%GoldIcon")
	var price: int = card.asset.price
	assert(button.disabled, "Unaffordable cosmetic was enabled in " + name)
	assert(button.icon == gold_icon.texture and button.text == str(price), "Purchase button lost gold icon or price in " + name)
	economy.add_gold(price)
	assert(not button.disabled and gold_label.text == str(economy.gold), "Cosmetics menu missed gold update in " + name)
	button.pressed.emit()
	assert(button.disabled and button.icon == button.equipped_texture, "Purchase did not equip cosmetic in " + name)
	assert(gold_label.text == "16", "Purchase did not refresh balance in " + name)
	var cosmetics: CosmeticsController = economy.get_node(^"%CosmeticsController")
	cosmetics.reset()
	assert(
		button.icon == gold_icon.texture and button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT,
		"Reset lost purchase icon or alignment in " + name,
	)
	var controlled_entity: Node3D = ControlledEntityEvents.controlled_entity
	ControlledEntityEvents.set_controlled_entity(null)
	assert(button.disabled and button.text == str(price), "Unbound cosmetic did not show a disabled price in " + name)
	assert(not button.has_theme_color_override(&"font_disabled_color"), "Unbound cosmetic retained affordability color in " + name)
	ControlledEntityEvents.set_controlled_entity(controlled_entity)
