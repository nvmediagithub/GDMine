# scripts/domain/word/chunk_data.gd
class_name ChunkData

var position: Vector2i
var field: Array  # 3D массив: field[z][y][x]
var dirty_layers: Array[bool] = []

func set_value(x: int, y: int, z: int, value: float) -> void:
	if z >= 0 and z < field.size() and y >= 0 and y < field[z].size() and x >= 0 and x < field[z][y].size():
		field[z][y][x] = value
