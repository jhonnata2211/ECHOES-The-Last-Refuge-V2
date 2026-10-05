class_name FootstepSurface
extends Resource

## ECHOES-040: fonte provisória e janelas curtas, sem converter o áudio original.
@export var surface_id: StringName = &"grass"
@export_file("*.mp3") var stream_path: String = ""
@export var source_stream: AudioStreamMP3 = null
@export var contiguous_segments: bool = false
@export var segment_starts: PackedFloat32Array = PackedFloat32Array([0.25, 0.85, 1.45, 2.05])
@export_range(0.06, 0.6, 0.01) var segment_duration: float = 0.35


func is_valid() -> bool:
	if String(surface_id).is_empty() or (source_stream == null and stream_path.is_empty()) or (not contiguous_segments and segment_starts.is_empty()) or not is_finite(segment_duration) or segment_duration <= 0.0:
		return false
	for start in segment_starts:
		if not is_finite(start) or start < 0.0:
			return false
	return true
