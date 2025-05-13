# scripts/application/world/chunk_generator.gd
extends Node
class_name ChunkGenerator

@export var chunk_size: int = 32
@export var cell_size: float = 0.5
@export var noise: FastNoiseLite

func generate_chunk(position: Vector2i) -> ChunkData:
	var field: Array = []
	for y: int in range(chunk_size + 1):
		var row: Array = []
		for x: int in range(chunk_size + 1):
			var world_x: int = position.x * chunk_size + x
			var world_y: int = position.y * chunk_size + y
			var value: float = noise.get_noise_2d(world_x, world_y)
			row.append(value)
		field.append(row)

	var data: ChunkData = ChunkData.new()
	data.position = position
	data.field = field
	return data
