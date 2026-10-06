class_name SoundExperienceController
extends Node

## AUDIO-001: experiência sonora provisória; os assets podem ser trocados na cena.
signal menu_ready
signal gameplay_transition_ready

enum Phase { IDLE, OPENING, MENU, TRANSITION, GAMEPLAY }

const SILENCE_DB: float = -60.0

@export_group("Assets provisórios / referência")
@export_file("*.mp3") var menu_music_path: String = "res://assets/audio/music/menu_melancholic.mp3"
@export_file("*.mp3") var forest_ambience_path: String = "res://assets/audio/ambience/forest_night.mp3"
@export_file("*.mp3") var radio_signal_path: String = "res://assets/audio/sfx/radio_signal.mp3"

@export_group("Volumes em dB")
@export_range(-40.0, 0.0, 0.5) var music_volume_db: float = -10.0
@export_range(-40.0, 0.0, 0.5) var ambience_volume_db: float = -16.0
@export_range(-50.0, 0.0, 0.5) var interior_ambience_volume_db: float = -30.0
@export_range(-40.0, 0.0, 0.5) var radio_volume_db: float = -16.0

@export_group("Tempos do protótipo em segundos")
@export_range(0.2, 5.0, 0.05) var opening_radio_duration: float = 1.1
@export_range(0.2, 5.0, 0.05) var transition_radio_duration: float = 0.65
@export_range(0.1, 5.0, 0.05) var music_fade_in: float = 1.2
@export_range(0.1, 5.0, 0.05) var music_fade_out: float = 0.8
@export_range(0.1, 5.0, 0.05) var ambience_fade_in: float = 2.0
@export_range(0.1, 5.0, 0.05) var ambience_fade_out: float = 0.8

var phase: Phase = Phase.IDLE
var menu_music: AudioStreamMP3 = null
var forest_ambience: AudioStreamMP3 = null
var radio_signal: AudioStreamMP3 = null
var _available: bool = false
var _music_tween: Tween = null
var _ambience_tween: Tween = null
var _radio_tween: Tween = null

@onready var _music: AudioStreamPlayer = $Music
@onready var _ambience: AudioStreamPlayer = $Ambience
@onready var _radio: AudioStreamPlayer = $Radio


func _ready() -> void:
	# Carregar em runtime evita dependência do cache durante a primeira importação.
	menu_music = load(menu_music_path) as AudioStreamMP3
	forest_ambience = load(forest_ambience_path) as AudioStreamMP3
	radio_signal = load(radio_signal_path) as AudioStreamMP3
	if menu_music == null or forest_ambience == null or radio_signal == null:
		push_error("AUDIO-001: falta um dos três recursos de áudio configurados.")
		return
	# Duplicar recursos evita alterar os MP3 e suas configurações de importação.
	_music.stream = _playback_stream(menu_music, true)
	_ambience.stream = _playback_stream(forest_ambience, true)
	_ambience.volume_db = ambience_volume_db
	_radio.stream = _playback_stream(radio_signal, false)
	_available = true


func _playback_stream(source: AudioStreamMP3, looping: bool) -> AudioStreamMP3:
	var stream: AudioStreamMP3 = source.duplicate() as AudioStreamMP3
	stream.loop = looping
	stream.loop_offset = 0.0
	return stream


func begin_menu() -> void:
	if not _available or phase == Phase.OPENING or phase == Phase.TRANSITION:
		return
	if phase == Phase.MENU:
		menu_ready.emit()
		return
	_stop_channels()
	phase = Phase.OPENING
	_play_radio(opening_radio_duration, _enter_menu)


func _enter_menu() -> void:
	phase = Phase.MENU
	_music.volume_db = SILENCE_DB
	_music.play()
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", music_volume_db, music_fade_in)
	menu_ready.emit()


func request_gameplay_transition() -> bool:
	if not _available or phase != Phase.MENU:
		return false
	phase = Phase.TRANSITION
	_kill_tween(_music_tween)
	_music_tween = create_tween()
	_music_tween.tween_property(_music, "volume_db", SILENCE_DB, music_fade_out)
	_music_tween.tween_callback(_begin_transition_radio)
	return true


func _begin_transition_radio() -> void:
	_music.stop()
	_play_radio(transition_radio_duration, _finish_transition)


func _finish_transition() -> void:
	# A cena de gameplay confirma sua entrada chamando start_forest().
	phase = Phase.IDLE
	gameplay_transition_ready.emit()


func start_forest() -> void:
	if not _available:
		return
	if phase != Phase.GAMEPLAY:
		_stop_channels()
		phase = Phase.GAMEPLAY
	# Exterior é o padrão de gameplay, sem depender de um fade saindo de -60 dB.
	_kill_tween(_ambience_tween)
	_ambience_tween = null
	_ambience.volume_db = ambience_volume_db
	_ambience.stream_paused = false
	if not _ambience.playing:
		_ambience.play()


func set_forest_interior(inside: bool) -> void:
	if not _available or phase != Phase.GAMEPLAY:
		return
	var target_db: float = interior_ambience_volume_db if inside else ambience_volume_db
	var duration: float = ambience_fade_out if inside else ambience_fade_in
	# Destinos absolutos; substituir o fade anterior evita reduções acumuladas.
	_kill_tween(_ambience_tween)
	_ambience.stream_paused = false
	if not _ambience.playing:
		_ambience.play()
	_ambience_tween = create_tween()
	_ambience_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_ambience_tween.tween_property(_ambience, "volume_db", target_db, duration)


func _play_radio(requested_duration: float, completed: Callable) -> void:
	var duration: float = minf(maxf(requested_duration, 0.2), _radio.stream.get_length())
	var fade_in: float = minf(0.08, duration * 0.2)
	var fade_out: float = minf(0.12, duration * 0.2)
	_radio.volume_db = SILENCE_DB
	_radio.play()
	_radio_tween = create_tween()
	_radio_tween.tween_property(_radio, "volume_db", radio_volume_db, fade_in)
	_radio_tween.tween_interval(maxf(0.0, duration - fade_in - fade_out))
	_radio_tween.tween_property(_radio, "volume_db", SILENCE_DB, fade_out)
	_radio_tween.tween_callback(_finish_radio.bind(completed))


func _finish_radio(completed: Callable) -> void:
	_radio.stop()
	if completed.is_valid():
		completed.call()


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()


func _stop_channels() -> void:
	_kill_tween(_music_tween)
	_kill_tween(_ambience_tween)
	_kill_tween(_radio_tween)
	_music.stop()
	_ambience.stop()
	_radio.stop()


func _exit_tree() -> void:
	_stop_channels()
