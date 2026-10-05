class_name SurvivalDamageComponent
extends Node

@export_range(0.1, 60.0, 0.1, "or_greater") var damage_interval: float = 5.0
@export_range(0.0, 100.0, 0.1, "or_greater") var damage_amount: float = 1.0

var _needs: SurvivalNeedsComponent = null
var _health: HealthComponent = null
var _elapsed: float = 0.0


func bind_sources(needs: SurvivalNeedsComponent, health: HealthComponent) -> void:
	if is_instance_valid(_needs) and _needs.zero_state_changed.is_connected(_on_zero_state_changed):
		_needs.zero_state_changed.disconnect(_on_zero_state_changed)
	_needs = needs
	_health = health
	_elapsed = 0.0
	if is_instance_valid(_needs):
		_needs.zero_state_changed.connect(_on_zero_state_changed)


func _physics_process(delta: float) -> void:
	advance_time(delta)


func advance_time(seconds: float) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	if not _in_danger() or not is_finite(damage_interval) or damage_interval <= 0.0 \
		or not is_finite(damage_amount) or damage_amount <= 0.0:
		_elapsed = 0.0
		return
	_elapsed += seconds
	while _elapsed >= damage_interval and _in_danger():
		_elapsed -= damage_interval
		_health.take_damage(damage_amount)


func _in_danger() -> bool:
	return is_instance_valid(_needs) and is_instance_valid(_health) \
		and not _needs.is_queued_for_deletion() and not _health.is_queued_for_deletion() \
		and _health.get_health() > 0.0 and (_needs.is_hunger_empty() or _needs.is_thirst_empty())


func _on_zero_state_changed(hunger_empty: bool, thirst_empty: bool) -> void:
	if not hunger_empty and not thirst_empty:
		_elapsed = 0.0
