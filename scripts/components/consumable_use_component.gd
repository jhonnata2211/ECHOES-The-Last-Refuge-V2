class_name ConsumableUseComponent
extends Node

signal availability_changed
signal item_used(item_id: StringName)

@export var definitions: Array[ConsumableDefinition] = []

var _inventory: Inventory = null
var _needs: SurvivalNeedsComponent = null
var _catalog: Dictionary = {}
var _using: bool = false


func _ready() -> void:
	for definition in definitions:
		if definition != null and definition.is_valid():
			# IDs duplicados ficam indisponíveis, em vez de escolher um efeito arbitrário.
			_catalog[definition.item_id] = null if _catalog.has(definition.item_id) else definition


func bind_sources(inventory: Inventory, needs: SurvivalNeedsComponent) -> void:
	if is_instance_valid(_inventory) and _inventory.inventory_changed.is_connected(_on_inventory_changed):
		_inventory.inventory_changed.disconnect(_on_inventory_changed)
	if is_instance_valid(_needs):
		if _needs.hunger_changed.is_connected(_on_needs_changed):
			_needs.hunger_changed.disconnect(_on_needs_changed)
		if _needs.thirst_changed.is_connected(_on_needs_changed):
			_needs.thirst_changed.disconnect(_on_needs_changed)
	_inventory = inventory
	_needs = needs
	if is_instance_valid(_inventory):
		_inventory.inventory_changed.connect(_on_inventory_changed)
	if is_instance_valid(_needs):
		_needs.hunger_changed.connect(_on_needs_changed)
		_needs.thirst_changed.connect(_on_needs_changed)
	availability_changed.emit()


func get_definition(item_id: StringName) -> ConsumableDefinition:
	var definition: ConsumableDefinition = _catalog.get(item_id) as ConsumableDefinition
	return definition if definition != null and definition.is_valid() and definition.item_id == item_id else null


func can_use(item_id: StringName) -> bool:
	var definition: ConsumableDefinition = get_definition(item_id)
	return not _using and not is_queued_for_deletion() and definition != null \
		and is_instance_valid(_inventory) and not _inventory.is_queued_for_deletion() \
		and is_instance_valid(_needs) and not _needs.is_queued_for_deletion() \
		and _inventory.has_item(item_id) and _needs.can_restore(definition.hunger_restore, definition.thirst_restore)


func use_item(item_id: StringName) -> bool:
	if not can_use(item_id):
		return false
	var definition: ConsumableDefinition = get_definition(item_id)
	_using = true
	var accepted: bool = _inventory.use_item(item_id, _apply_effect.bind(definition))
	_using = false
	if accepted:
		item_used.emit(item_id)
	availability_changed.emit()
	return accepted


func _apply_effect(definition: ConsumableDefinition) -> bool:
	if not is_instance_valid(_needs) or _needs.is_queued_for_deletion() or not definition.is_valid():
		return false
	return _needs.restore(definition.hunger_restore, definition.thirst_restore)


func _on_inventory_changed() -> void:
	availability_changed.emit()


func _on_needs_changed(_current: float, _maximum: float) -> void:
	availability_changed.emit()
