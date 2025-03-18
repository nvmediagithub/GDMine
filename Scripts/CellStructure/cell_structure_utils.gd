# cell_structure_utils.gd
extends RefCounted
class_name CellStructureUtils

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
