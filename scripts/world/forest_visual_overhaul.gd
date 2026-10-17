extends Node2D

## ECHOES-067: somente apresentacao; nunca escreve nos TileMapLayers originais.
@export var world_path: NodePath = NodePath("../../..")
@export var forest_texture: Texture2D = null
@export var composition_seed: int = 6701
@export var player_floor_offset: float = 20.0

const TRAILS = [
	[Vector2(10, 35), Vector2(19, 35), Vector2(21, 33), Vector2(21, 27), Vector2(12, 27), Vector2(12, 16)],
	[Vector2(21, 27), Vector2(40, 27), Vector2(40, 9)],
	[Vector2(40, 22), Vector2(64, 22), Vector2(64, 33)],
	[Vector2(52, 22), Vector2(52, 14), Vector2(68, 14), Vector2(68, 7)]
]
const SMALL = [
	Rect2(0, 128, 16, 16), Rect2(16, 128, 16, 16), Rect2(0, 144, 16, 16),
	Rect2(32, 128, 16, 16), Rect2(48, 128, 16, 16), Rect2(64, 128, 16, 16),
	Rect2(80, 128, 16, 16), Rect2(16, 144, 16, 16), Rect2(32, 144, 16, 16),
	Rect2(80, 144, 16, 16), Rect2(96, 144, 16, 16),
	Rect2(96, 128, 16, 16), Rect2(112, 128, 16, 16), Rect2(128, 128, 16, 16)
]
const TALL = [Rect2(0, 160, 64, 96), Rect2(64, 160, 96, 96)]
const STUMPS = [Rect2(0, 256, 64, 32), Rect2(64, 256, 96, 64)]

var _terrain: TileMapLayer = null
var _obstacles: TileMapLayer = null
var _player: Node2D = null
var _image: Image = null
var _blocked: Dictionary = {}
var _roads: Dictionary = {}
var _segments: Array[PackedVector2Array] = []
var _base_samples: Dictionary = {}
var _protected: Array[Rect2] = []
var _ground_objects: Array[Dictionary] = []
var _trees: Array[Dictionary] = []
var _hidden: Array[Dictionary] = []
var _back: Node2D = null
var _front: Node2D = null
var _feet_y: float = -INF
var _metrics: Dictionary = {}


func _ready() -> void:
	set_process(false)
	var world: Node2D = get_node_or_null(world_path) as Node2D
	if world == null or forest_texture == null:
		push_warning("ECHOES-067: fontes ausentes; visual anterior preservado.")
		return
	_terrain = world.get_node_or_null("Tiles/Terrain") as TileMapLayer
	_obstacles = world.get_node_or_null("Tiles/Obstacles") as TileMapLayer
	if _terrain == null or _obstacles == null or _terrain.tile_set == null or _terrain.tile_set.tile_size != Vector2i(32, 32) or forest_texture.get_size() != Vector2(512, 512):
		push_warning("ECHOES-067: grade/atlas incompatível; visual anterior preservado.")
		return
	_image = forest_texture.get_image()
	if _image == null or _image.is_empty():
		return
	global_transform = _terrain.global_transform
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var main: Node = world.get_parent()
	_player = main.get_node_or_null("Player") as Node2D
	_read_protected(main)
	for cell in _obstacles.get_used_cells():
		_blocked[cell] = _obstacles.get_cell_atlas_coords(cell).x
	_build_ground()
	_build_objects()
	_build_drawers()
	_hide_previous(world)
	_metrics["blocked_cells"] = _blocked.size()
	_metrics["ground_objects"] = _ground_objects.size()
	_metrics["trees"] = _trees.size()
	_metrics["visual_nodes"] = 1 + get_child_count()
	set_process(is_instance_valid(_player))
	_process(0.0)


func get_visual_metrics() -> Dictionary:
	return _metrics.duplicate(true)


func _value(cell: Vector2i, salt: int = 0) -> int:
	var value: int = posmod(cell.x * 73856093 ^ cell.y * 19349663 ^ composition_seed ^ salt * 83492791, 2147483647)
	value = (value ^ (value >> 13)) * 1274126177
	return posmod(value ^ (value >> 16), 2147483647)


func _read_protected(main: Node) -> void:
	for name in ["Player", "InteractionTestObject", "Sucata", "Sucata2", "Water", "Water2", "Food", "Food2", "StealthTestListener", "StealthPrototypeThreat"]:
		var node: Node2D = main.get_node_or_null(NodePath(name)) as Node2D
		if node != null:
			_protected.append(Rect2(to_local(node.global_position) - Vector2(28, 48), Vector2(56, 80)))
	var house: Node2D = main.get_node_or_null("AbandonedHouse") as Node2D
	if house != null and house.has_meta("solid_bounds"):
		var bounds: Rect2 = house.get_meta("solid_bounds")
		bounds.position += to_local(house.global_position)
		_protected.append(bounds.grow(40.0))
		for name in ["Entrance", "ReturnSpawn"]:
			var marker: Node2D = house.get_node_or_null(NodePath(name)) as Node2D
			if marker != null:
				_protected.append(Rect2(to_local(marker.global_position) - Vector2(40, 40), Vector2(80, 80)))


func _clear(bounds: Rect2) -> bool:
	for rect in _protected:
		if rect.intersects(bounds):
			return false
	return true


func _new_layer(label: String, texture: Texture2D, columns: int) -> TileMapLayer:
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(32, 32)
	for x in range(columns):
		atlas.create_tile(Vector2i(x, 0))
	var tiles: TileSet = TileSet.new()
	tiles.tile_size = Vector2i(32, 32)
	tiles.add_source(atlas, 0)
	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = label
	layer.tile_set = tiles
	layer.collision_enabled = false
	layer.navigation_enabled = false
	add_child(layer)
	return layer


func _build_trails() -> void:
	for route in TRAILS:
		var points: PackedVector2Array = PackedVector2Array()
		points.append((route[0] + Vector2(0.5, 0.5)) * 32.0)
		for index in range(1, route.size() - 1):
			var previous: Vector2 = (route[index - 1] + Vector2(0.5, 0.5)) * 32.0
			var center: Vector2 = (route[index] + Vector2(0.5, 0.5)) * 32.0
			var next: Vector2 = (route[index + 1] + Vector2(0.5, 0.5)) * 32.0
			var radius: float = minf(40.0, minf(previous.distance_to(center), next.distance_to(center)) * 0.3)
			var a: Vector2 = center + center.direction_to(previous) * radius
			var b: Vector2 = center + center.direction_to(next) * radius
			points.append(a)
			for step in range(1, 5):
				var t: float = float(step) / 4.0
				points.append(a * (1.0 - t) * (1.0 - t) + center * 2.0 * (1.0 - t) * t + b * t * t)
		points.append((route[-1] + Vector2(0.5, 0.5)) * 32.0)
		for index in range(points.size() - 1):
			var a: Vector2 = points[index]
			var b: Vector2 = points[index + 1]
			if a.distance_squared_to(b) > 0.01:
				_segments.append(PackedVector2Array([a, b, (b - a).normalized().orthogonal()]))


func _build_ground() -> void:
	_build_trails()
	var ground: TileMapLayer = _new_layer("Ground", forest_texture, 3)
	var source: TileSetAtlasSource = ground.tile_set.get_source(0) as TileSetAtlasSource
	for index in range(3):
		source.create_alternative_tile(Vector2i(index, 0), 1)
		source.get_tile_data(Vector2i(index, 0), 1).modulate = Color(0.92, 0.96, 0.92, 1.0)
	var candidates: Array[Vector2i] = []
	for cell in _terrain.get_used_cells():
		var value: int = _value(cell)
		var variant: int = 0 if value % 10 < 6 else (1 if value % 10 < 9 else 2)
		ground.set_cell(cell, 0, Vector2i(variant, 0), 1 if _blocked.has(cell) else 0)
		if _terrain.get_cell_atlas_coords(cell) == Vector2i(1, 0) and not _blocked.has(cell):
			candidates.append(cell)
	_build_paths(candidates)
	_metrics["ground_cells"] = ground.get_used_cells().size()


func _build_paths(candidates: Array[Vector2i]) -> void:
	# Composicao plana: pixels originais da terra, sem inventar paredes/desniveis.
	# Recorte alpha em coordenadas mundiais evita costuras de celulas no contorno.
	var rows: int = maxi(1, ceili(float(candidates.size()) / 32.0))
	var image: Image = Image.create(1024, rows * 32, false, Image.FORMAT_RGBA8)
	var slots: Dictionary = {}
	for index in range(candidates.size()):
		var cell: Vector2i = candidates[index]
		var center: Vector2 = _terrain.map_to_local(cell)
		var nearby: Array[PackedVector2Array] = []
		for segment in _segments:
			if center.distance_to(Geometry2D.get_closest_point_to_segment(center, segment[0], segment[1])) < 64.0:
				nearby.append(segment)
		if nearby.is_empty():
			continue
		var slot: Vector2i = Vector2i(index % 32, index / 32)
		var variant: int = _value(cell, 1) % 3
		var painted: bool = false
		for y in range(32):
			for x in range(32):
				var point: Vector2 = center - Vector2(16, 16) + Vector2(x + 0.5, y + 0.5)
				var distance: float = INF
				for segment in nearby:
					var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1])
					var t: float = clampf((closest - segment[0]).length() / segment[0].distance_to(segment[1]), 0.0, 1.0)
					var wave: float = sin((closest.x + closest.y) * 0.018) * 8.0 * sin(t * PI)
					distance = minf(distance, point.distance_to(closest + segment[2] * wave))
				var width: float = 19.0 + sin(point.x * 0.021 + point.y * 0.013) * 4.0
				var grain: float = float(posmod(int(point.x) * 13 ^ int(point.y) * 7, 5) - 2) * 0.35
				var alpha: float = snappedf(clampf((width + grain - distance) * 0.5, 0.0, 1.0), 1.0 / 3.0)
				if alpha > 0.0:
					var color: Color = _image.get_pixel(96 + variant * 32 + x, y)
					color.a *= alpha
					image.set_pixel(slot.x * 32 + x, slot.y * 32 + y, color)
					painted = true
		if painted:
			slots[cell] = slot
			_roads[cell] = true
	var paths: TileMapLayer = _new_layer("Paths", ImageTexture.create_from_image(image), 0)
	var source: TileSetAtlasSource = paths.tile_set.get_source(0) as TileSetAtlasSource
	for cell: Vector2i in slots:
		var slot: Vector2i = slots[cell]
		source.create_tile(slot)
		paths.set_cell(cell, 0, slot)
	_metrics["path_cells"] = paths.get_used_cells().size()


func _solid_at(point: Vector2) -> bool:
	var local: Vector2 = _obstacles.to_local(to_global(point))
	var cell: Vector2i = _obstacles.local_to_map(local)
	var data: TileData = _obstacles.get_cell_tile_data(cell)
	if data == null:
		return false
	var relative: Vector2 = local - _obstacles.map_to_local(cell)
	for polygon in range(data.get_collision_polygons_count(0)):
		if Geometry2D.is_point_in_polygon(relative, data.get_collision_polygon_points(0, polygon)):
			return true
	return false


func _base_fits(point: Vector2, rect: Rect2) -> bool:
	if not _base_samples.has(rect):
		var samples: Array[Vector2] = []
		for y in range(int(rect.size.y) - 16, int(rect.size.y)):
			for x in range(int(rect.size.x)):
				if _image.get_pixel(int(rect.position.x) + x, int(rect.position.y) + y).a >= 0.5:
					samples.append(Vector2(x + 0.5 - rect.size.x * 0.5, y + 0.5 - rect.size.y))
		_base_samples[rect] = samples
	for offset: Vector2 in _base_samples[rect]:
		if not _solid_at(point + offset):
			return false
	return true


func _object(point: Vector2, rect: Rect2) -> Dictionary:
	return {"point": point.round(), "rect": rect}


func _build_objects() -> void:
	var region: Rect2i = _terrain.get_used_rect()
	for y in range(region.position.y, region.end.y, 2):
		for x in range(region.position.x, region.end.x, 2):
			var candidates: Array[Vector2i] = []
			for dy in range(2):
				for dx in range(2):
					var cell: Vector2i = Vector2i(x + dx, y + dy)
					if _blocked.has(cell) and int(_blocked[cell]) != 5:
						candidates.append(cell)
			candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return _value(a, 2) < _value(b, 2))
			for cell in candidates:
				var point: Vector2 = _terrain.map_to_local(cell) + Vector2(0, 10)
				var rect: Rect2 = TALL[_value(cell, 3) % 2]
				if not _clear(Rect2(point - Vector2(rect.size.x * 0.5, rect.size.y), rect.size)) or not _base_fits(point, rect):
					continue
				_trees.append(_object(point, rect))
				break
	for cell in _terrain.get_used_cells():
		var point: Vector2 = _terrain.map_to_local(cell)
		var value: int = _value(cell, 4)
		if not _clear(Rect2(point - Vector2(16, 24), Vector2(32, 40))):
			continue
		if _blocked.has(cell):
			var boundary: bool = false
			for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if not _blocked.has(cell + direction) and region.has_point(cell + direction):
					boundary = true
			if int(_blocked[cell]) == 5:
				_ground_objects.append(_object(point + Vector2(0, 8), SMALL[value % 3]))
			elif boundary or value % 4 == 0:
				_ground_objects.append(_object(point + Vector2(value % 19 - 9, (value / 19) % 15 - 3), SMALL[11 + _value(cell, 5) % 3]))
				if boundary:
					_ground_objects.append(_object(point + Vector2(-7, -5), SMALL[11 + _value(cell, 6) % 3]))
			if value % 73 == 0:
				var rect: Rect2 = STUMPS[value % 2]
				var base: Vector2 = point + Vector2(0, 10)
				if _base_fits(base, rect) and _clear(Rect2(base - Vector2(rect.size.x * 0.5, rect.size.y), rect.size)):
					_ground_objects.append(_object(base, rect))
			elif value % 47 == 0:
				_ground_objects.append(_object(point + Vector2(0, 8), Rect2(112, 144, 32, 16)))
		elif not _roads.has(cell) and value % 11 == 0:
			_ground_objects.append(_object(point + Vector2(value % 9 - 4, 6), SMALL[3 + _value(cell, 6) % 11]))
	_trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["point"].y < b["point"].y)
	_ground_objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["point"].y < b["point"].y)


func _build_drawers() -> void:
	var floor_decor: Node2D = Node2D.new()
	floor_decor.name = "GroundDecor"
	add_child(floor_decor)
	floor_decor.draw.connect(_draw_objects.bind(floor_decor, false, 0))
	_back = Node2D.new()
	_back.name = "ForestObjectsBehind"
	_back.z_as_relative = false
	_back.z_index = -1
	add_child(_back)
	_back.draw.connect(_draw_objects.bind(_back, true, -1))
	_front = Node2D.new()
	_front.name = "CanopyInFront"
	_front.z_as_relative = false
	_front.z_index = 1
	add_child(_front)
	_front.draw.connect(_draw_objects.bind(_front, true, 1))


func _draw_objects(canvas: Node2D, tall: bool, side: int) -> void:
	var objects: Array[Dictionary] = _trees if tall else _ground_objects
	for entry in objects:
		var point: Vector2 = entry["point"]
		if side != 0 and ((point.y > _feet_y) != (side > 0)):
			continue
		var rect: Rect2 = entry["rect"]
		canvas.draw_texture_rect_region(forest_texture, Rect2(point - Vector2(rect.size.x * 0.5, rect.size.y), rect.size), rect)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_visible_in_tree():
		return
	var next_y: float = to_local(_player.global_position).y + player_floor_offset
	if is_equal_approx(next_y, _feet_y):
		return
	var changed: bool = not is_finite(_feet_y)
	for entry in _trees:
		var point: Vector2 = entry["point"]
		if (point.y > _feet_y) != (point.y > next_y):
			changed = true
	_feet_y = next_y
	if changed:
		_back.queue_redraw()
		_front.queue_redraw()


func _hide_item(item: CanvasItem) -> void:
	if item != null:
		_hidden.append({"node": item, "visible": item.visible})
		item.hide()


func _hide_previous(world: Node2D) -> void:
	for path in ["Tiles/Terrain", "Tiles/Vegetation", "Tiles/Obstacles", "ForestDecor"]:
		_hide_item(world.get_node_or_null(NodePath(path)) as CanvasItem)
	for sibling in get_parent().get_children():
		if sibling != self and sibling is CanvasItem:
			_hide_item(sibling as CanvasItem)


func _exit_tree() -> void:
	for entry in _hidden:
		if is_instance_valid(entry["node"]):
			(entry["node"] as CanvasItem).visible = bool(entry["visible"])
