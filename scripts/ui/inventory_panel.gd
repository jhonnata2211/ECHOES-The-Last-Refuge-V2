class_name InventoryPanel
extends CanvasLayer

signal open_changed(opened: bool)

var _inventory: Inventory = null
var _consumer: ConsumableUseComponent = null
var _opened: bool = false
var _selected_item: StringName = &""
var _item_buttons: Array[Button] = []

@onready var _open_button: Button = $OpenButton
@onready var _overlay: Control = $Overlay
@onready var _scroll: ScrollContainer = $Overlay/Panel/Margin/Rows/Scroll
@onready var _items_box: VBoxContainer = $Overlay/Panel/Margin/Rows/Scroll/Items
@onready var _selection_label: Label = $Overlay/Panel/Margin/Rows/Selection/Selected
@onready var _use_button: Button = $Overlay/Panel/Margin/Rows/Selection/UseButton


func _ready() -> void:
	_open_button.pressed.connect(toggle)
	$Overlay/Panel/Margin/Rows/Header/CloseButton.pressed.connect(close)
	_scroll.connect("item_tapped", _on_item_tapped)
	_use_button.pressed.connect(_use_selected_item)
	_update_selection()
	_overlay.hide()


func bind_inventory(inventory: Inventory) -> void:
	if is_instance_valid(_inventory) and _inventory.inventory_changed.is_connected(_refresh_items):
		_inventory.inventory_changed.disconnect(_refresh_items)
	_inventory = inventory
	if is_instance_valid(_inventory):
		_inventory.inventory_changed.connect(_refresh_items)
	_refresh_items()


func bind_consumer(consumer: ConsumableUseComponent) -> void:
	if is_instance_valid(_consumer) and _consumer.availability_changed.is_connected(_update_selection):
		_consumer.availability_changed.disconnect(_update_selection)
	_consumer = consumer
	if is_instance_valid(_consumer):
		_consumer.availability_changed.connect(_update_selection)
	_update_selection()


func get_selected_item() -> StringName:
	return _selected_item


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
	for child in _items_box.get_children():
		_items_box.remove_child(child)
		child.queue_free()
	_item_buttons.clear()
	if is_instance_valid(_inventory):
		for item in _inventory.get_items():
			var button: Button = Button.new()
			var item_id: StringName = item["item_id"]
			button.text = "%s x%d" % [item["display_name"], item["quantity"]]
			button.custom_minimum_size.y = 56.0
			button.add_theme_font_size_override("font_size", 24)
			button.toggle_mode = true
			button.set_meta("item_id", item_id)
			button.pressed.connect(_select_item.bind(item_id))
			_items_box.add_child(button)
			_item_buttons.append(button)
		if not _inventory.has_item(_selected_item):
			_selected_item = &""
	if _item_buttons.is_empty():
		var empty: Label = Label.new()
		empty.text = "Inventário vazio."
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		empty.add_theme_font_size_override("font_size", 24)
		_items_box.add_child(empty)
	_update_selection()


func _select_item(item_id: StringName) -> void:
	if not _opened or not is_instance_valid(_inventory) or not _inventory.has_item(item_id):
		return
	if item_id != _selected_item:
		# A mudança de seleção cancela um USAR que ainda esteja sendo segurado.
		_use_button.hide()
	_selected_item = item_id
	_update_selection()


func _on_item_tapped(local_position: Vector2) -> void:
	var canvas_position: Vector2 = _scroll.get_global_transform_with_canvas() * local_position
	for button in _item_buttons:
		var local: Vector2 = button.get_global_transform_with_canvas().affine_inverse() * canvas_position
		if Rect2(Vector2.ZERO, button.size).has_point(local):
			_select_item(button.get_meta("item_id"))
			return


func _update_selection() -> void:
	_selection_label.text = "Selecione um item."
	for button in _item_buttons:
		var selected: bool = button.get_meta("item_id") == _selected_item
		button.set_pressed_no_signal(selected)
		if selected:
			_selection_label.text = button.text
	var definition: ConsumableDefinition = _consumer.get_definition(_selected_item) if is_instance_valid(_consumer) else null
	var unavailable: bool = not is_instance_valid(_consumer) or not _consumer.can_use(_selected_item)
	if unavailable and not _use_button.disabled:
		# A ocultação cancela a posse do dedo pelo botão existente, antes de desabilitar.
		_use_button.hide()
	_use_button.visible = definition != null
	_use_button.disabled = unavailable


func _use_selected_item() -> void:
	if _opened and is_instance_valid(_consumer):
		_consumer.use_item(_selected_item)
