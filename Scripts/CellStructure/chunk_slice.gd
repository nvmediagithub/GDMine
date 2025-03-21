# chunk_slice.gd
extends RefCounted
class_name ChunkSlice

# Массивы для хранения точек, линий и полигонов (если потребуется)
var lines: Array[CellLine] = []
var polygons: Array = []

func add_line(line: CellLine) -> void:
	lines.append(line)

func _to_string() -> String:
	return "ChunkSlice(lines=%d)" % [
		lines.size()
	]

	
func find_polygon(line: CellLine) -> Array[CellPoint]:
	# Массив для хранения последовательности вершин полигона
	var polygon_points: Array[CellPoint] = []
	
	# Определяем стартовую и целевую точки
	var start_point: CellPoint = line.start
	var end_point: CellPoint = line.end
	polygon_points.append(start_point)
	
	# Задаём начальное направление: от end_point к start_point
	var current_direction: Vector2 = start_point.position - end_point.position
	var current_point: CellPoint = start_point
	var visited_lines: Array[CellLine] = []
	visited_lines.append(line)
	
	# Ограничиваем число итераций, чтобы избежать бесконечного цикла
	var max_iterations: int = self.lines.size() * 5
	
	while current_point != end_point and max_iterations > 0:
		max_iterations -= 1
		# Собираем все линии, исходящие из текущей точки
		var candidates: Array = []
		for candidate_line: CellLine in self.lines:
			if candidate_line.start == current_point or candidate_line.end == current_point:
				# Пропускаем ту же самую линию и линии, уже задействованные в полигонах
				if not candidate_line in visited_lines:
					visited_lines.append(candidate_line)
					candidates.append(candidate_line)
		
		# Если из текущей точки нет ни одной линии, значит тупик
		if candidates.is_empty():
			return []
		
		# Выбираем лучшую линию по критерию угла (наибольший поворот против часовой стрелки)
		var best_line: CellLine = null
		var best_angle: float = INF
		var best_vector: Vector2 = Vector2()
		
		for candidate_line: CellLine in candidates:
			# Определяем соседнюю точку на линии candidate_line
			var neighbor: CellPoint = candidate_line.end if candidate_line.start == current_point else candidate_line.start
			# Вектор от текущей точки к соседней
			var candidate_vector: Vector2 = neighbor.position - current_point.position
			# Вычисляем подписанный угол от current_direction до candidate_vector.
			# Функция signed_angle_to возвращает угол в радианах: положительный — поворот против часовой стрелки, отрицательный — по часовой.
			var angle: float = current_direction.angle_to(candidate_vector)

			# Выбираем кандидата с максимальным углом.
			# Если поворотов против часовой нет (все отрицательные), будет выбран тот, у которого отклонение по часовой минимально.
			if angle < best_angle:
				best_angle = angle
				best_line = candidate_line
				best_vector = candidate_vector

		# Многоугольник оказался вогнутый, добавляем принудительно грань, но полигон не формируем 
		# TODO Подумать на сколько это хорошее решение
		#if best_angle >= 0:
			#return []
			
		# Если ни одного кандидата не выбрано, завершаем поиск
		if best_line == null:
			return []
			
		if best_line.polygon_membership > 1:
			return []
		
		# Обновляем текущую точку: переходим по выбранной линии к соседней точке
		var next_point: CellPoint =  best_line.end if (best_line.start == current_point) else best_line.start
		
		# Обновляем направление движения
		current_direction = best_vector
		current_point = next_point
		polygon_points.append(current_point)
		
		# Если цикл слишком длинный, возможно мы зашли в тупик – выходим с пустым результатом
		if polygon_points.size() > self.lines.size():
			return []
	
	# Если целевая точка не достигнута, возвращаем пустой массив
	if current_point != end_point:
		return []
	
	return polygon_points
