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

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_refresh_interaction_state()


func _has_valid_data() -> bool:
	return not String(item_id).strip_edges().is_empty() \
		and not display_name.strip_edges().is_empty() and quantity > 0


func _refresh_interaction_state() -> void:
	if is_instance_valid(_interactable):
		_interactable.enabled = not _collected and _has_valid_data()


func _on_interacted(actor: Node2D) -> void:
	if _collected or not _has_valid_data() or not _interactable.can_interact(actor):
		_refresh_interaction_state()
		return

	_collected = true
	_interactable.enabled = false
	collected.emit(item_id, display_name, quantity, actor)
	hide()
	queue_free()
