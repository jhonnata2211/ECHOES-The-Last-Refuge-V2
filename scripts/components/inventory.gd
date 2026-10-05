class_name Inventory
extends Node

signal inventory_changed()
signal item_quantity_changed(item_id: StringName, quantity: int)

var _items: Dictionary = {}
var _use_in_progress: bool = false


static func find_on(actor: Node) -> Inventory:
	if not is_instance_valid(actor):
		return null
	for component in actor.get_children():
		if component is Inventory and not component.is_queued_for_deletion():
			return component
	return null


func add_item(item_id: StringName, display_name: String, quantity: int) -> bool:
	if _use_in_progress:
		return false
	if String(item_id).strip_edges().is_empty() or display_name.strip_edges().is_empty() or quantity <= 0:
		return false
	var previous: int = get_quantity(item_id)
	# Rejeitar overflow antes de alterar armazenamento ou emitir sinais.
	if previous > 9223372036854775807 - quantity:
		return false
	var stored_name: String = _items[item_id]["display_name"] if _items.has(item_id) else display_name
	_items[item_id] = {"display_name": stored_name, "quantity": previous + quantity}
	item_quantity_changed.emit(item_id, previous + quantity)
	inventory_changed.emit()
	return true


func get_quantity(item_id: StringName) -> int:
	return int(_items[item_id]["quantity"]) if _items.has(item_id) else 0


func has_item(item_id: StringName, quantity: int = 1) -> bool:
	return quantity > 0 and get_quantity(item_id) >= quantity


func remove_item(item_id: StringName, quantity: int = 1) -> bool:
	if _use_in_progress:
		return false
	if not has_item(item_id, quantity):
		return false
	var remaining: int = get_quantity(item_id) - quantity
	if remaining == 0:
		_items.erase(item_id)
	else:
		_items[item_id]["quantity"] = remaining
	item_quantity_changed.emit(item_id, remaining)
	inventory_changed.emit()
	return true


func use_item(item_id: StringName, apply_effect: Callable) -> bool:
	if _use_in_progress or is_queued_for_deletion() or not has_item(item_id) or not apply_effect.is_valid():
		return false
	# Proteger a pilha contra reentrada durante os sinais emitidos pelo efeito.
	_use_in_progress = true
	var applied: Variant = apply_effect.call()
	if not applied is bool or not bool(applied):
		_use_in_progress = false
		return false
	var remaining: int = get_quantity(item_id) - 1
	if remaining == 0:
		_items.erase(item_id)
	else:
		_items[item_id]["quantity"] = remaining
	item_quantity_changed.emit(item_id, remaining)
	inventory_changed.emit()
	_use_in_progress = false
	return true


func get_items() -> Array[Dictionary]:
	# Retornar cópias em ordem estável; a UI não recebe acesso ao armazenamento.
	var ids: Array = _items.keys()
	ids.sort()
	var result: Array[Dictionary] = []
	for item_id in ids:
		result.append({"item_id": item_id, "display_name": _items[item_id]["display_name"], "quantity": _items[item_id]["quantity"]})
	return result
