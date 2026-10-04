class_name InventoryPanel
extends CanvasLayer

signal open_changed(opened: bool)

var _inventory: Inventory = null
var _opened: bool = false

@onready var _open_button: Button = $OpenButton
@onready var _overlay: Control = $Overlay
@onready var _items_label: Label = $Overlay/Panel/Margin/Rows/Scroll/Items


func _ready() -> void:
	_open_button.pressed.connect(toggle)
	$Overlay/Panel/Margin/Rows/Header/CloseButton.pressed.connect(close)
	_overlay.hide()


func bind_inventory(inventory: Inventory) -> void:
	if is_instance_valid(_inventory) and _inventory.inventory_changed.is_connected(_refresh_items):
		_inventory.inventory_changed.disconnect(_refresh_items)
	_inventory = inventory
	if is_instance_valid(_inventory):
		_inventory.inventory_changed.connect(_refresh_items)
	_refresh_items()


func is_open() -> bool:
	return _opened


func toggle() -> void:
	_set_open(not _opened)


func close() -> void:
	_set_open(false)


func _set_open(value: bool) -> void:
	if _opened == value:
		return
	_opened = value
	_overlay.visible = value
	_open_button.visible = not value
	if value:
		_refresh_items()
	open_changed.emit(value)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and not event.echo:
		if event.is_action_pressed("inventory"):
			toggle()
			get_viewport().set_input_as_handled()
		elif _opened and event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()


func _refresh_items() -> void:
	var rows: PackedStringArray = []
	if is_instance_valid(_inventory):
		for item in _inventory.get_items():
			rows.append("%s x%d" % [item["display_name"], item["quantity"]])
	_items_label.text = "\n".join(rows) if not rows.is_empty() else "Inventário vazio."
