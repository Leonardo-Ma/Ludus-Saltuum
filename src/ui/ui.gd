# TODO Rename file to ui_view
class_name UIView
extends CanvasLayer

## View controller UI scene root. Implements View of MVC
## Registers itself to UIManager

var _player: PlayerEntity

@onready var _menus: MenusView = %Menus
@onready var _hud: HUDView = %HUD
@onready var _overlays: OverlaysView = %Overlays
@onready var _popups: PopupsManager = %Popups
@onready var _debug: DebugView = %DebugInterface


func _ready() -> void:
	UIManager.register_ui(self)

	for child: Control in get_children():
		assert(
			child.z_index != 0,
			child.name + " is missing CanvasItem > Ordering > Z Index. All children of UI must have manual screen ordering set",
		)

	present(ApplicationStateManager.get_current_state())
	ControlledEntityEvents.controlled_entity_changed.connect(_on_controlled_entity_changed)
	var controlled_entity: Node3D = ControlledEntityEvents.controlled_entity
	if is_instance_valid(controlled_entity) and controlled_entity is PlayerEntity:
		bind_player(controlled_entity)
	else:
		_clear_player_features()


#region Presentation
## Menus show screen registered for state, HUD / overlays / popups only while playing
## Open popups are closed by PopupsManager on state change
func present(state: ApplicationStateManager.GameState) -> void:
	var is_playing: bool = state == ApplicationStateManager.GameState.PLAYING
	_menus.show_screen(state)
	_hud.visible = is_playing and UIManager.hud_visible
	_overlays.visible = is_playing
	_popups.visible = is_playing


func has_open_popup() -> bool:
	return _popups.has_open_popup()


func close_open_popup() -> void:
	_popups.close_open_popup()


func request_confirmation(icons: Array[CompressedTexture2D]) -> bool:
	if not _popups.open_confirmation(icons):
		return false

	var confirmed: bool = await _popups.confirmation_popup.choice_made
	return confirmed


func open_save_name_editor(slot_index: int, current_name: String, submit: Callable) -> void:
	_popups.open_save_name_editor(slot_index, current_name, submit)


func set_hud_visible(_hud_visible: bool) -> void:
	_hud.visible = _hud_visible and ApplicationStateManager.is_in_state(ApplicationStateManager.GameState.PLAYING)
#endregion


#region Player binding
func _on_controlled_entity_changed(entity: Node3D) -> void:
	if entity is PlayerEntity and entity != _player:
		bind_player(entity)
	elif entity == null and _player != null:
		bind_player(null)


## Assigns this view's gameplay data source after its children are ready
func bind_player(player: PlayerEntity) -> void:
	if is_instance_valid(_player):
		if _player.ready.is_connected(_bind_player_features):
			_player.ready.disconnect(_bind_player_features)
		if _player.tree_exiting.is_connected(_on_player_exiting):
			_player.tree_exiting.disconnect(_on_player_exiting)
	_player = player
	if _player == null:
		_clear_player_features()
		return
	_player.tree_exiting.connect(_on_player_exiting, CONNECT_ONE_SHOT)
	if _player.is_node_ready():
		_bind_player_features()
	else:
		_clear_player_features()
		_player.ready.connect(_bind_player_features, CONNECT_ONE_SHOT)


func _on_player_exiting() -> void:
	bind_player(null)


func _clear_player_features() -> void:
	_hud.bind_player_features(null, null, null, null, null)
	_overlays.bind_player_features(null, null, null)
	_menus.bind_player_features(null, null)
	if is_instance_valid(_debug):
		_debug.bind_player(null, null)


func _bind_player_features() -> void:
	var economy: EconomyController = _player.get_node(^"%EconomyController")
	var skills: SkillsController = _player.get_node(^"%SkillsController")
	var input: InputController = _player.get_node(^"%InputController")
	var cosmetics: CosmeticsController = _player.get_node(^"%CosmeticsController")
	var transition: EnvironmentTransitionController = _player.get_node(^"%EnvironmentTransitionController")
	_hud.bind_player_features(economy, skills, input, _player.health, _player.status_manager)
	_overlays.bind_player_features(_player.health, cosmetics, transition)
	_menus.bind_player_features(economy, cosmetics)
	if is_instance_valid(_debug):
		var movement: PlayerMovementComponent = _player.get_node(^"%PlayerMovementComponent")
		_debug.bind_player(_player, movement)
#endregion
