extends Node
class_name CellStructure

# Экспортируемые параметры для настройки алгоритма
@export var initial_vector_count: int = 4         # Чётное число; например, 4 (две пары противоположных векторов)
@export var initial_length_min: float = 5.0
@export var initial_length_max: float = 10.0
@export var expansion_iterations: int = 2         # Число итераций расширения структуры
@export var connection_threshold: float = 3.0     # Расстояние для поиска "ближайшей незанятой" точки
@export var random_vector_length_min: float = 3.0
@export var random_vector_length_max: float = 6.0


var points: Array = []   # Массив Vector3, содержащий все сгенерированные точки
var edges: Array = []    # Массив словарей { "from": Vector3, "to": Vector3 } для ребер

# Запускает генерацию структуры
func generate_structure() -> void:
	points.clear()
	edges.clear()
	
	# Стартовая точка (например, в центре координат)
	var start_point = Vector3.ZERO
	points.append(start_point)
	
	_emit_initial_vectors(start_point)
	
	# Выполняем итерации расширения
	for i in range(expansion_iterations):
		_expand_points()

# Эмитируем начальные векторы из стартовой точки.
# Чтобы сумма векторов была 0, генерируем пары: один случайный вектор и его противоположность.
func _emit_initial_vectors(origin: Vector3) -> void:
	var half_count = initial_vector_count / 2
	for i in range(half_count):
		# Случайный угол
		var angle = randf() * TAU
		# Случайная длина в диапазоне
		var length = lerp(initial_length_min, initial_length_max, randf())
		var vec = Vector3(cos(angle) * length, 0, sin(angle) * length)
		# Добавляем вектор и его противоположность
		_add_point(origin, origin + vec)
		_add_point(origin, origin - vec)

# Функция, которая добавляет новую точку (если она ещё не существует с достаточной точностью)
# и записывает ребро между from_point и to_point
func _add_point(from_point: Vector3, to_point: Vector3) -> void:
	# Проверяем, есть ли уже точка близко к to_point
	var existing = null
	for p in points:
		if p.distance_to(to_point) < 0.01:
			existing = p
			break
	if existing:
		# Используем существующую точку
		to_point = existing
	else:
		points.append(to_point)
	edges.append({ "from": from_point, "to": to_point })

# Функция расширения: для каждой уже существующей точки (или для новой выборки)
# испускаем два вектора в зависимости от наличия соседней незанятой точки.
func _expand_points() -> void:
	# Для простоты обрабатываем все точки
	# (в дальнейшем можно отметить обработанные точки, чтобы не дублировать)
	var current_points = points.duplicate()
	for current_point in current_points:
		var neighbor = _find_nearest_unconnected_point(current_point)
		if neighbor:
			# Если сосед найден, генерируем вектор к нему и противоположный
			var vec = (neighbor - current_point).normalized()
			var length = lerp(random_vector_length_min, random_vector_length_max, randf())
			_add_point(current_point, current_point + vec * length)
			_add_point(current_point, current_point - vec * length)
		else:
			# Если сосед не найден, генерируем два случайных вектора, взаимно противоположных
			var angle = randf() * TAU
			var length = lerp(random_vector_length_min, random_vector_length_max, randf())
			var vec = Vector3(cos(angle) * length, 0, sin(angle) * length)
			_add_point(current_point, current_point + vec)
			_add_point(current_point, current_point - vec)
			
# Функция поиска ближайшей точки, которая не соединена с current_point (по порогу)
func _find_nearest_unconnected_point(current_point: Vector3) -> Vector3:
	var nearest = null
	var nearest_dist = INF
	# Ищем среди уже существующих точек, которые не совпадают с current_point
	for p in points:
		if p == current_point:
			continue
		# Проверяем, что между current_point и p ещё нет ребра
		if _edge_exists(current_point, p):
			continue
		var d = current_point.distance_to(p)
		if d < connection_threshold and d < nearest_dist:
			nearest = p
			nearest_dist = d
	return nearest

# Функция проверки наличия ребра между двумя точками (с учетом порядка)
func _edge_exists(p1: Vector3, p2: Vector3) -> bool:
	for edge in edges:
		if (edge["from"] == p1 and edge["to"] == p2) or (edge["from"] == p2 and edge["to"] == p1):
			return true
	return false
