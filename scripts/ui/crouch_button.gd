@tool
extends Control

signal crouch_toggle_requested()

## ECHOES-037: visual placeholder; um toggle por início de toque proprietário.
const BASE_COLOR := Color(0.18, 0.25, 0.20, 0.45)
const ACTIVE_COLOR := Color(0.45, 0.65, 0.35, 0.65)
const OUTLINE_COLOR := Color(0.7, 0.85, 0.65, 0.75)

@export_range(24.0, 128.0, 1.0) var button_radius: float = 64.0
var _active_touch_index: int = -1
var _crouched: bool = false
var _pressed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2.ONE * button_radius * 2.0
	resized.connect(_reset_touch)
	get_viewport().size_changed.connect(_reset_touch)
	set_process_input(not Engine.is_editor_hint())
	set_crouched(_crouched)


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var color: Color = ACTIVE_COLOR if _crouched else BASE_COLOR
	if _pressed:
		color.a = minf(color.a + 0.15, 1.0)
	draw_circle(center, button_radius, color)
	draw_circle(center, button_radius, OUTLINE_COLOR, false, 2.0)


func set_crouched(value: bool) -> void:
	# O estado pertence ao componente, não ao botão; teclado também atualiza a UI.
	_crouched = value
	var label: Label = get_node_or_null("Label") as Label
	if label != null:
		label.text = "LEVANTAR" if _crouched else "AGACHAR"
	queue_redraw()


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree() or not can_process():
		return
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if _active_touch_index != -1 and touch.index == _active_touch_index:
			if not touch.pressed or touch.canceled:
				_reset_touch()
			get_viewport().set_input_as_handled()
		elif _active_touch_index == -1 and touch.pressed and not touch.canceled:
			var local_touch: InputEventScreenTouch = make_input_local(touch) as InputEventScreenTouch
			if local_touch.position.distance_squared_to(size * 0.5) <= button_radius * button_radius:
				_active_touch_index = touch.index
				_pressed = true
				queue_redraw()
				get_viewport().set_input_as_handled()
				crouch_toggle_requested.emit()
	elif event is InputEventScreenDrag and _active_touch_index != -1 and event.index == _active_touch_index:
		# Nunca adquirir um dedo pelo arrasto vindo de outro controle.
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_reset_touch()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_reset_touch()


func _reset_touch() -> void:
	_active_touch_index = -1
	_pressed = false
	# Ocultação/cancelamento libera o dedo, mas preserva a postura lógica.
	queue_redraw()
