extends RefCounted
class_name CellLine

# Начало и конец линии – ссылки на объекты CellPoint
var start: CellPoint
var end: CellPoint
# Сколько полигонов (ячейки) содержит эта линия (можно использовать для оптимизации или отладки)
var polygon_membership: int = 0

func _init(start_point: CellPoint, end_point: CellPoint) -> void:
	start = start_point
	end = end_point
	
# Метод для увеличения счётчика принадлежности линии к полигону
func add_polygon_membership() -> void:
	polygon_membership += 1
