# cell_structure_utils.gd
extends RefCounted
class_name CellStructureUtils

static func calculate_angle(start: Vector2, end: Vector2) -> float:
	# Вычисление угла в радианах
	var dx: float = end.x - start.x
	var dy: float = end.y - start.y
	return atan2(dy, dx)

static func generate_child_rays(
		start_point: CellPoint, 
		base_direction: float, 
		child_count: int = 2,
		min_length: float = 1, 
		max_length: float = 2,
		max_deviation: float = PI
	) -> Array[CellPoint]:
	"""
	Генерирует child_count лучей из start_point.
	Направление каждого луча основывается на base_direction (в радианах) с отклонением не более max_deviation.

	Возвращает список лучей, где каждый луч представлен как список [start_point, end_point],
	а end_point – объект CellPoint с целочисленными координатами.
	"""
	if child_count == 0:
		return []
	var points: Array[CellPoint] = []
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var base_step: float = max_deviation * 2 / child_count
	var deviation_limit: float = base_step / 6
	for n: int in range(child_count):
		# Вычисляем случайное отклонение
		var deviation: float =\
			rng.randf_range(
					-max_deviation + base_step * n + deviation_limit, 
					-max_deviation + base_step * (n + 1) - deviation_limit
				)
		var new_angle: float = base_direction + deviation
		# Выбираем случайную длину луча
		var length: float = rng.randf_range(min_length, max_length)
		var dx: float  = cos(new_angle) * length
		var dy: float = sin(new_angle) * length
		# Вычисляем координаты конечной точки и округляем до целых чисел
		var new_x: float = start_point.position.x + dx
		var new_y: float = start_point.position.y + dy
		var end_point: CellPoint = CellPoint.new(Vector2(new_x, new_y))
		points.append(end_point)
	return points


static func line_intersection(p1: Vector2, p2: Vector2, p3: Vector2, p4: Vector2, tol: float = 1e-6) -> CellPoint:
	"""
	Вычисляет точку пересечения двух отрезков (p1, p2) и (p3, p4) с учетом допуска tol.
	p1, p2, p3, p4 – объекты Vector2, представляющие концы отрезков.
	Возвращает Vector2 с координатами точки пересечения, если отрезки пересекаются, иначе null.
	"""

	if (p1 - p3).length() < tol or (p1 - p4).length() < tol:
		return null
		
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
