extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(8.0,8.0,8.0)
@export var min_ray_length: float = 0.5
@export var max_ray_length: float = 1.5
# Допустим, у нас есть ссылка на игрока (или камеру)
@export var player: Node3D
@export var view_distance: int = 1   # Зона видимости в чанках

var chunks: Dictionary[Vector2i, Chunk3D] = {}
var limit: float = 0.2

func _process(_delta: float) -> void:
	# При каждом кадре проверяем, изменилось ли положение игрока
	update_chunk_loading()

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
		var new_chunk: Chunk3D = init_chunk(key)
		new_chunk.position = Vector3(key.x * chunk_size.x, 0, key.y * chunk_size.z)
		add_child(new_chunk)
	# Создаем соседние чанки, если их еще нет, как незагруженные
	for nkey: Vector2i in get_neighbor_keys(key, 1):
		if not chunks.has(nkey):
			var new_chunk: Chunk3D = init_chunk(nkey)
			new_chunk.position = Vector3(nkey.x * chunk_size.x, 0, nkey.y * chunk_size.z)
			add_child(new_chunk)

func init_chunk(key: Vector2i) -> Chunk3D:
		if chunks.has(key): return
		var new_chunk: Chunk3D = Chunk3D.new(key, chunk_size)
		new_chunk.size = chunk_size
		new_chunk.position = Vector3(key.x * chunk_size.x, 0.0, key.y * chunk_size.z)
		chunks[key] = new_chunk
		
		var start_point: CellPoint =\
			CellPoint.new(
				Vector2(chunk_size.x / 2, chunk_size.z / 2)
			)
		var end_points: Array[CellPoint] =\
		CellStructureUtils.generate_child_rays(
			start_point, 
			0, 
			3, 
			min_ray_length, 
			max_ray_length
		)
		for end_point: CellPoint in end_points:
			new_chunk.add_line(CellLine.new(start_point, end_point))
			
		while new_chunk.status == Chunk3D.Status.RED:
			expand_structure(key)
		new_chunk.create_polygons()
		new_chunk.update_debug_geometry()
		return new_chunk

func get_chunk_for_point(point: Vector2) -> Chunk3D:
	var key: Vector2i = get_chunk_key_for_point(point)
	if chunks.has(key):
		return chunks[key]
	return null

# TODO перенести в слайсы или чанк
func expand_structure(key: Vector2i) -> void:
	var chunk: Chunk3D = chunks[key]
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
					target_point = last_line.start
				elif (target_point.position - last_line.end.position).length() < limit:
					target_point = last_line.end
				else: # разбить линию на 2
					var new_split: CellLine = CellLine.new(target_point, last_line.end)
					last_line.end = target_point
					new_lines.append(new_split)
					
			var new_line: CellLine = CellLine.new(p_end, target_point)
			
			#if (p_end.position - target_point.position).length() < limit:
				#chunk_line.end = target_point
				#continue
			if 	new_lines.is_empty() or \
				new_lines.back().end != new_line.end or \
				new_lines.back().start != new_line.start:
				
				new_lines.append(new_line)
			
	
	for line: CellLine in new_lines:
		var gpos: Vector2 =\
			line.start.position +\
			Vector2(chunk.position.x, chunk.position.z)
		var target_chunk: Chunk3D = get_chunk_for_point(gpos)
		
		if target_chunk == chunk:
			target_chunk.add_line(line)
	
	# TODO когда будут прогруженны соседние чаник статус зеленный
	if new_lines.size() == 0:
		chunk.status = Chunk3D.Status.YELLOW

func update_chunk_loading() -> void:
	# Получаем позицию игрока в 2D (используем X и Z)
	var player_pos: Vector2 = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
	var center_key: Vector2i = get_chunk_key_for_point(player_pos)
	# Определяем диапазон чанков для загрузки
	var keys_to_load: Array[Vector2i] = get_neighbor_keys(center_key, view_distance)	
	# Загружаем нужные чанки
	for key: Vector2i in keys_to_load:
		load_chunk(key)
