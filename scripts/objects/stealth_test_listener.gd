extends Node2D

## ECHOES-043/044: instrumentação visual placeholder; não é inimigo/personagem.
@onready var _listener: NoiseListenerComponent = $NoiseListenerComponent
@onready var _label: Label = $Label
var _perceived: bool = false


func _ready() -> void:
	_listener.perception_changed.connect(_on_perception_changed)
	_on_perception_changed(_listener.is_perceiving())


func _draw() -> void:
	var color: Color = Color(0.85, 0.40, 0.25, 0.8) if _perceived else Color(0.35, 0.60, 0.55, 0.7)
	draw_circle(Vector2.ZERO, 14.0, color)
	draw_circle(Vector2.ZERO, 24.0, color, false, 2.0)
	# Feedback local discreto; não cobre o mundo com um círculo de alcance.
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color(0.9, 0.95, 0.9), 2.0)
	draw_line(Vector2(0, -6), Vector2(0, 6), Color(0.9, 0.95, 0.9), 2.0)


func _on_perception_changed(perceived: bool) -> void:
	_perceived = perceived
	_label.text = "TESTE DE RUÍDO\nPERCEBIDO" if _perceived else "TESTE DE RUÍDO\nNEUTRO"
	_label.modulate = Color(1.0, 0.6, 0.4) if _perceived else Color(0.8, 0.9, 0.85)
	queue_redraw()
