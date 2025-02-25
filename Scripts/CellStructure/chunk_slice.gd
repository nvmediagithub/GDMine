# chunk_slice.gd
extends RefCounted
class_name ChunkSlice

# Параметры чанка: координаты верхнего левого угла, размеры, флаг загрузки и позиция в сетке (например, Vector2)
var size: float
var need_expand: bool = true
# Массивы для хранения точек, линий и полигонов (если потребуется)
var lines: Array[CellLine] = []

var polygons: Array = []

func _init(p_size: float, p_need_expand: bool) -> void:
	size = p_size
	need_expand = p_need_expand
	lines = []
	polygons = []


func add_line(line: CellLine) -> void:
	lines.append(line)

func _to_string() -> String:
	return "ChunkSlice(size=%d, need_expand=%s, lines=%d)" % [
		size, str(need_expand), lines.size()
	]


func find_polygon(line: CellLine) -> Array[CellPoint]:
	"""
	Ищет самый короткий путь от точки line.start до точки line.end 
	по линиям, хранящимся в self.lines.
	Возвращает Array[CellPoint] – последовательность вершин, образующих путь.
	Если путь не найден, возвращает пустой массив.
	"""
	#if line.polygon_membership > 1:
		#return []

	var start_point: CellPoint = line.start
	var end_point: CellPoint = line.end
	
	# Очередь для BFS и словарь посещённых вершин
	var queue: Array = []
	var visited: Dictionary = {}        # key: CellPoint, value: bool
	# Для каждой вершины сохраняем ту линию, по которой к ней пришли
	var prev: Dictionary = {}           # key: CellPoint, value: CellLine
	queue.append(start_point)
	visited[start_point] = true
	prev[start_point] = null
	
	var last_lines: Array[CellLine] = []
	
	
	# Поиск в ширину (BFS)
	while queue.size() > 0:
		var current_point: CellPoint = queue.pop_front()
		if current_point == end_point:
			break
		# Перебираем все линии графа (self.lines – массив CellLine)
		for l: CellLine in lines:
			# Пропускаем ту же самую линию и линии, уже задействованные в полигонах
			if l.start == line.start and l.end == line.end:
				continue
			#if l.polygon_membership > 1:
				#continue
			# Граф неориентированный: рассматриваем обе вершины линии как соседей
			if current_point == l.start and not visited.has(l.end):
				visited[l.end] = true
				prev[l.end] = l
				queue.append(l.end)
			elif current_point == l.end and not visited.has(l.start):
				visited[l.start] = true
				prev[l.start] = l
				queue.append(l.start)
	
	# Если целевая вершина не достигнута, возвращаем пустой массив
	if not visited.has(end_point):
		return []
	
	# Восстанавливаем путь как последовательность вершин (CellPoint)
	var path_points: Array[CellPoint] = []
	var cur: CellPoint = end_point
	path_points.append(cur)
	while cur != start_point:
		var edge: CellLine = prev[cur]
		if edge == null:
			break
		# Отмечаем все использованные линии как принадлежащие полигону
		edge.add_polygon_membership()
		# Определяем предыдущую вершину по линии
		if edge.end == cur:
			cur = edge.start
		else:
			cur = edge.end
		path_points.append(cur)
		
	
  # Проверка порядка вершин с помощью вычисления площади (алгоритм Гаусса)
	var area: float = 0.0
	for i:int in range(path_points.size()):
		var p1: Vector2 = path_points[i].position
		var p2: Vector2 = path_points[(i+1) % path_points.size()].position
		area += p1.x * p2.y - p2.x * p1.y
	# Если площадь отрицательная, вершины идут по часовой стрелке, инвертируем порядок для получения контр-часового порядка
	if area > 0:
		path_points.reverse()
	
	return path_points
