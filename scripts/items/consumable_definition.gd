class_name ConsumableDefinition
extends Resource

@export var item_id: StringName = &""
@export var display_name: String = ""
@export_range(0.0, 100.0, 0.1) var hunger_restore: float = 0.0
@export_range(0.0, 100.0, 0.1) var thirst_restore: float = 0.0


func is_valid() -> bool:
	return not String(item_id).strip_edges().is_empty() and not display_name.strip_edges().is_empty() \
		and is_finite(hunger_restore) and is_finite(thirst_restore) \
		and hunger_restore >= 0.0 and thirst_restore >= 0.0 \
		and (hunger_restore > 0.0 or thirst_restore > 0.0)
