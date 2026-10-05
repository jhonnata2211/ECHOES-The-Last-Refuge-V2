class_name PlayerNoiseComponent
extends Node

## ECHOES-039: intensidade de gameplay, independente da mixagem dos MP3.
signal noise_changed(level: float)

@export_range(0.0, 1.0, 0.01) var crouch_noise: float = 0.25
@export_range(0.0, 1.0, 0.01) var walk_noise: float = 0.60
@export_range(0.0, 1.0, 0.01) var sprint_noise: float = 1.0
@export_range(0.0, 0.1, 0.001) var significant_change: float = 0.01
@export_range(0.0001, 1.0, 0.0001) var minimum_displacement: float = 0.001

var _noise_level: float = 0.0
var _last_emitted: float = 0.0


func update_motion(displacement: Vector2, crouched: bool, sprinting: bool) -> void:
	if not displacement.is_finite() or displacement.length() <= maxf(minimum_displacement, 0.0001):
		clear_noise()
		return
	var value: float = crouch_noise if crouched else (sprint_noise if sprinting else walk_noise)
	_set_noise(value)


func get_noise_level() -> float:
	return _noise_level


func get_noise_origin() -> Vector2:
	var origin: Node2D = get_parent() as Node2D
	return origin.global_position if is_instance_valid(origin) else Vector2.ZERO


func has_relevant_noise() -> bool:
	return _noise_level > 0.0 and is_inside_tree() and can_process()


func clear_noise() -> void:
	_set_noise(0.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		clear_noise()


func _set_noise(value: float) -> void:
	_noise_level = clampf(value, 0.0, 1.0) if is_finite(value) else 0.0
	var threshold: float = clampf(significant_change, 0.0, 0.1) if is_finite(significant_change) else 0.01
	# Transições de/para zero são sempre comunicadas, mesmo abaixo do limiar.
	if (_noise_level == 0.0) != (_last_emitted == 0.0) or absf(_noise_level - _last_emitted) > threshold or (_noise_level != _last_emitted and threshold == 0.0):
		_last_emitted = _noise_level
		noise_changed.emit(_noise_level)
