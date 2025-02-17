class_name CellPolygon
# Импортируем классы точек и линий (если необходимо, через preload или using, но в Godot достаточно, если они в том же пространстве имён)

var points: Array = []  # Array of CellPoint, упорядоченный обход
var lines: Array = []   # Array of CellLine

func _init(_points: Array):
	# Ожидается, что _points – массив объектов CellPoint
	points = _points.duplicate()
	_build_lines()

# Строит линии по последовательности точек, предполагая, что многоугольник замкнут
func _build_lines() -> void:
	lines.clear()
	var count = points.size()
	if count < 2:
		return
	for i in range(count):
		var next_i = (i + 1) % count
		var line = CellLine.new(points[i], points[next_i])
		lines.append(line)

# Метод для добавления новой точки и обновления линий (если требуется динамическое изменение)
func add_point(new_point: CellPoint) -> void:
	points.append(new_point)
	_build_lines()

# Дополнительно можно добавить метод для визуализации или вычисления площади и т.п.
