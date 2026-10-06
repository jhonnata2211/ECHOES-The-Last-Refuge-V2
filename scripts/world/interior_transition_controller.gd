class_name InteriorTransitionController
extends Node

## SPRINT 05: áreas coexistem na Main; Player e componentes nunca são recriados.
signal area_changed(area_id: StringName)

@export var interior_scene: PackedScene = null
@export var interior_origin: Vector2 = Vector2(4096, 0)

var _player: CharacterBody2D = null
var _controls: CanvasLayer = null
var _panel: InventoryPanel = null
var _camera: Camera2D = null
var _footsteps: FootstepsComponent = null
var _noise: PlayerNoiseComponent = null
var _detector: InteractionDetector = null
var _interior: Node2D = null
var _return_spawn: Marker2D = null
var _outside: Array[Dictionary] = []
var _forest_limits: Rect2 = Rect2()
var _inside: bool = false
var _busy: bool = false


func configure(player: CharacterBody2D, controls: CanvasLayer, panel: InventoryPanel, outside: Array[Node2D], entrance: ScenePortal, return_spawn: Marker2D) -> bool:
	if _interior != null or interior_scene == null or not is_instance_valid(player) or not is_instance_valid(entrance) or not is_instance_valid(return_spawn):
		return false
	_player = player
	_controls = controls
	_panel = panel
	_return_spawn = return_spawn
	_camera = player.get_node_or_null("Camera2D") as Camera2D
	_footsteps = player.get_node_or_null("FootstepsComponent") as FootstepsComponent
	_noise = player.get_node_or_null("PlayerNoiseComponent") as PlayerNoiseComponent
	_detector = player.get_node_or_null("InteractionDetector") as InteractionDetector
	if _camera == null or _footsteps == null or _noise == null or _detector == null:
		return false
	_forest_limits = Rect2(Vector2(_camera.limit_left, _camera.limit_top), Vector2(_camera.limit_right - _camera.limit_left, _camera.limit_bottom - _camera.limit_top))
	_interior = interior_scene.instantiate() as Node2D
	if _interior == null:
		return false
	_interior.position = interior_origin
	_interior.hide()
	add_child(_interior)
	var exit_portal: ScenePortal = _interior.get_node_or_null("ExitPortal") as ScenePortal
	if exit_portal == null or _interior.get_node_or_null("EntrySpawn") == null or not _interior.has_meta("camera_bounds"):
		_interior.queue_free()
		_interior = null
		return false
	for node in outside:
		if is_instance_valid(node):
			_outside.append({"node": node, "visible": node.visible, "process_mode": node.process_mode})
	entrance.transition_requested.connect(_on_transition_requested)
	exit_portal.transition_requested.connect(_on_transition_requested)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	return true


func get_current_area() -> StringName:
	return &"house" if _inside else &"forest"


func get_interior() -> Node2D:
	return _interior


func is_transitioning() -> bool:
	return _busy


func _on_transition_requested(destination: StringName, actor: Node2D) -> void:
	if _busy or actor != _player or get_tree().paused or not is_instance_valid(_interior) or (is_instance_valid(_panel) and _panel.is_open()):
		return
	if (destination == &"house" and _inside) or (destination == &"forest" and not _inside) or destination not in [&"house", &"forest"]:
		return
	_busy = true
	# A interação ocorre durante física; mudar área após a consulta do detector.
	_perform_transition.call_deferred(destination)


func _perform_transition(destination: StringName) -> void:
	var entering: bool = destination == &"house"
	var previous_mode: ProcessMode = _player.process_mode
	var controls_were_visible: bool = _controls.visible
	_player.set_touch_direction(Vector2.ZERO)
	_player.set_touch_sprint_pressed(false)
	_player.velocity = Vector2.ZERO
	_footsteps.reset_steps()
	_noise.clear_noise()
	_controls.hide()
	_controls.get_node("InteractionButton").set_interaction_target(null)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_set_area_visible(entering)
	# Reativação dos corpos/áreas precisa passar pelo servidor de física.
	await get_tree().physics_frame
	await get_tree().process_frame
	if not is_inside_tree() or not is_instance_valid(_player):
		return
	var spawn: Vector2 = (_interior.get_node("EntrySpawn") as Marker2D).global_position if entering else _return_spawn.global_position
	var surface: StringName = &"wood" if entering else &"grass"
	if not _spawn_is_clear(spawn) or not _footsteps.set_surface(surface):
		_set_area_visible(_inside)
		_finish_transition(previous_mode, controls_were_visible)
		push_warning("SPRINT 05: transição recusada; spawn bloqueado ou superfície indisponível. Estado do jogador preservado.")
		return
	_player.global_position = spawn
	_player.velocity = Vector2.ZERO
	_inside = entering
	_apply_camera_bounds()
	# Limpar alvo da área anterior sem trocar a seleção/direção do Player.
	_detector.process_interaction(_player, _player.get_facing_vector())
	_finish_transition(previous_mode, controls_were_visible)
	area_changed.emit(get_current_area())


func _spawn_is_clear(position: Vector2) -> bool:
	var collision: CollisionShape2D = _player.get_node("CollisionShape2D") as CollisionShape2D
	if not position.is_finite() or collision == null or collision.shape == null:
		return false
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.transform.origin += position - _player.global_position
	query.collision_mask = _player.collision_mask
	query.exclude = [_player.get_rid()]
	query.collide_with_areas = false
	return _player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _set_area_visible(inside: bool) -> void:
	_interior.visible = inside
	for entry in _outside:
		# Coletáveis removidos não podem ser restaurados nem reaparecer.
		if not is_instance_valid(entry["node"]):
			continue
		var node: Node2D = entry["node"] as Node2D
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			node.visible = false if inside else bool(entry["visible"])
			node.process_mode = Node.PROCESS_MODE_DISABLED if inside else entry["process_mode"]


func _finish_transition(previous_mode: ProcessMode, controls_were_visible: bool) -> void:
	_player.process_mode = previous_mode
	_controls.visible = controls_were_visible and not get_tree().paused and not (is_instance_valid(_panel) and _panel.is_open())
	_busy = false


func _on_viewport_size_changed() -> void:
	if _inside and is_instance_valid(_camera):
		_apply_camera_bounds()


func _apply_camera_bounds() -> void:
	var bounds: Rect2 = _forest_limits
	if _inside:
		bounds = _interior.get_meta("camera_bounds")
		bounds.position += _interior.global_position
		# Canvas stretch expand pode mostrar uma área maior que 1280x720.
		# Centralizar a sala sem alterar zoom; fundo interno cobre as margens.
		var center: Vector2 = bounds.get_center()
		bounds.size = bounds.size.max(get_viewport().get_visible_rect().size / _camera.zoom)
		bounds.position = center - bounds.size * 0.5
	_camera.limit_left = roundi(bounds.position.x)
	_camera.limit_top = roundi(bounds.position.y)
	_camera.limit_right = roundi(bounds.end.x)
	_camera.limit_bottom = roundi(bounds.end.y)
	_camera.reset_smoothing()
	_camera.force_update_scroll()
