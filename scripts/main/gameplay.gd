extends Node2D

var _owns_pause: bool = false
var _previous_pause: bool = false
var _resume_serial: int = 0


func _ready() -> void:
	$StealthPrototypeThreat.configure_world($TestWorld/Tiles/Terrain, $TestWorld/Tiles/Obstacles)
	var house_bounds: Rect2 = $AbandonedHouse.get_meta("solid_bounds")
	house_bounds.position += $AbandonedHouse.global_position
	$StealthPrototypeThreat/ThreatGridNavigator.reserve_world_rect(house_bounds)
	$StealthPrototypeThreat.bind_noise_source($Player/PlayerNoiseComponent)
	$StealthTestListener/NoiseListenerComponent.bind_source($Player/PlayerNoiseComponent)
	$Player/SurvivalDamageComponent.bind_sources($Player/SurvivalNeedsComponent, $Player/HealthComponent)
	$Player/ConsumableUseComponent.bind_sources($Player/Inventory, $Player/SurvivalNeedsComponent)
	$GameplayHUD.bind_sources($Player/HealthComponent, $Player)
	$GameplayHUD.bind_survival($Player/SurvivalNeedsComponent)
	$InventoryPanel.bind_inventory($Player/Inventory)
	$InventoryPanel.bind_consumer($Player/ConsumableUseComponent)
	$InventorySoundFeedback.bind_sources($InventoryPanel, $Player/ConsumableUseComponent)
	$InventoryPanel.open_changed.connect(_on_inventory_open_changed)
	var sound: SoundExperienceController = get_tree().root.get_node("SoundExperience")
	var outside: Array[Node2D] = [$TestWorld, $InteractionTestObject, $Sucata, $Sucata2, $Water, $Water2, $Food, $Food2, $StealthTestListener, $StealthPrototypeThreat, $AbandonedHouse]
	if not $InteriorTransition.configure($Player, $TouchControls, $InventoryPanel, outside, $AbandonedHouse/Entrance, $AbandonedHouse/ReturnSpawn):
		$AbandonedHouse/Entrance/Interactable.enabled = false
		push_error("SPRINT 05: interior indisponível; porta desabilitada sem alterar Player.")
	$InteriorTransition.area_changed.connect(_on_area_changed)
	sound.start_forest()


func _on_area_changed(area_id: StringName) -> void:
	var sound: SoundExperienceController = get_tree().root.get_node("SoundExperience")
	sound.set_forest_interior(area_id == &"house")


func _on_inventory_open_changed(opened: bool) -> void:
	_resume_serial += 1
	var serial: int = _resume_serial
	if opened:
		if not _owns_pause:
			_previous_pause = get_tree().paused
			_owns_pause = true
		$TouchControls.hide()
		$Player/FootstepsComponent.reset_steps()
		$Player/PlayerNoiseComponent.clear_noise()
		$StealthTestListener/NoiseListenerComponent.refresh_perception()
		$Player.set_touch_direction(Vector2.ZERO)
		$Player.set_touch_sprint_pressed(false)
		get_tree().paused = true
	else:
		# Descartar bordas de input produzidas no frame de fechamento do modal.
		get_tree().physics_frame.connect(_resume_after_physics.bind(serial), CONNECT_ONE_SHOT)


func _resume_after_physics(serial: int) -> void:
	if is_inside_tree() and serial == _resume_serial:
		get_tree().process_frame.connect(_resume_gameplay.bind(serial), CONNECT_ONE_SHOT)


func _resume_gameplay(serial: int) -> void:
	if not is_inside_tree() or serial != _resume_serial or $InventoryPanel.is_open():
		return
	if _owns_pause:
		get_tree().paused = _previous_pause
		_owns_pause = false
	$TouchControls.show()
	$TouchControls/InteractionButton.set_interaction_target($Player/InteractionDetector.get_current_target())


func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = _previous_pause
