class_name ScenePortal
extends Node2D

## SPRINT 05: porta contextual reutiliza o contrato aprovado de Interactable.
signal transition_requested(destination: StringName, actor: Node2D)

@export var destination: StringName = &""
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.enabled = not String(destination).strip_edges().is_empty()


func _on_interacted(actor: Node2D) -> void:
	if _interactable.can_interact(actor) and not String(destination).strip_edges().is_empty():
		transition_requested.emit(destination, actor)
