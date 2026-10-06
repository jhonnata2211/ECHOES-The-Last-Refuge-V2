class_name InventorySoundFeedback
extends Node

## ECHOES-055–060: feedback provisório; não controla inventário ou sobrevivência.
signal feedback_played(kind: StringName)

@export var zipper_stream: AudioStream = null
@export var selection_stream: AudioStream = null
@export_range(-40.0, 0.0, 0.5) var zipper_volume_db: float = -12.0
@export_range(-40.0, 0.0, 0.5) var selection_volume_db: float = -12.0
@export var use_sounds: Array[ItemUseSound] = []

@onready var _inventory_audio: AudioStreamPlayer = $InventoryAudio
@onready var _selection_audio: AudioStreamPlayer = $SelectionAudio
@onready var _consumption_audio: AudioStreamPlayer = $ConsumptionAudio

var _panel: InventoryPanel = null
var _consumer: ConsumableUseComponent = null
var _zipper: AudioStream = null
var _selection: AudioStream = null
var _catalog: Dictionary = {}
var _use_streams: Dictionary = {}


func _ready() -> void:
	_zipper = _prepare_stream(zipper_stream)
	_selection = _prepare_stream(selection_stream)
	for definition in use_sounds:
		if definition == null or not definition.is_valid():
			continue
		if _catalog.has(definition.item_id):
			# Associação ambígua não deve tocar um som arbitrário.
			_catalog[definition.item_id] = null
			_use_streams.erase(definition.item_id)
		else:
			_catalog[definition.item_id] = definition
			_use_streams[definition.item_id] = _prepare_stream(definition.stream)


func bind_sources(panel: InventoryPanel, consumer: ConsumableUseComponent) -> void:
	if is_instance_valid(_panel):
		if _panel.open_changed.is_connected(_on_open_changed):
			_panel.open_changed.disconnect(_on_open_changed)
		if _panel.item_selected_by_user.is_connected(_on_item_selected):
			_panel.item_selected_by_user.disconnect(_on_item_selected)
	if is_instance_valid(_consumer) and _consumer.item_used.is_connected(_on_item_used):
		_consumer.item_used.disconnect(_on_item_used)
	_panel = panel
	_consumer = consumer
	if is_instance_valid(_panel):
		_panel.open_changed.connect(_on_open_changed)
		_panel.item_selected_by_user.connect(_on_item_selected)
	if is_instance_valid(_consumer):
		# Este sinal já ocorre depois da aplicação do efeito e remoção da unidade.
		_consumer.item_used.connect(_on_item_used)


func _on_open_changed(opened: bool) -> void:
	_play(_inventory_audio, _zipper, zipper_volume_db, &"inventory_open" if opened else &"inventory_close")


func _on_item_selected(_item_id: StringName) -> void:
	_play(_selection_audio, _selection, selection_volume_db, &"item_select")


func _on_item_used(item_id: StringName) -> void:
	var definition: ItemUseSound = _catalog.get(item_id) as ItemUseSound
	if definition != null and definition.is_valid():
		var stream: AudioStream = _use_streams.get(item_id) as AudioStream
		_play(_consumption_audio, stream, definition.volume_db, item_id)


func _prepare_stream(source: AudioStream) -> AudioStream:
	if source == null:
		return null
	var copy: AudioStream = source.duplicate() as AudioStream
	# Não alterar o MP3/import compartilhado; SFX são one-shots em cópias locais.
	if copy is AudioStreamMP3:
		copy.loop = false
	return copy


func _play(player: AudioStreamPlayer, stream: AudioStream, volume: float, kind: StringName) -> void:
	if stream == null or not is_finite(volume):
		return
	player.stream = stream
	player.volume_db = clampf(volume, -60.0, 6.0)
	player.stream_paused = false
	player.play()
	feedback_played.emit(kind)
