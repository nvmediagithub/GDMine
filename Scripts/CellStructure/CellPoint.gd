extends RefCounted
class_name CellPoint

# Позиция точки (в 2D; можно использовать Vector3, если потребуется 3D)
var position: Vector2
# Флаг, указывающий, испустила ли эта точка векторы (например, для дальнейшей генерации)
var has_emitted: bool = false

func _init(pos: Vector2) -> void:
	print(pos)
	position = pos
