# scripts/domain/world/mesh_generation_task.gd
class_name MeshGenerationTask

var chunk_pos: Vector2i
var chunk_data: ChunkData
var generator: Callable
var cell_size: float
var chunk_size: int
var layer_height: float
var slice_count: int
