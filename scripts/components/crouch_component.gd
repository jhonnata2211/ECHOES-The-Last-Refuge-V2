class_name CrouchComponent
extends Node

## ECHOES-038: estado lógico; arte própria de crouch ainda não existe.
signal crouch_changed(crouched: bool)

@export_range(1.0, 320.0, 1.0) var crouch_speed: float = 110.0
var _crouched: bool = false


func is_crouched() -> bool:
	return _crouched


func get_move_speed() -> float:
	return maxf(crouch_speed, 1.0) if is_finite(crouch_speed) else 110.0


func request_toggle() -> void:
	set_crouched(not _crouched)


func set_crouched(value: bool) -> void:
	if _crouched == value:
		return
	_crouched = value
	crouch_changed.emit(_crouched)
