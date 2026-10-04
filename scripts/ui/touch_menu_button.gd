extends Button

# Botão de menu: mouse/teclado nativos e toque com propriedade de dedo.
var _touch_index: int = -1


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or disabled:
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		if _touch_index != -1 or _contains(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.index == _touch_index and _touch_index != -1:
			if not event.pressed or event.canceled:
				var activate: bool = not event.canceled and _contains(event)
				_reset_touch()
				get_viewport().set_input_as_handled()
				if activate:
					pressed.emit()
		elif _touch_index == -1 and event.pressed and not event.canceled and _contains(event):
			_touch_index = event.index
			set_pressed_no_signal(true)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_index and _touch_index != -1:
		set_pressed_no_signal(_contains(event))
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	# Não duplicar a ação com o mouse emulado a partir do mesmo toque.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		accept_event()


func _contains(event: InputEvent) -> bool:
	var local_event: InputEvent = make_input_local(event)
	return Rect2(Vector2.ZERO, size).has_point(local_event.get("position"))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_reset_touch()
		NOTIFICATION_EXIT_TREE, NOTIFICATION_WM_WINDOW_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT, MainLoop.NOTIFICATION_APPLICATION_PAUSED:
			_reset_touch()


func _reset_touch() -> void:
	_touch_index = -1
	set_pressed_no_signal(false)
