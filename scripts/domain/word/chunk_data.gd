# scripts/domain/word/chunk_data.gd
class_name ChunkData

var position: Vector2i
var field: Array

func set_value(x: int, y: int, value: float) -> void:
    if x >= 0 and x < field[0].size() and y >= 0 and y < field.size():
        field[y][x] = value