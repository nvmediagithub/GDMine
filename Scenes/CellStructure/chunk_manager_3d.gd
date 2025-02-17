extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(256,256,256)
var chunks: Dictionary = {}  # ключ: Vector2i, значение: Chunk3D узел
	
func _ready() -> void:
	var new_chunk = Chunk3D.new()
	var new_slice = ChunkSlice.new(256, true, origin)
	new_chunk.set_chunk(new_slice)
	new_chunk.visible = true
	add_child(new_chunk)
	#var start_point = CellPoint.new(Vector2i(0,0))
	#load_chunk(Vector2i(0,0))
	#expand_structure()
	

func get_chunk_key_for_point(point: Vector2i) -> Vector2i:
	var relative_pos = point - origin
	var i = int(floor(relative_pos.x / chunk_size.x))
	var j = int(floor(relative_pos.y / chunk_size.y))
	return Vector2i(i, j)

func get_neighbor_keys(key: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for di in range(-1, 2):
		for dj in range(-1, 2):
				if di == 0 and dj == 0:
					continue
				neighbors.append(Vector2i(key.x + di, key.y + dj))
	return neighbors
	
func load_chunk(key: Vector2i) -> void:
	# Если чанк не существует, создаем его как загруженный
	if not chunks.has(key):
		var chunk_origin = origin + Vector2i(key.x * chunk_size.x, key.y * chunk_size.y)
		var new_chunk = Chunk3D.new()
		var new_slice = ChunkSlice.new(chunk_size.x, true, key)
		new_chunk.set_chunk(new_slice)
		# Добавляем новый узел как дочерний к менеджеру
		add_child(new_chunk)
		chunks[key] = new_chunk
	else:
		chunks[key].need_expand = true

	# Создаем соседние чанки, если их еще нет, как незагруженные
	for nkey in get_neighbor_keys(key):
		if not chunks.has(nkey):
			var neighbor_origin = origin + Vector2i(nkey.x * chunk_size.x, nkey.y * chunk_size.y)
			var neighbor_chunk = Chunk3D.new()
			var new_slice = ChunkSlice.new(chunk_size.x, false, nkey)
			neighbor_chunk.set_chunk(new_slice)
			add_child(neighbor_chunk)
			chunks[nkey] = neighbor_chunk

func get_chunk_for_point(point: Vector2i) -> Chunk3D:
	var key = get_chunk_key_for_point(point)
	if chunks.has(key):
		return chunks[key]
	return null

func update_loaded_chunks() -> void:
	var loaded_keys = []
	for key in chunks.keys():
		if chunks[key].need_expand:
			loaded_keys.append(key)
	for key in loaded_keys:
		load_chunk(key)

func get_loaded_chunks() -> Array:
	var loaded_chunks = []
	for chunk in chunks.values():
		if chunk.need_expand:
			loaded_chunks.append(chunk)
	return loaded_chunks
	
func expand_structure(connection_threshold: float = 300.0) -> void:
	for chunk in chunks.values():
		if not chunk.slice.need_expand:
			continue
		var new_lines = []
		for chunk_line in chunk.slice.lines:
			var p_start = chunk_line.start
			var p_end = chunk_line.end
			if p_end.has_emitted:
				continue
			p_end.has_emitted = true
			var base_direction = calculate_angle(p_start.position, p_end.position)
			var target_points = generate_child_rays(p_end, base_direction, 3, 40.0, 60.0, deg_to_rad(90.0))
			for target_point in target_points:
				for line in chunk.lines:
					var inter = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
					if inter != null:
						target_point = line.start if (inter - line.start.position).length() < (inter - line.end.position).length() else line.end

				var neighbor_keys = get_neighbor_keys(chunk.grid_pos)
				for neighbor_key in neighbor_keys:
					if chunks.has(neighbor_key):
						var neighbor_chunk = chunks[neighbor_key]
						for line in neighbor_chunk.lines:
							var inter = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
							if inter != null:
								target_point = line.start if (inter - line.start.position).length() < (inter - line.end.position).length() else line.end

				for line in new_lines:
					var inter = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
					if inter != null:
						target_point = line.start if (inter - line.start.position).length() < (inter - line.end.position).length() else line.end

				var new_line = CellLine.new(p_end, target_point)
				new_lines.append(new_line)

		for line in new_lines:
			var target_chunk = get_chunk_for_point(line.start.position)
			if target_chunk != null:
				target_chunk.add_line(line)
				

func calculate_angle(start: Vector2, end: Vector2) -> float:
	# Вычисление угла в радианах
	var dx = end.x - start.x
	var dy = end.y - start.y
	return atan2(dy, dx)

func generate_child_rays(start_point: CellPoint, base_direction: float, child_count: int = 2,
						min_length: float = 30, max_length: float = 50,
						max_deviation: float = deg_to_rad(80)) -> Array[CellLine]:
	"""
	Генерирует child_count лучей из start_point.
	Направление каждого луча основывается на base_direction (в радианах) с отклонением не более max_deviation.

	Возвращает список лучей, где каждый луч представлен как список [start_point, end_point],
	а end_point – объект CellPoint с целочисленными координатами.
	"""
	var points = []
	var rng = RandomNumberGenerator.new()
	for n in range(child_count):
		# Вычисляем случайное отклонение
		var deviation = rng.randf_range(-max_deviation, max_deviation)
		var new_angle = base_direction + deviation
		# Выбираем случайную длину луча
		var length = rng.randf_range(min_length, max_length)
		var dx = cos(new_angle) * length
		var dy = sin(new_angle) * length
		# Вычисляем координаты конечной точки и округляем до целых чисел
		var new_x = int(round(start_point.x + dx))
		var new_y = int(round(start_point.y + dy))
		var end_point = CellPoint.new(Vector2(new_x, new_y))
		points.append(end_point)
	return points


func line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, tol: float = 1e-6):
	"""
	Вычисляет точку пересечения двух отрезков (p1, p2) и (p3, p4) с учетом допуска tol.
	p1, p2, p3, p4 – объекты Vector2, представляющие концы отрезков.
	Возвращает Vector2 с координатами точки пересечения, если отрезки пересекаются, иначе null.
	"""
	if abs(p1.x - p4.x) < 1e-6 and abs(p1.y - p4.y) < 1e-6:
		return null  # Новый отрезок исходит из этой прямой
	if abs(p1.x - p3.x) < 1e-6 and abs(p1.y - p3.y) < 1e-6:
		return null  # Новый отрезок исходит из этой прямой
		
	# Направления отрезков
	var d1 = p2 - p1
	var d2 = p4 - p3
		
	# Определитель
	var det = d1.x * d2.y - d1.y * d2.x
	# Если определитель близок к нулю, отрезки параллельны или совпадают
	if abs(det) < tol:
		return null
	# Вычисление параметра t для точки пересечения
	var diff = p3 - p1
	var t = (diff.x * d2.y - diff.y * d2.x) / det
	# Проверка, что точка пересечения находится на первом отрезке
	if t < 0 or t > 1:
		return null
	# Вычисление параметра u для точки пересечения
	var u = (diff.x * d1.y - diff.y * d1.x) / det
	# Проверка, что точка пересечения находится на втором отрезке
	if u < 0 or u > 1:
		return null
	# Вычисление координат точки пересечения
	var intersection = p1 + t * d1
	return intersection
