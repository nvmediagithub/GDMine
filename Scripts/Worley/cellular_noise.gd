# Scripts/Voronoi/cellular_noise.gd
extends Node
class_name CellularNoise

# Функция генерации ячеек.
# area_width, area_height – размеры области (в пикселях)
# cell_size – шаг дискретизации (размер ячейки сетки)
# seeds – массив Vector2 с координатами семян
# Возвращает Dictionary, где ключ – индекс семени, а значение – массив Vector2, представляющий замкнутый контур ячейки.
func generate_cells(area_width: int, area_height: int, cell_size: int, seeds: Array) -> Dictionary:
	var cols = int(area_width / cell_size)
	var rows = int(area_height / cell_size)
	var grid = []
	# Заполняем сетку: для каждой ячейки находим ближайшее семя
	for x in range(cols):
		grid.append([])
		for y in range(rows):
			# Используем центр ячейки для расчёта расстояния
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
	
	# Извлекаем граничные точки: если хотя бы один сосед (в 8-окрестности) имеет другой seed, то текущая ячейка считается граничной.
	for x in range(cols):
		for y in range(rows):
			var seed_id = grid[x][y]
			var is_boundary = false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var nx = x + dx
					var ny = y + dy
					if nx < 0 or nx >= cols or ny < 0 or ny >= rows:
						is_boundary = true
					elif grid[nx][ny] != seed_id:
						is_boundary = true
			if is_boundary:
				var pt = Vector2(x * cell_size + cell_size / 2.0, y * cell_size + cell_size / 2.0)
				polygons[seed_id].append(pt)
	
	# Для каждой ячейки упрощаем форму, вычисляя выпуклую оболочку,
	# чтобы итоговый контур имел меньше точек (около 10)
	for seed_id in polygons.keys():
		if polygons[seed_id].size() >= 3:
			var pts_array = PackedVector2Array(polygons[seed_id])
			var hull = Geometry2D.convex_hull(pts_array)
			polygons[seed_id] = hull.duplicate()
	return polygons
