# scripts/application/world/chunk_generator.gd
extends Node
class_name ChunkGenerator

@export var chunk_size: int = 32
@export var cell_size: float = 1.0
@export var height: int = 32  # Высота чанка
@export var noise: FastNoiseLite
@export var layers_count: int = 10

func generate_chunk(position: Vector2i) -> ChunkData:
	var field: Array = []
	for z: int in range(height + 1):
		var layer: Array = []
		for y: int in range(chunk_size + 1):
			var row: Array = []
			for x: int in range(chunk_size + 1):
				var world_x: float = position.x * chunk_size + x
				var world_y: float = y
				var world_z: float = position.y * chunk_size + z
				var value: float = noise.get_noise_3d(world_x, world_y, world_z)
				row.append(value)
			layer.append(row)
		field.append(layer)

	var data: ChunkData = ChunkData.new()
	data.position = position
	data.field = field
	data.dirty_layers.resize(layers_count)
	data.dirty_layers.fill(true)
	return data
