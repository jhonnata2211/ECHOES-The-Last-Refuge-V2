class_name InteractionDetector
extends Area2D

signal target_changed(target: Interactable)

const INTERACTION_RANGE: float = 48.0
const MIN_ALIGNMENT: float = 0.5 # cos(60°): cone frontal de ±60°.
const OBSTACLE_MASK: int = 1

var _target: Interactable
var _interaction_requested: bool = false


func request_interaction() -> void:
	_interaction_requested = true


func get_current_target() -> Interactable:
	return _target if is_instance_valid(_target) and not _target.is_queued_for_deletion() else null


func process_interaction(actor: Node2D, facing: Vector2) -> void:
	# Chamado pelo Player após movimento/facing, dentro da atualização física.
	var requested := _interaction_requested
	_interaction_requested = false
	_set_target(_select_target(actor, facing))
	if requested and _is_candidate_valid(_target, actor, facing):
		_target.interact(actor)
		_set_target(_select_target(actor, facing))


func _select_target(actor: Node2D, facing: Vector2) -> Interactable:
	var best: Interactable = null
	var best_distance: float = INF
	var best_alignment: float = -INF
	for area in get_overlapping_areas():
		var candidate := area as Interactable
		if not _is_candidate_valid(candidate, actor, facing):
			continue
		var offset := candidate.get_interaction_position() - actor.global_position
		var distance := offset.length_squared()
		var alignment := _alignment(offset, facing)
		var replace := best == null
		if best != null:
			if not is_equal_approx(distance, best_distance):
				replace = distance < best_distance
			elif not is_equal_approx(alignment, best_alignment):
				replace = alignment > best_alignment
			else:
				replace = String(candidate.get_path()) < String(best.get_path())
		if replace:
			best = candidate
			best_distance = distance
			best_alignment = alignment
	return best


func _is_candidate_valid(candidate: Interactable, actor: Node2D, facing: Vector2) -> bool:
	if not is_instance_valid(candidate) or not is_instance_valid(actor):
		return false
	if not candidate.monitorable or facing.is_zero_approx() or not candidate.can_interact(actor):
		return false
	var point := candidate.get_interaction_position()
	var offset := point - actor.global_position
	if offset.length_squared() > INTERACTION_RANGE * INTERACTION_RANGE + 0.001:
		return false
	if _alignment(offset, facing) < MIN_ALIGNMENT - 0.00001:
		return false
	var query := PhysicsRayQueryParameters2D.create(actor.global_position, point, OBSTACLE_MASK)
	query.collide_with_areas = false
	query.hit_from_inside = true
	if actor is CollisionObject2D:
		query.exclude = [(actor as CollisionObject2D).get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or (is_instance_valid(candidate.interaction_body) and hit.get("collider") == candidate.interaction_body)


func _alignment(offset: Vector2, facing: Vector2) -> float:
	return 1.0 if offset.is_zero_approx() else offset.normalized().dot(facing.normalized())


func _set_target(next: Interactable) -> void:
	if _target == next:
		return
	_target = next
	target_changed.emit(_target)
