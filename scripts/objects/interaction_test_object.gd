extends Node2D

# ECHOES-018B: placeholder técnico, sem coleta ou inventário.
const INITIAL_COLOR := Color(0.85, 0.62, 0.2, 1.0)
const ALTERNATE_COLOR := Color(0.2, 0.75, 0.55, 1.0)

var interaction_count: int = 0

@onready var _visual: Polygon2D = $Visual


func _on_interacted(actor: Node2D) -> void:
	interaction_count += 1
	_visual.color = ALTERNATE_COLOR if interaction_count % 2 == 1 else INITIAL_COLOR
	print("ECHOES-018B: interação #%d no objeto placeholder por %s." % [interaction_count, actor.name])
