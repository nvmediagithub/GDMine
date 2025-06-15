# scripts/domain/chunk_data.gd
extends Resource
class_name ChunkData

var position: Vector2i
var block_ids: Array # 3D массив: block_ids[layer_num][z][x] значения BlockType.ID
var weight_fields: Array  # 3D массив: weight_fields[layer_num][z][x] значения от 0.0 до 0.5
var dirty_layers: Dictionary[int, bool] = {}


# var position: Vector2i
# # теперь трехмерный массив block_ids[z][y][x]
# var block_ids: Array # Array of Array of PoolIntArray
# var dirty_layers: Dictionary = {}

# func _init(size_x: int = 0, size_y: int = 0, size_z: int = 0) -> void:
# 	# TODO можно упростить
#     # инициализация массивов
#     block_ids = []
#     for z: int in size_z:
#         var layer: Array = []
#         for y: int in size_y:
#             layer.append([])
#             layer[y].resize(size_x)
#         block_ids.append(layer)
#     # отметить все слои грязными
#     for y: int in size_y:
#         dirty_layers[y] = true

# func set_block(x: int, y: int, z: int, id: int) -> void:
#     if z < 0 or z >= block_ids.size(): return
#     if y < 0 or y >= block_ids[z].size(): return
#     if x < 0 or x >= block_ids[z][y].size(): return
#     block_ids[z][y][x] = id
#     dirty_layers[y] = true






# func set_value(x: int, y: int, z: int, value: float) -> void:
# 	if z >= 0 and z < field.size() and y >= 0 and y < field[z].size() and x >= 0 and x < field[z][y].size():
# 		field[z][y][x] = value