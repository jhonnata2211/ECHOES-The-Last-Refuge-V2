class_name StealthPrototypeThreat
extends CharacterBody2D

## ECHOES-050: entidade técnica temporária, sem ataque, dano ou identidade narrativa.
signal state_changed(state: int)
signal noise_heard(origin: Vector2)
signal navigation_blocked()

enum State { IDLE, INVESTIGATE, SEARCH, RETURN }

@export_range(1.0, 320.0, 1.0) var movement_speed: float = 90.0
@export_range(0.05, 2.0, 0.05) var hearing_sample_interval: float = 0.5
@export_range(0.5, 10.0, 0.1) var search_duration: float = 4.0
@export_range(1.0, 16.0, 0.5) var arrival_distance: float = 4.0
@export_range(1.0, 64.0, 1.0) var retarget_distance: float = 16.0
@export_range(0.5, 5.0, 0.1) var blocked_timeout: float = 2.0

@onready var _listener: NoiseListenerComponent = $NoiseListenerComponent
@onready var _navigator: ThreatGridNavigator = $ThreatGridNavigator
@onready var _label: Label = $Label

var _noise: PlayerNoiseComponent = null
var _state: State = State.IDLE
var _home: Vector2 = Vector2.ZERO
var _destination: Vector2 = Vector2.ZERO
var _last_heard: Vector2 = Vector2.ZERO
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _listen_elapsed: float = 0.0
var _search_elapsed: float = 0.0
var _blocked_elapsed: float = 0.0
var _navigation_failed: bool = false


func _ready() -> void:
	_home = global_position
	_destination = _home
	_update_feedback()


func configure_world(terrain: TileMapLayer, obstacles: TileMapLayer) -> bool:
	return _navigator.configure(terrain, obstacles)


func bind_noise_source(noise: PlayerNoiseComponent) -> void:
	if is_instance_valid(_noise):
		var previous_body: PhysicsBody2D = _noise.get_parent() as PhysicsBody2D
		if previous_body != null:
			remove_collision_exception_with(previous_body)
	_noise = noise
	_listener.bind_source(noise)
	if is_instance_valid(noise):
		# A ameaça não bloqueia nem ataca o emissor; colisão com terreno permanece.
		var source_body: PhysicsBody2D = noise.get_parent() as PhysicsBody2D
		if source_body != null:
			add_collision_exception_with(source_body)


func _physics_process(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	_listen_elapsed += delta
	var interval: float = hearing_sample_interval if is_finite(hearing_sample_interval) else 0.5
	interval = maxf(interval, 0.05)
	if _listen_elapsed >= interval:
		_listen_elapsed = fmod(_listen_elapsed, interval)
		_sample_noise()
	match _state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.INVESTIGATE, State.RETURN:
			_follow_path(delta)
		State.SEARCH:
			velocity = Vector2.ZERO
			_search_elapsed += delta
			var duration: float = search_duration if is_finite(search_duration) else 4.0
			if _search_elapsed >= maxf(duration, 0.5):
				_begin_move(_home, State.RETURN)


func _sample_noise() -> void:
	# Atualizar o listener aprovado antes do snapshot, sem consultar posição inaudível.
	_listener.refresh_perception()
	if not _listener.is_perceiving() or not is_instance_valid(_noise) or _noise.is_queued_for_deletion():
		return
	var heard: Vector2 = _noise.get_noise_origin()
	if not heard.is_finite():
		return
	_last_heard = heard
	noise_heard.emit(heard)
	if _state == State.SEARCH and global_position.distance_to(heard) <= arrival_distance:
		_search_elapsed = 0.0
	elif _state != State.INVESTIGATE or _destination.distance_to(heard) >= maxf(retarget_distance, 1.0):
		_begin_move(heard, State.INVESTIGATE)


func _begin_move(destination: Vector2, next_state: State) -> void:
	_destination = destination
	_path = _navigator.find_path(global_position, destination)
	_path_index = 0
	_blocked_elapsed = 0.0
	_navigation_failed = false
	_set_state(next_state)


func _follow_path(delta: float) -> void:
	while _path_index < _path.size() and global_position.distance_to(_path[_path_index]) <= arrival_distance:
		_path_index += 1
	if _path_index >= _path.size():
		velocity = Vector2.ZERO
		if global_position.distance_to(_destination) <= arrival_distance:
			_arrived()
		else:
			_handle_blocked(delta)
		return
	var difference: Vector2 = _path[_path_index] - global_position
	var speed: float = maxf(movement_speed, 0.0) if is_finite(movement_speed) else 0.0
	velocity = difference.normalized() * minf(speed, difference.length() / delta)
	var previous: Vector2 = global_position
	move_and_slide()
	if global_position.distance_to(previous) <= 0.001:
		_handle_blocked(delta)
	else:
		_blocked_elapsed = 0.0


func _handle_blocked(delta: float) -> void:
	_blocked_elapsed += delta
	var timeout: float = maxf(blocked_timeout, 0.5) if is_finite(blocked_timeout) else 2.0
	if _blocked_elapsed < timeout or _navigation_failed:
		return
	_navigation_failed = true
	velocity = Vector2.ZERO
	navigation_blocked.emit()
	if _state == State.INVESTIGATE:
		# Não atravessar parede/teleportar até um alvo inacessível; buscar aqui.
		_set_state(State.SEARCH)
	else:
		# RETURN sem rota aguarda neste estado. Não fingir que chegou à origem.
		_update_feedback()


func _arrived() -> void:
	if _state == State.INVESTIGATE:
		_set_state(State.SEARCH)
	elif _state == State.RETURN:
		_set_state(State.IDLE)


func _set_state(value: State) -> void:
	if _state == value:
		return
	_state = value
	_search_elapsed = 0.0
	_update_feedback()
	state_changed.emit(int(_state))


func get_state() -> State:
	return _state


func get_destination() -> Vector2:
	return _destination


func get_last_heard_position() -> Vector2:
	return _last_heard


func get_home_position() -> Vector2:
	return _home


func _update_feedback() -> void:
	var names: Array[String] = ["IDLE", "INVESTIGATE", "SEARCH", "RETURN"]
	_label.text = "%s\nPROTÓTIPO" % names[int(_state)]
	if _navigation_failed:
		_label.text += " / SEM ROTA"
	queue_redraw()


func _draw() -> void:
	var colors: Array[Color] = [Color(0.5, 0.55, 0.5), Color(0.9, 0.55, 0.2), Color(0.85, 0.75, 0.3), Color(0.4, 0.65, 0.75)]
	var color: Color = colors[int(_state)]
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -8), Vector2(10, -8), Vector2(14, 0), Vector2(10, 8), Vector2(-10, 8), Vector2(-14, 0)]), color)
	draw_circle(Vector2.ZERO, 17.0, color, false, 1.5)
