class_name ThreatGridNavigator
extends Node

## ECHOES-052: grade estática do mundo existente; sem bake ou alteração dos tiles.
var _terrain: TileMapLayer = null
var _grid: AStarGrid2D = null


func configure(terrain: TileMapLayer, obstacles: TileMapLayer) -> bool:
	_terrain = null
	_grid = null
	if not is_instance_valid(terrain) or not is_instance_valid(obstacles) or terrain.tile_set == null:
		return false
	var region: Rect2i = terrain.get_used_rect()
	if region.size.x <= 0 or region.size.y <= 0:
		return false
	_terrain = terrain
	_grid = AStarGrid2D.new()
	_grid.region = region
	_grid.cell_size = Vector2(terrain.tile_set.tile_size)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_grid.update()
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if terrain.get_cell_source_id(cell) == -1:
				_grid.set_point_solid(cell, true)
	# Obstacles é a camada sólida da base; bloquear a célula inteira é conservador.
	for obstacle_cell in obstacles.get_used_cells():
		var world_point: Vector2 = obstacles.to_global(obstacles.map_to_local(obstacle_cell))
		var cell: Vector2i = terrain.local_to_map(terrain.to_local(world_point))
		if region.has_point(cell):
			_grid.set_point_solid(cell, true)
	return true


func find_path(from_position: Vector2, destination: Vector2) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if _grid == null or not is_instance_valid(_terrain) or not from_position.is_finite() or not destination.is_finite():
		return result
	var start: Vector2i = _terrain.local_to_map(_terrain.to_local(from_position))
	var goal: Vector2i = _terrain.local_to_map(_terrain.to_local(destination))
	if not _grid.region.has_point(start) or not _grid.region.has_point(goal):
		return result
	if _grid.is_point_solid(start) or _grid.is_point_solid(goal):
		return result
	var cells: Array[Vector2i] = _grid.get_id_path(start, goal)
	for cell in cells:
		result.append(_terrain.to_global(_terrain.map_to_local(cell)))
	if not result.is_empty():
		result.append(destination)
	return result
