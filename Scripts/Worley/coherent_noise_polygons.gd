extends Node
class_name CoherentNoisePolygons

# Вспомогательная функция для вычисления углов ячейки (4 угла)
func get_cell_corners(x: int, y: int, cell_size: int) -> Array:
	# Возвращаем углы в фиксированном порядке
	return [
		Vector2(x * cell_size, y * cell_size),                               # верхний левый
		Vector2(x * cell_size + cell_size, y * cell_size),                     # верхний правый
		Vector2(x * cell_size + cell_size, y * cell_size + cell_size),           # нижний правый
		Vector2(x * cell_size, y * cell_size + cell_size)                      # нижний левый
	]

# Вспомогательная функция для удаления дублей точек с заданной точностью
func remove_duplicate_points(points: Array, epsilon: float = 0.001) -> Array:
	var unique_points = []
	for p in points:
		var is_duplicate = false
		for up in unique_points:
			if p.distance_to(up) < epsilon:
				is_duplicate = true
				break
		if not is_duplicate:
			unique_points.append(p)
	return unique_points

# Функция генерации ячеек (полигонов) на основе клеточного шума (Worley noise)
# area_width, area_height – размеры области (в пикселях)
# cell_size – шаг дискретизации (размер ячейки сетки)
# seeds – массив Vector2 с координатами семян (контрольных точек)
# Возвращает Dictionary, где ключ – индекс семени, а значение – массив Vector2,
# представляющий замкнутый контур ячейки (выпуклая оболочка набора углов ячеек, принадлежащих данному семени)
func generate_polygons(area_width: int, area_height: int, cell_size: int, seeds: Array) -> Dictionary:
	var cols = int(area_width / cell_size)
	var rows = int(area_height / cell_size)
	var grid = []  # Для каждой дискретной ячейки запишем индекс ближайшего семени

	# Заполняем сетку: для каждой ячейки находим ближайшее семя
	for x in range(cols):
		grid.append([])
		for y in range(rows):
			var pos = Vector2(x * cell_size + cell_size / 2.0, y * cell_size + cell_size / 2.0)
			var min_dist = INF
			var closest_seed = -1
			for i in range(seeds.size()):
				var d = pos.distance_to(seeds[i])
				if d < min_dist:
					min_dist = d
					closest_seed = i
			grid[x].append(closest_seed)
	
	# Инициализируем словарь для ячеек: для каждого семени создаём пустой массив точек
	var polygons = {}
	for i in range(seeds.size()):
		polygons[i] = []
	
	# Для каждой ячейки дискретной сетки получаем углы и добавляем их к соответствующему семени
	for x in range(cols):
		for y in range(rows):
			var seed_id = grid[x][y]
			if seed_id < 0:
				continue
			var corners = get_cell_corners(x, y, cell_size)
			# Добавляем все 4 угла в набор точек для данного семени
			polygons[seed_id] += corners
	
	# Удаляем дублированные точки и вычисляем выпуклую оболочку для каждого семени
	for seed_id in polygons.keys():
		var pts = remove_duplicate_points(polygons[seed_id])
		if pts.size() >= 3:
			var pts_array = PackedVector2Array(pts)
			var hull = Geometry2D.convex_hull(pts_array)
			polygons[seed_id] = hull.duplicate()
		else:
			polygons[seed_id] = []
	
	return polygons
