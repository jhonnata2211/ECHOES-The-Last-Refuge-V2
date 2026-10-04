extends Node

# ECHOES-019B: observador TEMPORÁRIO de teste; não representa um inventário.
var collection_count: int = 0
var last_item_id: StringName = &""
var last_display_name: String = ""
var last_quantity: int = 0


func record_collection(item_id: StringName, display_name: String, quantity: int, actor: Node2D) -> void:
	collection_count += 1
	last_item_id = item_id
	last_display_name = display_name
	last_quantity = quantity
	var actor_name: String = String(actor.name) if is_instance_valid(actor) else "indisponível"
	print("ECHOES-019B: coleta #%d — %s x%d (id=%s), por %s." % [collection_count, display_name, quantity, item_id, actor_name])
