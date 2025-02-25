# chunk_slice.gd
extends RefCounted
class_name ChunkSlice

# Параметры чанка: координаты верхнего левого угла, размеры, флаг загрузки и позиция в сетке (например, Vector2)
var size: float
var need_expand: bool = true
var grid_pos: Vector2

# Массивы для хранения точек, линий и полигонов (если потребуется)
var lines: Array[CellLine] = []

func _init(p_size: float, p_need_expand: bool) -> void:
	size = p_size
	need_expand = p_need_expand

	lines = []

# Метод для проверки, принадлежит ли точка чанку (используются только x и y)
func contains(point: CellPoint) -> bool:
	# Ожидается, что у point есть свойство "position", которое является Vector2
	var pos: Vector2 = point.position
	# Используем стандартную семантику: левая и верхняя границы включаются, правая и нижняя — нет
	return pos.x >= grid_pos.x and pos.x < (grid_pos.x + size) and pos.y >= grid_pos.y and pos.y < (grid_pos.y + size)


func add_line(line: CellLine) -> void:
	lines.append(line)
	find_polygon(line)

func _to_string() -> String:
	return "ChunkSlice(size=%d, need_expand=%s, grid_pos=%s, lines=%d)" % [
		size, str(need_expand), str(grid_pos), lines.size()
	]
		
func find_polygon(line: CellLine) -> Array:
	"""
	Ищет самый короткий путь от точки line.start до точки line.end 
	по линиям, хранящимся в self.lines.
	Возвращает Array[CellLine] – последовательность линий, образующих путь.
	Если путь не найден, возвращает пустой массив.
	"""	
	var start_key: CellPoint = line.start
	var end_key: CellPoint = line.end
	
	# Инициализируем очередь и словарь посещённых вершин
	var queue: Array = []
	var visited: Dictionary = {}  # key: String, value: bool
	# prev будет хранить для каждой вершины ту линию, по которой к ней пришли
	var prev: Dictionary = {}  # key: String, value: CellLine
	
	queue.append(start_key)
	visited[start_key] = true
	prev[start_key] = null
	
	# Алгоритм BFS
	while queue.size() > 0:
		var current_key: CellPoint = queue.pop_front()
		if current_key == end_key:
			break
		# Перебираем все линии графа (self.lines – массив CellLine)
		for l: CellLine in lines:
			# Предполагаем, что граф неориентированный: ищем все соседние вершины
			if current_key == l.start and not visited.has(l.end):
				visited[l.end] = true
				prev[l.end] = l
				queue.append(l.end)
			elif current_key == l.end and not visited.has(l.start):
				visited[l.start] = true
				prev[l.start] = l
				queue.append(l.start)
	
	# Если целевая вершина не достигнута, возвращаем пустой массив
	if not visited.has(end_key):
		return []
	
	# Восстанавливаем путь (список линий) от e_point до s_point, затем переворачиваем
	var path: Array = []
	var cur_key: CellPoint = end_key
	while cur_key != start_key:
		var edge: CellLine = prev[cur_key]
		if edge == null:
			break
		path.append(edge)
		# Определяем, откуда пришли: если текущая вершина совпадает с end, то предыдущая – start, иначе наоборот
		if edge.end == cur_key:
			cur_key = edge.start
		else:
			cur_key = edge.end
	print(path)
	return path
	
