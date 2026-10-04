class_name Interactable
extends Area2D

signal interacted(actor: Node2D)

# Componente reutilizável; o objeto proprietário define o efeito da interação.
@export var enabled: bool = true
@export var interaction_prompt: String = "Interagir"
@export var interaction_body: CollisionObject2D


func can_interact(actor: Node2D) -> bool:
	return enabled and is_instance_valid(actor) and not actor.is_queued_for_deletion() \
		and is_visible_in_tree() and not is_queued_for_deletion()


func interact(actor: Node2D) -> void:
	if can_interact(actor):
		interacted.emit(actor)


func get_interaction_position() -> Vector2:
	return global_position
