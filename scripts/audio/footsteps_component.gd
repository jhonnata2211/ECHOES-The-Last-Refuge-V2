class_name FootstepsComponent
extends Node

## PATCH FOOTSTEPS: trechos por deslocamento real, com início audível e corte seguro.
signal step_played(surface_id: StringName, crouched: bool, sprinting: bool)

@export var surfaces: Array[FootstepSurface] = []
@export var initial_surface: StringName = &"grass"
@export_group("Distância entre passos / px")
@export_range(8.0, 160.0, 1.0) var crouch_stride: float = 66.0
@export_range(8.0, 160.0, 1.0) var walk_stride: float = 80.0
@export_range(8.0, 160.0, 1.0) var sprint_stride: float = 88.0
@export_group("Volumes / dB")
@export_range(-60.0, 0.0, 0.5) var crouch_volume_db: float = -18.0
@export_range(-60.0, 0.0, 0.5) var walk_volume_db: float = -8.0
@export_range(-60.0, 0.0, 0.5) var sprint_volume_db: float = -3.0
@export_group("Envelope / segundos")
@export_range(0.005, 0.08, 0.001) var fade_out: float = 0.025

const SILENCE_DB: float = -60.0
var _catalog: Dictionary = {}
var _surface: FootstepSurface = null
var _distance: float = 0.0
var _segment_index: int = 0
var _next_start: float = 0.0
var _start: float = 0.0
var _elapsed: float = 0.0
var _duration: float = 0.0
var _target_db: float = -8.0
var _player: AudioStreamPlayer = null


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "StepAudio"
	_player.autoplay = false
	_player.bus = &"Master"
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_player)
	_player.finished.connect(_on_stream_finished)
	for surface in surfaces:
		if surface != null and surface.is_valid():
			_catalog[surface.surface_id] = null if _catalog.has(surface.surface_id) else surface
	set_surface(initial_surface)


func set_surface(surface_id: StringName) -> bool:
	var candidate: FootstepSurface = _catalog.get(surface_id) as FootstepSurface
	if candidate == null or not candidate.is_valid():
		return false
	if candidate == _surface:
		return true
	# Referência direta garante a dependência de import/export; path é fallback.
	var source: AudioStreamMP3 = candidate.source_stream
	if source == null:
		if not ResourceLoader.exists(candidate.stream_path):
			push_warning("ECHOES-040: fonte de passos ausente: %s" % candidate.stream_path)
			return false
		source = load(candidate.stream_path) as AudioStreamMP3
	if source == null:
		push_warning("ECHOES-040: recurso configurado não carregou como AudioStreamMP3.")
		return false
	# O loop é desligado somente na cópia em memória; import e MP3 intactos.
	var playback: AudioStreamMP3 = source.duplicate() as AudioStreamMP3
	playback.loop = false
	playback.loop_offset = 0.0
	reset_steps()
	_surface = candidate
	_player.stream = playback
	_player.stream_paused = false
	_segment_index = 0
	_next_start = 0.0
	return true


func update_motion(displacement: Vector2, delta: float, crouched: bool, sprinting: bool) -> void:
	if not displacement.is_finite() or not is_finite(delta) or delta <= 0.0 or displacement.length() <= 0.001:
		reset_steps()
		return
	if _surface == null or _player == null or _player.stream == null:
		return
	var stride: float = crouch_stride if crouched else (sprint_stride if sprinting else walk_stride)
	if not is_finite(stride) or stride <= 0.0:
		return
	_distance += displacement.length()
	if _distance >= stride:
		_distance = fmod(_distance, stride)
		# Um evento por frame; não gerar uma rajada após deslocamento grande.
		var speed: float = displacement.length() / delta
		_play_step(crouched, sprinting, stride / speed)


func _play_step(crouched: bool, sprinting: bool, step_interval: float) -> void:
	if not _surface.is_valid():
		return
	var length: float = _player.stream.get_length()
	var known_length: bool = is_finite(length) and length > 0.0
	var start: float = 0.0
	if _surface.contiguous_segments:
		start = _next_start
	else:
		start = float(_surface.segment_starts[_segment_index % _surface.segment_starts.size()])
		_segment_index += 1
	if start < 0.0 or not is_finite(start):
		return
	if known_length and start >= length:
		start = 0.0
	# Limitar a janela a 85% do intervalo calculado entre passos.
	_duration = minf(_surface.segment_duration, step_interval * 0.85)
	if known_length:
		_duration = minf(_duration, length - start)
	_start = start
	_next_start = fmod(start + _duration, length) if known_length else start + _duration
	_elapsed = 0.0
	var volume: float = crouch_volume_db if crouched else (sprint_volume_db if sprinting else walk_volume_db)
	_target_db = clampf(volume, -60.0, 0.0) if is_finite(volume) else -8.0
	_player.stream_paused = false
	# Não iniciar uma janela curta em silêncio: Android pode atrasar o primeiro mix.
	_player.volume_db = _target_db
	_player.play(start)
	step_played.emit(_surface.surface_id, crouched, sprinting)


func _process(delta: float) -> void:
	if _player == null or not _player.playing:
		return
	_elapsed += delta
	var position: float = _player.get_playback_position()
	var played: float = maxf(position - _start, 0.0)
	# Usar o relógio do áudio, não gastar a janela antes de o decoder avançar.
	# Watchdog evita um stream preso caso o backend não informe progresso.
	if played >= _duration or _elapsed >= _duration + 0.5:
		_player.stop()
		return
	var release: float = maxf(fade_out, 0.001) if is_finite(fade_out) else 0.025
	var envelope: float = clampf((_duration - played) / release, 0.0, 1.0)
	_player.volume_db = lerpf(SILENCE_DB, _target_db, envelope)


func _on_stream_finished() -> void:
	# EOF natural, inclusive se o decoder não informou duração nos metadados.
	_next_start = 0.0
	_elapsed = 0.0
	_duration = 0.0


func reset_steps() -> void:
	_distance = 0.0
	_elapsed = 0.0
	_duration = 0.0
	if is_instance_valid(_player):
		_player.stop()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT or what == MainLoop.NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_EXIT_TREE:
		reset_steps()
