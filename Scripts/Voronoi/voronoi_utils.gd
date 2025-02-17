extends Node

# Функция округления точки до кратного resolution
func snap_point(p: Vector2, resolution: float) -> Vector2:
	return Vector2(round(p.x / resolution) * resolution, round(p.y / resolution) * resolution)

# Функция, которая применяет snapping ко всем точкам многоугольника
func snap_polygon(polygon: Array, resolution: float) -> Array:
	var snapped = []
	for p in polygon:
		snapped.append(snap_point(p, resolution))
	return snapped

# Функция упрощения многоугольника.
# tolerance – порог упрощения
func simplify_polygon(polygon: Array, tolerance: float) -> Array:
	if polygon.size() < 3:
		return polygon
	var simplified = douglas_peucker(polygon, tolerance)
	return simplified

# Функция, которая комбинирует snapping и упрощение, а затем ограничивает количество вершин.
# max_vertices – желаемое максимальное число вершин.
func reduce_polygon(polygon: Array, snap_resolution: float, tolerance: float, max_vertices: int) -> Array:
	# Применяем snapping
	var snapped = snap_polygon(polygon, snap_resolution)
	# Упрощаем многоугольник
	var simplified = simplify_polygon(snapped, tolerance)
	# Если всё еще вершин больше, чем нужно – берем равномерно выбранные
	while simplified.size() > max_vertices:
		var temp = []
		var step = float(simplified.size()) / max_vertices
		for i in range(max_vertices):
			temp.append(simplified[int(i * step)])
		simplified = temp
	return simplified

# Функция для вычисления перпендикулярного расстояния от точки p до линии, заданной точками p1 и p2
func perpendicular_distance(p: Vector2, p1: Vector2, p2: Vector2) -> float:
	var numerator = abs((p2.y - p1.y) * p.x - (p2.x - p1.x) * p.y + p2.x * p1.y - p2.y * p1.x)
	var denominator = p1.distance_to(p2)
	return numerator / denominator

# Рекурсивная функция алгоритма Дугласа-Пекера
func douglas_peucker(points: Array, tolerance: float) -> Array:
	if points.size() < 3:
		return points

	var max_distance = 0.0
	var index = 0
	for i in range(1, points.size() - 1):
		var distance = perpendicular_distance(points[i], points[0], points[-1])
		if distance > max_distance:
			index = i
			max_distance = distance

	if max_distance > tolerance:
		var left = douglas_peucker(points.slice(0, index + 1), tolerance)
		var right = douglas_peucker(points.slice(index, points.size()), tolerance)
		return left + right.slice(1, right.size())
	else:
		return [points[0], points[-1]]
