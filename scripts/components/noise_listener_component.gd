class_name NoiseListenerComponent
extends Node2D

## ECHOES-042: um emissor vinculado; sem visão, navegação, ataque ou memória.
signal perception_changed(perceived: bool)

@export_range(1.0, 2048.0, 1.0) var hearing_radius: float = 320.0
@export_range(0.001, 1.0, 0.001) var detection_threshold: float = 0.20

var _source: PlayerNoiseComponent = null
var _perceived: bool = false
var _effective_noise: float = 0.0


func bind_source(source: PlayerNoiseComponent) -> void:
	if is_instance_valid(_source) and _source.tree_exiting.is_connected(_on_source_exiting):
		_source.tree_exiting.disconnect(_on_source_exiting)
	_source = source
	if is_instance_valid(_source):
		_source.tree_exiting.connect(_on_source_exiting, CONNECT_ONE_SHOT)
	refresh_perception()


func _physics_process(_delta: float) -> void:
	# A distância muda mesmo quando a intensidade não muda. UI usa apenas sinal.
	refresh_perception()


func refresh_perception() -> void:
	_effective_noise = 0.0
	if is_instance_valid(_source) and not _source.is_queued_for_deletion() and _source.has_relevant_noise():
		_effective_noise = evaluate_noise(_source.get_noise_level(), _source.get_noise_origin())
	var threshold: float = clampf(detection_threshold, 0.001, 1.0) if is_finite(detection_threshold) else 0.20
	_set_perceived(_effective_noise >= threshold)


func evaluate_noise(level: float, origin: Vector2) -> float:
	if not is_finite(level) or not origin.is_finite() or not is_finite(hearing_radius) or hearing_radius <= 0.0:
		return 0.0
	var attenuation: float = clampf(1.0 - global_position.distance_to(origin) / hearing_radius, 0.0, 1.0)
	return clampf(level, 0.0, 1.0) * attenuation


func is_perceiving() -> bool:
	return _perceived


func get_effective_noise() -> float:
	return _effective_noise


func _set_perceived(value: bool) -> void:
	if value == _perceived:
		return
	_perceived = value
	perception_changed.emit(_perceived)


func _on_source_exiting() -> void:
	_source = null
	_effective_noise = 0.0
	_set_perceived(false)
