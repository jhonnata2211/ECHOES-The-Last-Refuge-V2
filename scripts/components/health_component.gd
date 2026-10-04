class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal died()

@export var max_health: float = 100.0:
	set(value):
		if not is_finite(value) or value <= 0.0:
			return
		var previous_max: float = max_health
		max_health = value
		_current_health = clampf(_current_health, 0.0, max_health)
		if is_node_ready() and not is_equal_approx(previous_max, max_health):
			health_changed.emit(_current_health, max_health)

var current_health: float:
	get:
		return _current_health

var _current_health: float = 100.0


func _ready() -> void:
	_current_health = max_health
	health_changed.emit(_current_health, max_health)


func get_health() -> float:
	return _current_health


func take_damage(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_set_health(_current_health - amount)


func heal(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_set_health(_current_health + amount)


func _set_health(value: float) -> void:
	var next: float = clampf(value, 0.0, max_health)
	if is_equal_approx(next, _current_health):
		return
	var reached_zero: bool = _current_health > 0.0 and next == 0.0
	_current_health = next
	health_changed.emit(_current_health, max_health)
	if reached_zero:
		died.emit()
