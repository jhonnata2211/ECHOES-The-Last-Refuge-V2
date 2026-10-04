class_name GameplayHUD
extends CanvasLayer

var _health: HealthComponent = null
var _stamina_source: Node = null

@onready var _health_label: Label = $Panel/Margin/Rows/HealthLabel
@onready var _health_bar: ProgressBar = $Panel/Margin/Rows/HealthBar
@onready var _stamina_label: Label = $Panel/Margin/Rows/StaminaLabel
@onready var _stamina_bar: ProgressBar = $Panel/Margin/Rows/StaminaBar


func bind_sources(health: HealthComponent, stamina_source: Node) -> void:
	if is_instance_valid(_health) and _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.disconnect(_on_health_changed)
	if is_instance_valid(_stamina_source) and _stamina_source.is_connected("stamina_changed", _on_stamina_changed):
		_stamina_source.disconnect("stamina_changed", _on_stamina_changed)
	_health = health
	_stamina_source = stamina_source
	if is_instance_valid(_health):
		_health.health_changed.connect(_on_health_changed)
		_on_health_changed(_health.get_health(), _health.max_health)
	if is_instance_valid(_stamina_source):
		_stamina_source.connect("stamina_changed", _on_stamina_changed)
		_on_stamina_changed(float(_stamina_source.call("get_stamina")), float(_stamina_source.call("get_max_stamina")))


func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "VIDA  %d / %d" % [roundi(current), roundi(maximum)]


func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	_stamina_label.text = "STAMINA  %d / %d" % [roundi(current), roundi(maximum)]
