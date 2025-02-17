# chunk_slice.gd
extends RefCounted
class_name ChunkSlice

# Параметры чанка: координаты верхнего левого угла, размеры, флаг загрузки и позиция в сетке (например, Vector2)
var size: int
var need_expand: bool = true
var grid_pos: Vector2

# Массивы для хранения точек, линий и полигонов (если потребуется)
var points: Array[CellPoint] = []
var lines: Array[CellLine] = []

func _init(p_size: int, p_need_expand: bool, p_grid_pos: Vector2) -> void:
	size = p_size
	need_expand = p_need_expand
	grid_pos = p_grid_pos
	points = []
	lines = []

# Метод для проверки, принадлежит ли точка чанку (используются только x и y)
func contains(point) -> bool:
	# Ожидается, что у point есть свойство "position", которое является Vector2
	var pos: Vector2 = point.position
	# Используем стандартную семантику: левая и верхняя границы включаются, правая и нижняя — нет
	return pos.x >= grid_pos.x and pos.x < (grid_pos.x + size) and pos.y >= grid_pos.y and pos.y < (grid_pos.y + size)

func add_point(point) -> void:
	points.append(point)

func add_line(line) -> void:
	lines.append(line)

func _to_string() -> String:
	return "ChunkSlice(size=%d, need_expand=%s, grid_pos=%s, points=%d, lines=%d)" % [
		size, str(need_expand), str(grid_pos), points.size(), lines.size()
	]
