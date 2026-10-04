extends Node2D

signal collected(item_id: StringName, display_name: String, quantity: int, actor: Node2D)

@export var item_id: StringName = &"scrap":
	set(value):
		item_id = value
		_refresh_interaction_state()
@export var display_name: String = "Sucata":
	set(value):
		display_name = value
		_refresh_interaction_state()
@export_range(1, 999, 1, "or_greater") var quantity: int = 1:
	set(value):
		quantity = value
		_refresh_interaction_state()

var _collected: bool = false
var _collection_in_progress: bool = false

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_refresh_interaction_state()


func _has_valid_data() -> bool:
	return not String(item_id).strip_edges().is_empty() \
		and not display_name.strip_edges().is_empty() and quantity > 0


func _refresh_interaction_state() -> void:
	if is_instance_valid(_interactable):
		_interactable.enabled = not _collected and not _collection_in_progress and _has_valid_data()


func _on_interacted(actor: Node2D) -> void:
	if _collected or _collection_in_progress or not _has_valid_data() or not _interactable.can_interact(actor):
		_refresh_interaction_state()
		return

	var inventory: Inventory = Inventory.find_on(actor)
	if inventory == null:
		return
	# Desabilitar durante a transação, incluindo callbacks dos sinais do Inventory.
	_collection_in_progress = true
	_interactable.enabled = false
	var collected_id: StringName = item_id
	var collected_name: String = display_name
	var collected_quantity: int = quantity
	if not inventory.add_item(collected_id, collected_name, collected_quantity):
		_collection_in_progress = false
		_refresh_interaction_state()
		return

	_collected = true
	_collection_in_progress = false
	collected.emit(collected_id, collected_name, collected_quantity, actor)
	hide()
	queue_free()
