@tool
extends Control

signal direction_changed(direction: Vector2)

# ECHOES-015B: visual placeholder desenhado com primitivas nativas.
const BASE_COLOR := Color(0.12, 0.22, 0.35, 0.42)
const KNOB_COLOR := Color(0.25, 0.75, 1.0, 0.75)

var _active_touch_index: int = -1
var _direction := Vector2.ZERO
var _knob_offset := Vector2.ZERO

@export_range(2.0, 256.0, 1.0, "or_greater") var base_radius: float = 80.0:
	set(value):
		base_radius = maxf(value, 2.0)
		knob_radius = minf(knob_radius, base_radius - 1.0)
		_refresh_geometry()

@export_range(1.0, 128.0, 1.0, "or_greater") var knob_radius: float = 28.0:
	set(value):
		knob_radius = clampf(value, 1.0, base_radius - 1.0)
		_reset_touch()

@export_range(0.0, 0.95, 0.01) var deadzone: float = 0.18:
	set(value):
		deadzone = clampf(value, 0.0, 0.95)
		_reset_touch()


func _ready() -> void:
	resized.connect(_reset_touch)
	get_viewport().size_changed.connect(_reset_touch)
	_refresh_geometry()
	set_process_input(not Engine.is_editor_hint())


func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, BASE_COLOR)
	draw_circle(center + _knob_offset, knob_radius, KNOB_COLOR)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.index == _active_touch_index and _active_touch_index != -1:
			if not touch.pressed or touch.canceled:
				_reset_touch()
				get_viewport().set_input_as_handled()
		elif _active_touch_index == -1 and touch.pressed and not touch.canceled:
			var local_touch := make_input_local(touch) as InputEventScreenTouch
			if local_touch.position.distance_squared_to(size * 0.5) <= base_radius * base_radius:
				_active_touch_index = touch.index
				_update_from_position(local_touch.position)
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _active_touch_index:
		var local_drag := make_input_local(event) as InputEventScreenDrag
		_update_from_position(local_drag.position)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_reset_touch()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_WM_WINDOW_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_reset_touch()


func get_direction() -> Vector2:
	return _direction


func _update_from_position(local_position: Vector2) -> void:
	var travel_radius := base_radius - knob_radius
	_knob_offset = (local_position - size * 0.5).limit_length(travel_radius)
	var strength := minf(_knob_offset.length() / travel_radius, 1.0)
	var effective_direction := Vector2.ZERO
	if strength > deadzone:
		var remapped_strength := clampf((strength - deadzone) / (1.0 - deadzone), 0.0, 1.0)
		effective_direction = _knob_offset.normalized() * remapped_strength
	_set_direction(effective_direction)
	queue_redraw()


func _set_direction(value: Vector2, force_emit: bool = false) -> void:
	if not force_emit and _direction == value:
		return
	_direction = value
	direction_changed.emit(_direction)


func _reset_touch() -> void:
	var had_touch := _active_touch_index != -1
	_active_touch_index = -1
	_knob_offset = Vector2.ZERO
	# Toda liberação/cancelamento de um dedo proprietário comunica o repouso.
	_set_direction(Vector2.ZERO, had_touch)
	queue_redraw()


func _refresh_geometry() -> void:
	custom_minimum_size = Vector2.ONE * base_radius * 2.0
	_reset_touch()
