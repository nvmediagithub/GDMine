# scripts/application/world/chunk_generator.gd
extends Node
class_name ChunkGenerator

@export var noise: FastNoiseLite

# TODO hueta
var world_settings: WorldSettings = WorldSettings.new()

func generate_chunk(position: Vector2i) -> ChunkData:
	var field: Array = []
	for z: int in range(world_settings.chunk_size + 1):
		var layer: Array = []
		for y: int in range(world_settings.slice_count + 1):
			var row: Array = []
			for x: int in range(world_settings.chunk_size + 1):
				var world_x: float = position.x * world_settings.chunk_size + x
				var world_y: float = y
				var world_z: float = position.y * world_settings.chunk_size + z
				var value: float = noise.get_noise_3d(world_x, world_y, world_z)
				row.append(value)
			layer.append(row)
		field.append(layer)

	var data: ChunkData = ChunkData.new()
	data.position = position
	data.field = field
	data.dirty_layers.resize(world_settings.slice_count)
	data.dirty_layers.fill(true)
	return data
