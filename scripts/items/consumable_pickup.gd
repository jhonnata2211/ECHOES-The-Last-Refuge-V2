extends "res://scripts/items/collectible_item.gd"

@export var definition: ConsumableDefinition


func _ready() -> void:
	if definition != null and definition.is_valid():
		item_id = definition.item_id
		display_name = definition.display_name
	else:
		item_id = &""
		display_name = ""
	super._ready()


func _has_valid_data() -> bool:
	return definition != null and definition.is_valid() and item_id == definition.item_id \
		and display_name == definition.display_name and super._has_valid_data()
