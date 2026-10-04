extends ScrollContainer

# Gesto touch próprio; a rolagem não depende da emulação de mouse.
var _touch_index: int = -1
var _last_y: float = 0.0
var _drag_value: float = 0.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if _touch_index != -1 and event.index == _touch_index:
			if not event.pressed or event.canceled:
				_reset_touch()
			get_viewport().set_input_as_handled()
		elif event.pressed and not event.canceled and _contains(event):
			if _touch_index == -1:
				_touch_index = event.index
				_last_y = _local_position(event).y
				_drag_value = float(scroll_vertical)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _touch_index != -1 and event.index == _touch_index:
		var y: float = _local_position(event).y
		var bar: VScrollBar = get_v_scroll_bar()
		_drag_value = clampf(_drag_value + _last_y - y, 0.0, maxf(0.0, bar.max_value - bar.page))
		scroll_vertical = roundi(_drag_value)
		_last_y = y
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if _touch_index != -1 or _contains(event):
			get_viewport().set_input_as_handled()


func _local_position(event: InputEvent) -> Vector2:
	return make_input_local(event).get("position")


func _contains(event: InputEvent) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(_local_position(event))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_reset_touch()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_WM_WINDOW_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_reset_touch()


func _reset_touch() -> void:
	_touch_index = -1
