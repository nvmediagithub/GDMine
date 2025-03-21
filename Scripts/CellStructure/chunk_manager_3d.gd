extends Node3D
class_name ChunkManager3D

# Параметры сетки чанков
@export var origin: Vector2i = Vector2i(0,0)
@export var chunk_size: Vector3 = Vector3(8.0,8.0,8.0)
@export var min_ray_length: float = 0.5
@export var max_ray_length: float = 2.5
# Допустим, у нас есть ссылка на игрока (или камеру)
@export var player: Node3D
@export var view_distance: int = 1   # Зона видимости в чанках

var chunks: Dictionary[Vector2i, Chunk3D] = {}
var limit: float = 0.2

func _process(_delta: float) -> void:
    # При каждом кадре проверяем, изменилось ли положение игрока
    update_chunk_loading()
    if Input.is_action_pressed("move_down"):
        var player_pos: Vector2 = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
        var center_key: Vector2i = get_chunk_key_for_point(player_pos)
        expand_structure(center_key)
        chunks[center_key].create_polygons()
        chunks[center_key].update_debug_geometry()


# point в глобальной системе
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
    if chunk.status == Chunk3D.Status.GREEN:
        return
    var new_lines: Array[CellLine] = []
    for chunk_line: CellLine in chunk.get_lines():
        var p_start: CellPoint = chunk_line.start
        var p_end: CellPoint = chunk_line.end
        if p_end.has_emitted:
            continue
        p_end.has_emitted = true
        var base_direction: float =\
            (p_end.position - p_start.position).angle()

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
            var all_lines: Array[CellLine] = new_lines + chunk.get_lines()
            var last_line: CellLine = null
            for line: CellLine in all_lines:
                if p_end == line.start or p_end == line.end:
                    continue
                var inter: Variant =\
                    Geometry2D.segment_intersects_segment(
                        p_end.position, 
                        target_point.position, 
                        line.start.position, 
                        line.end.position
                    )
                if inter != null:
                    last_line = line
                    target_point.position = inter
                    target_point.has_emitted = true
            
            var last_n_line: CellLine = null
            var last_n_chunk: Chunk3D = null     
            for nkey: Vector2i in get_neighbor_keys(key, 1):
                if not chunks.has(nkey):
                    continue
                for line: CellLine in chunks[nkey].get_lines():
                    if p_end == line.start or p_end == line.end:
                        continue
                    # В глобальную систему 
                    var inter: Variant =\
                        Geometry2D.segment_intersects_segment(
                            p_end.position + Vector2(chunk.position.x, chunk.position.z), 
                            target_point.position + Vector2(chunk.position.x, chunk.position.z), 
                            line.start.position + Vector2(chunks[nkey].position.x, chunks[nkey].position.z), 
                            line.end.position + Vector2(chunks[nkey].position.x, chunks[nkey].position.z)
                        )
                    # В локальную систему 
                    if inter != null:
                        inter -= Vector2(chunk.position.x, chunk.position.z)
                        last_n_line = line
                        target_point.position = inter
                        target_point.has_emitted = true
                        last_n_chunk = chunks[nkey]


            # Если есть пересечение с соседним чанком
            if (last_n_line != null):
                pass
                var new_pos: Vector2 =\
                    target_point.position +\
                    Vector2(chunk.position.x, chunk.position.z) -\
                    Vector2(last_n_chunk.position.x, last_n_chunk.position.z) 
                var new_target_poin: CellPoint =\
                    CellPoint.new(new_pos)
                var new_split: CellLine = CellLine.new(new_target_poin, last_n_line.end)
                last_n_line.end = new_target_poin                
                last_n_chunk.add_line(new_split)
                
            # Если есть пересечение в чанке
            elif (last_line != null):
                var new_split: CellLine = CellLine.new(target_point, last_line.end)
                last_line.end = target_point
                chunk.add_line(new_split)
            
            var new_line: CellLine = CellLine.new(p_end, target_point)
            
            if 	new_lines.is_empty() or \
                new_lines.back().end != new_line.end or \
                new_lines.back().start != new_line.start:
                new_lines.append(new_line)
    
    for line: CellLine in new_lines:
        var gpos: Vector2 =\
            line.start.position +\
            Vector2(chunk.position.x, chunk.position.z)
        var target_chunk: Chunk3D = get_chunk_for_point(gpos)
        
        chunk.add_line(line)
        if target_chunk != chunk:
            chunk.status = Chunk3D.Status.YELLOW
    
    # TODO когда будут прогруженны соседние чаник статус зеленный
    if new_lines.size() == 0:
        chunk.status = Chunk3D.Status.YELLOW
        
    if new_lines.size() == 0:
        chunk.status = Chunk3D.Status.YELLOW
    
    if new_lines.size() == 0 and get_neighbor_keys(key, 1).all(func(el: Vector2i) -> bool: return chunks.has(el)):
        chunk.status = Chunk3D.Status.GREEN
        
            

func update_chunk_loading() -> void:
    # Получаем позицию игрока в 2D (используем X и Z)
    var player_pos: Vector2 = Vector2(player.global_transform.origin.x, player.global_transform.origin.z)
    var center_key: Vector2i = get_chunk_key_for_point(player_pos)
    # Определяем диапазон чанков для загрузки
    var keys_to_load: Array[Vector2i] = get_neighbor_keys(center_key, view_distance)
    # Загружаем нужные чанки
    for key: Vector2i in keys_to_load:
        load_chunk(key)
    
