class_name GameplayHUD
extends CanvasLayer

var _health: HealthComponent = null
var _stamina_source: Node = null
var _needs: SurvivalNeedsComponent = null

@onready var _health_label: Label = $Panel/Margin/Rows/HealthLabel
@onready var _health_bar: ProgressBar = $Panel/Margin/Rows/HealthBar
@onready var _stamina_label: Label = $Panel/Margin/Rows/StaminaLabel
@onready var _stamina_bar: ProgressBar = $Panel/Margin/Rows/StaminaBar
@onready var _hunger_label: Label = $Panel/Margin/Rows/HungerLabel
@onready var _hunger_bar: ProgressBar = $Panel/Margin/Rows/HungerBar
@onready var _thirst_label: Label = $Panel/Margin/Rows/ThirstLabel
@onready var _thirst_bar: ProgressBar = $Panel/Margin/Rows/ThirstBar


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


func bind_survival(needs: SurvivalNeedsComponent) -> void:
	if is_instance_valid(_needs):
		if _needs.hunger_changed.is_connected(_on_hunger_changed):
			_needs.hunger_changed.disconnect(_on_hunger_changed)
		if _needs.thirst_changed.is_connected(_on_thirst_changed):
			_needs.thirst_changed.disconnect(_on_thirst_changed)
	_needs = needs
	if is_instance_valid(_needs):
		_needs.hunger_changed.connect(_on_hunger_changed)
		_needs.thirst_changed.connect(_on_thirst_changed)
		_on_hunger_changed(_needs.get_hunger(), _needs.get_max_hunger())
		_on_thirst_changed(_needs.get_thirst(), _needs.get_max_thirst())


func _on_hunger_changed(current: float, maximum: float) -> void:
	_hunger_bar.max_value = maximum
	_hunger_bar.value = current
	_hunger_label.text = "FOME  %d / %d" % [roundi(current), roundi(maximum)]


func _on_thirst_changed(current: float, maximum: float) -> void:
	_thirst_bar.max_value = maximum
	_thirst_bar.value = current
	_thirst_label.text = "SEDE  %d / %d" % [roundi(current), roundi(maximum)]
