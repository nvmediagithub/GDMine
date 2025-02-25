extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(8.0,8.0,8.0)
@export var min_ray_length: float = 1.0
@export var max_ray_length: float = 2.0
# Допустим, у нас есть ссылка на игрока (или камеру)
@export var player: Node3D
@export var view_distance: int = 1   # Зона видимости в чанках

var chunks: Dictionary = {}
var limit: float = 0.15

func _ready() -> void:
	var start_point: CellPoint = CellPoint.new(Vector2(chunk_size.x,chunk_size.z) / 2)
	load_chunk(Vector2i(0,0))
	var points: Array[CellPoint] =\
		CellStructureUtils.generate_child_rays(
			start_point, 
			0, 
			3, 
			min_ray_length, 
			max_ray_length
		)
	var chunk: Chunk3D = chunks[Vector2i(0,0)]
	for end_point: CellPoint in points:
		chunk.add_line(CellLine.new(start_point, end_point))
	for i: int in range(14):
		expand_structure()
	chunk.create_polygons()
	chunk.update_geometry()
	
	
func _process(_delta: float) -> void:
	
	# При каждом кадре проверяем, изменилось ли положение игрока
	update_chunk_loading()
	expand_structure()

func get_chunk_key_for_point(point: Vector2) -> Vector2i:
	return Vector2i(
		floor((point.x - origin.x) / chunk_size.x), 
		floor((point.y - origin.y) / chunk_size.z)
	)
	
func get_neighbor_keys(key: Vector2i, radius: int) -> Array[Vector2i]:
	var keys: Array[Vector2i] = []
	for i: int in range(key.x - radius, key.x + radius + 1):
		for j: int in range(key.y - radius, key.y + radius + 1):
			keys.append(Vector2i(i, j))
	return keys
	
func load_chunk(key: Vector2i) -> void:
	# Если чанк не существует, создаем его как загруженный
	if not chunks.has(key):
		var new_chunk: Chunk3D = Chunk3D.new(key)
		var new_slice: ChunkSlice = ChunkSlice.new(chunk_size.x, true)
		new_chunk.size = chunk_size
		new_chunk.set_chunk(new_slice)
		# Добавляем новый узел как дочерний к менеджеру
		add_child(new_chunk)
		chunks[key] = new_chunk

	# Создаем соседние чанки, если их еще нет, как незагруженные
	for nkey: Vector2i in get_neighbor_keys(key, 1):
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
			# Создаем новые точки лучей
			var target_points: Array[CellPoint] =\
				CellStructureUtils.generate_child_rays(
					p_end, 
					base_direction, 
					2, 
					min_ray_length, 
					max_ray_length, 
					PI / 2
				)
			# Поиск линии и точки пересечения
			for target_point: CellPoint in target_points:
				var last_line: CellLine = null
				var all_lines: Array[CellLine] = new_lines + chunk.get_lines()
				for neighbor_key: Vector2i in get_neighbor_keys(chunk.grid_pos, 1):
					if chunks.has(neighbor_key):
						var neighbor_chunk: Chunk3D = chunks[neighbor_key]
						all_lines += neighbor_chunk.get_lines()
						
				for line: CellLine in all_lines:
					var inter: CellPoint =\
						CellStructureUtils.line_intersection(
							p_end, 
							target_point, 
							line.start, 
							line.end
						)
					if inter != null:
						last_line = line
						target_point.position = inter.position
						target_point.has_emitted = true
				
				# Если есть пересечение
				if (last_line != null):
					# Если точка пересечения близко "подтягиваем позицию"
					if (target_point.position - last_line.start.position).length() < limit:
						last_line.start.position = target_point.position
						target_point = last_line.start
					elif (target_point.position - last_line.end.position).length() < limit:
						last_line.end.position = target_point.position
						target_point = last_line.end
					else: # разбить линию на 2
						var new_split: CellLine = CellLine.new(target_point, last_line.end)
						last_line.end = target_point
						new_lines.append(new_split)
				var new_line: CellLine = CellLine.new(p_end, target_point)
				new_lines.append(new_line)

		for line: CellLine in new_lines:
			var target_chunk: Chunk3D = get_chunk_for_point(line.start.position)
			# TODO Если чанка нет, создать его
			if target_chunk != null:
				need_expand = true
				target_chunk.add_line(line)

func update_chunk_loading() -> void:
	# Получаем позицию игрока в 2D (используем X и Z)
	var player_pos: Vector2 = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	var center_key: Vector2i = get_chunk_key_for_point(player_pos)
	
	# Определяем диапазон чанков для загрузки
	var keys_to_load: Array[Vector2i] = get_neighbor_keys(center_key, view_distance)
	
	# Загружаем нужные чанки
	for key: Vector2i in keys_to_load:
		load_chunk(key)
		chunks[key].expand()
	if center_key in chunks.keys():
		chunks[center_key].expand()
