extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(8.0,8.0,8.0)
@export var min_ray_lenght: float = 1.5
@export var max_ray_lenght: float = 3.0
var chunks: Dictionary = {}  # ключ: Vector2i, значение: Chunk3D узел
	
func _ready() -> void:
	var start_point: CellPoint = CellPoint.new(Vector2(0,0))
	load_chunk(Vector2i(0,0))
	var points: Array[CellPoint] = generate_child_rays(start_point, 3.14/2, 2, min_ray_lenght, max_ray_lenght)
	var chunk: Chunk3D = chunks[Vector2i(0,0)]
	chunk.size = chunk_size
	chunk.add_line(CellLine.new(start_point, points[0]))
	chunk.add_line(CellLine.new(start_point, points[1]))
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	expand_structure()
	
func get_chunk_key_for_point(point: Vector2) -> Vector2i:
	#print('point ', point)
	var relative_pos: Vector2i = Vector2i(floor(point.x / chunk_size.x), floor(point.y / chunk_size.y)) - origin
	#print('relative_pos ', relative_pos)
	var i: int = int(floor(relative_pos.x / chunk_size.x))
	var j: int = int(floor(relative_pos.y / chunk_size.y))
	return Vector2i(i, j)

func get_neighbor_keys(key: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for di: int in range(-1, 2):
		for dj: int in range(-1, 2):
				if di == 0 and dj == 0:
					continue
				neighbors.append(Vector2i(key.x + di, key.y + dj))
	return neighbors
	
func load_chunk(key: Vector2i) -> void:
	# Если чанк не существует, создаем его как загруженный
	if not chunks.has(key):
		var new_chunk: Chunk3D = Chunk3D.new(key)
		var new_slice: ChunkSlice = ChunkSlice.new(int(chunk_size.x), true)
		new_chunk.set_chunk(new_slice)
		new_chunk.size = chunk_size
		# Добавляем новый узел как дочерний к менеджеру
		add_child(new_chunk)
		chunks[key] = new_chunk

	# Создаем соседние чанки, если их еще нет, как незагруженные
	for nkey: Vector2i in get_neighbor_keys(key):
		if not chunks.has(nkey):
			var neighbor_chunk: Chunk3D = Chunk3D.new(nkey)
			var new_slice: ChunkSlice = ChunkSlice.new(chunk_size.x, false)
			neighbor_chunk.size = chunk_size
			neighbor_chunk.set_chunk(new_slice)
			var local_position: Vector2 = nkey * chunk_size.x
			neighbor_chunk.position = Vector3(local_position.x, 0, local_position.y)
			add_child(neighbor_chunk)
			chunks[nkey] = neighbor_chunk

func get_chunk_for_point(point: Vector2) -> Chunk3D:
	var key: Vector2i = get_chunk_key_for_point(point)
	if chunks.has(key):
		return chunks[key]
	return null

func update_loaded_chunks() -> void:
	var loaded_keys: Array[Vector2i] = []
	for key: Vector2i in chunks.keys():
		if chunks[key].need_expand:
			loaded_keys.append(key)
	for key: Vector2i in loaded_keys:
		load_chunk(key)

func get_loaded_chunks() -> Array:
	var loaded_chunks: Array[Vector2i] = []
	for chunk: Chunk3D in chunks.values():
		if chunk.need_expand:
			loaded_chunks.append(chunk)
	return loaded_chunks
	
func expand_structure() -> void:
	print("expand_structure")
	var need_expand: bool = false
	for chunk: Chunk3D in chunks.values():
		if not chunk.need_expand():
			continue
		var new_lines: Array[CellLine] = []
		for chunk_line: CellLine in chunk.get_lines():
			var p_start: CellPoint = chunk_line.start
			var p_end: CellPoint = chunk_line.end
			if p_end.has_emitted:
				continue
			p_end.has_emitted = true
			var base_direction: float = calculate_angle(p_start.position, p_end.position)
			var target_points: Array[CellPoint] = generate_child_rays(p_end, base_direction, 2, min_ray_lenght, max_ray_lenght)
			for target_point: CellPoint in target_points:
				for line: CellLine in chunk.get_lines():
					var inter: CellPoint = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
					if inter != null:
						target_point = line.end
				var k: Vector2i = chunks.find_key(chunk) 
				var neighbor_keys: Array[Vector2i] = get_neighbor_keys(k)
				for neighbor_key: Vector2i in neighbor_keys:
					if chunks.has(neighbor_key):
						var neighbor_chunk: Chunk3D = chunks[neighbor_key]
						for line: CellLine in neighbor_chunk.get_lines():
							var inter: CellPoint = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
							if inter != null:
								target_point = line.end

				for line: CellLine in new_lines:
					var inter: CellPoint = line_intersection(p_end.position, target_point.position, line.start.position, line.end.position)
					if inter != null:
						target_point = line.end

				var new_line: CellLine = CellLine.new(p_end, target_point)
				new_lines.append(new_line)

		for line: CellLine in new_lines:
			var target_chunk: Chunk3D = get_chunk_for_point(line.start.position)
			if target_chunk != null:
				need_expand = true
				target_chunk.add_line(line)
	#if need_expand:
		#expand_structure()

func calculate_angle(start: Vector2, end: Vector2) -> float:
	# Вычисление угла в радианах
	var dx: float = end.x - start.x
	var dy: float = end.y - start.y
	return atan2(dy, dx)

func generate_child_rays(start_point: CellPoint, base_direction: float, child_count: int = 2,
						min_length: float = 1, max_length: float = 2,
						max_deviation: float = deg_to_rad(80)) -> Array[CellPoint]:
	"""
	Генерирует child_count лучей из start_point.
	Направление каждого луча основывается на base_direction (в радианах) с отклонением не более max_deviation.

	Возвращает список лучей, где каждый луч представлен как список [start_point, end_point],
	а end_point – объект CellPoint с целочисленными координатами.
	"""
	var points: Array[CellPoint] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for n: int in range(child_count):
		# Вычисляем случайное отклонение
		var deviation: float = rng.randf_range(-max_deviation, max_deviation)
		var new_angle: float = base_direction + deviation
		# Выбираем случайную длину луча
		var length: float = rng.randf_range(min_length, max_length)
		var dx: float  = cos(new_angle) * length
		var dy: float = sin(new_angle) * length
		# Вычисляем координаты конечной точки и округляем до целых чисел
		var new_x: int = int(round(start_point.position.x + dx))
		var new_y: int = int(round(start_point.position.y + dy))
		var end_point: CellPoint = CellPoint.new(Vector2(new_x, new_y))
		points.append(end_point)
	return points


func line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, tol: float = 1e-6) -> CellPoint:
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
	var d1: Vector2 = p2 - p1
	var d2: Vector2 = p4 - p3
		
	# Определитель
	var det: float = d1.x * d2.y - d1.y * d2.x
	# Если определитель близок к нулю, отрезки параллельны или совпадают
	if abs(det) < tol:
		return null
	# Вычисление параметра t для точки пересечения
	var diff: Vector2 = p3 - p1
	var t: float = (diff.x * d2.y - diff.y * d2.x) / det
	# Проверка, что точка пересечения находится на первом отрезке
	if t < 0 or t > 1:
		return null
	# Вычисление параметра u для точки пересечения
	var u: float = (diff.x * d1.y - diff.y * d1.x) / det
	# Проверка, что точка пересечения находится на втором отрезке
	if u < 0 or u > 1:
		return null
	# Вычисление координат точки пересечения
	var intersection: Vector2 = p1 + t * d1
	return CellPoint.new(intersection)
