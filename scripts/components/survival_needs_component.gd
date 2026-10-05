class_name SurvivalNeedsComponent
extends Node

signal hunger_changed(current: float, maximum: float)
signal thirst_changed(current: float, maximum: float)
signal critical_state_changed(hunger_critical: bool, thirst_critical: bool)
signal zero_state_changed(hunger_empty: bool, thirst_empty: bool)

const MAX_NEED: float = 100.0

@export_range(0.0, 100.0, 0.1) var initial_hunger: float = 100.0
@export_range(0.0, 100.0, 0.1) var initial_thirst: float = 100.0
@export_range(0.0, 10.0, 0.001, "or_greater") var hunger_drain_per_second: float = 1.0 / 30.0
@export_range(0.0, 10.0, 0.001, "or_greater") var thirst_drain_per_second: float = 0.05
@export_range(0.0, 100.0, 0.1) var critical_threshold: float = 20.0

var _hunger: float = MAX_NEED
var _thirst: float = MAX_NEED


func _ready() -> void:
	if is_finite(initial_hunger) and is_finite(initial_thirst):
		_set_values(initial_hunger, initial_thirst)


func _physics_process(delta: float) -> void:
	advance_time(delta)


func get_hunger() -> float:
	return _hunger


func get_thirst() -> float:
	return _thirst


func get_max_hunger() -> float:
	return MAX_NEED


func get_max_thirst() -> float:
	return MAX_NEED


func is_hunger_critical() -> bool:
	return _hunger <= clampf(critical_threshold, 0.0, MAX_NEED)


func is_thirst_critical() -> bool:
	return _thirst <= clampf(critical_threshold, 0.0, MAX_NEED)


func is_hunger_empty() -> bool:
	return _hunger == 0.0


func is_thirst_empty() -> bool:
	return _thirst == 0.0


func advance_time(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	var hunger_rate: float = hunger_drain_per_second if is_finite(hunger_drain_per_second) else 0.0
	var thirst_rate: float = thirst_drain_per_second if is_finite(thirst_drain_per_second) else 0.0
	_set_values(_hunger - maxf(hunger_rate, 0.0) * seconds, _thirst - maxf(thirst_rate, 0.0) * seconds)


func deplete_hunger(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_set_values(_hunger - amount, _thirst)


func deplete_thirst(amount: float) -> void:
	if is_finite(amount) and amount > 0.0:
		_set_values(_hunger, _thirst - amount)


func can_restore(hunger_amount: float, thirst_amount: float) -> bool:
	if not is_finite(hunger_amount) or not is_finite(thirst_amount) or hunger_amount < 0.0 or thirst_amount < 0.0:
		return false
	return (hunger_amount > 0.0 and _hunger < MAX_NEED) or (thirst_amount > 0.0 and _thirst < MAX_NEED)


func restore(hunger_amount: float, thirst_amount: float) -> bool:
	if not can_restore(hunger_amount, thirst_amount):
		return false
	_set_values(_hunger + hunger_amount, _thirst + thirst_amount)
	return true


func restore_hunger(amount: float) -> bool:
	return restore(amount, 0.0)


func restore_thirst(amount: float) -> bool:
	return restore(0.0, amount)


func _set_values(hunger: float, thirst: float) -> void:
	var old_hunger_critical: bool = is_hunger_critical()
	var old_thirst_critical: bool = is_thirst_critical()
	var old_hunger_empty: bool = is_hunger_empty()
	var old_thirst_empty: bool = is_thirst_empty()
	var next_hunger: float = clampf(hunger, 0.0, MAX_NEED)
	var next_thirst: float = clampf(thirst, 0.0, MAX_NEED)
	# Comparação exata: a drenagem por frame é menor que tolerâncias relativas comuns.
	var hunger_different: bool = next_hunger != _hunger
	var thirst_different: bool = next_thirst != _thirst
	_hunger = next_hunger
	_thirst = next_thirst
	if hunger_different:
		hunger_changed.emit(_hunger, MAX_NEED)
	if thirst_different:
		thirst_changed.emit(_thirst, MAX_NEED)
	if old_hunger_critical != is_hunger_critical() or old_thirst_critical != is_thirst_critical():
		critical_state_changed.emit(is_hunger_critical(), is_thirst_critical())
	if old_hunger_empty != is_hunger_empty() or old_thirst_empty != is_thirst_empty():
		zero_state_changed.emit(is_hunger_empty(), is_thirst_empty())
