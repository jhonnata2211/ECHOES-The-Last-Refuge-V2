class_name ItemUseSound
extends Resource

## ECHOES-060: associação configurável entre item e feedback de uso confirmado.
@export var item_id: StringName = &""
@export var stream: AudioStream = null
@export_range(-40.0, 0.0, 0.5) var volume_db: float = -10.0


func is_valid() -> bool:
	return not String(item_id).strip_edges().is_empty() and stream != null and is_finite(volume_db)
