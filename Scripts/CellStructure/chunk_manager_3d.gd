extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(8.0,8.0,8.0)
@export var min_ray_length: float = 1.0
@export var max_ray_length: float = 1.5
var chunks: Dictionary = {}
var limit: float = 0.1 
	
func _ready() -> void:
	var start_point: CellPoint = CellPoint.new(Vector2(chunk_size.x,chunk_size.z) / 2)
	load_chunk(Vector2i(0,0))
	var points: Array[CellPoint] =\
		CellStructureUtils.generate_child_rays(
			start_point, 
			0, 
			6, 
			min_ray_length, 
			max_ray_length
		)
	var chunk: Chunk3D = chunks[Vector2i(0,0)]
	chunk.size = chunk_size
	for end_point: CellPoint in points:
		chunk.add_line(CellLine.new(start_point, end_point))
	for i: int in range(14):
		expand_structure()
	
func get_chunk_key_for_point(point: Vector2) -> Vector2i:
	return Vector2i(
		floor((point.x - origin.x) / chunk_size.x), 
		floor((point.y - origin.y) / chunk_size.z)
	)

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
		var new_slice: ChunkSlice = ChunkSlice.new(chunk_size.x, true)
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
			neighbor_chunk.position =\
				Vector3(local_position.x, 0, local_position.y)
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
			var base_direction: float =\
				CellStructureUtils.calculate_angle(
					p_start.position, 
					p_end.position
				)
			var target_points: Array[CellPoint] =\
				CellStructureUtils.generate_child_rays(
					p_end, 
					base_direction, 
					2, 
					min_ray_length, 
					max_ray_length, 
					PI / 2
				)
			# Проверка всех пересечений
			for target_point: CellPoint in target_points:
				var last_line: CellLine = null
				for line: CellLine in chunk.get_lines():
					var inter: CellPoint =\
						CellStructureUtils.line_intersection(
							p_end, 
							target_point, 
							line.start, 
							line.end
						)
					if inter != null:
						last_line = line
						target_point = inter
						target_point.has_emitted = true

				var chunk_key: Vector2i = chunks.find_key(chunk) 
				var neighbor_keys: Array[Vector2i] = get_neighbor_keys(chunk_key)
				for neighbor_key: Vector2i in neighbor_keys:
					if chunks.has(neighbor_key):
						var neighbor_chunk: Chunk3D = chunks[neighbor_key]
						for line: CellLine in neighbor_chunk.get_lines():
							var inter: CellPoint =\
								CellStructureUtils.line_intersection(
									p_end,
									target_point,
									line.start,
									line.end
								)
							if inter != null:
								last_line = line
								target_point = inter
								target_point.has_emitted = true

				for line: CellLine in new_lines:
					var inter: CellPoint =\
						CellStructureUtils.line_intersection(
							p_end, 
							target_point, 
							line.start, 
							line.end
						)
					if inter != null:
						last_line = line
						target_point = inter
						target_point.has_emitted = true
				
				if (p_end.position - target_point.position).length() > limit:
					var new_line: CellLine = CellLine.new(p_end, target_point)
					new_lines.append(new_line)
				else:
					chunk_line.end = target_point


		for line: CellLine in new_lines:
			var target_chunk: Chunk3D = get_chunk_for_point(line.start.position)
			if target_chunk != null:
				need_expand = true
				target_chunk.add_line(line)
