@tool
extends Control

signal interaction_requested()

# ECHOES-018C: botão placeholder; um pedido por início de toque válido.
const BASE_COLOR := Color(0.2, 0.32, 0.25, 0.5)
const PRESSED_COLOR := Color(0.3, 0.85, 0.6, 0.65)
const OUTLINE_COLOR := Color(0.7, 0.9, 0.8, 0.75)

var _active_touch_index: int = -1
var _pressed: bool = false
var _interaction_target: Node

@export_range(24.0, 128.0, 1.0, "or_greater") var button_radius: float = 64.0:
	set(value):
		button_radius = maxf(value, 24.0)
		_refresh_geometry()


func _ready() -> void:
	resized.connect(_reset_touch)
	get_viewport().size_changed.connect(_reset_touch)
	_refresh_geometry()
	set_process_input(not Engine.is_editor_hint())


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, button_radius, PRESSED_COLOR if _pressed else BASE_COLOR)
	draw_circle(center, button_radius, OUTLINE_COLOR, false, 2.0)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if _active_touch_index != -1 and touch.index == _active_touch_index:
			if not touch.pressed or touch.canceled:
				_reset_touch()
				get_viewport().set_input_as_handled()
		elif _active_touch_index == -1 and touch.pressed and not touch.canceled:
			var local_touch := make_input_local(touch) as InputEventScreenTouch
			if local_touch.position.distance_squared_to(size * 0.5) <= button_radius * button_radius:
				_active_touch_index = touch.index
				_pressed = true
				queue_redraw()
				get_viewport().set_input_as_handled()
				interaction_requested.emit()
	elif event is InputEventScreenDrag and _active_touch_index != -1 and event.index == _active_touch_index:
		# Arrasto mantém a posse, mas nunca cria novos pedidos.
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_reset_touch()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_WM_WINDOW_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_reset_touch()


func is_pressed() -> bool:
	return _pressed


func set_interaction_target(target: Node) -> void:
	# ECHOES-018D: a disponibilidade é decidida pelo detector, sem polling na UI.
	if is_instance_valid(_interaction_target):
		if _interaction_target.tree_exiting.is_connected(_on_target_exiting):
			_interaction_target.tree_exiting.disconnect(_on_target_exiting)
	_interaction_target = target
	visible = is_instance_valid(target)
	if visible:
		# Ocultar também se o alvo sair da árvore antes da próxima atualização.
		target.tree_exiting.connect(_on_target_exiting, CONNECT_ONE_SHOT)


func _on_target_exiting() -> void:
	_interaction_target = null
	hide()


func _reset_touch() -> void:
	_active_touch_index = -1
	_pressed = false
	queue_redraw()


func _refresh_geometry() -> void:
	custom_minimum_size = Vector2.ONE * button_radius * 2.0
	_reset_touch()
