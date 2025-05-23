# scripts/application/world/chunk_generator.gd
extends Node
class_name ChunkGenerator

@export var noise: FastNoiseLite

# TODO hueta
var world_settings: WorldSettings = WorldSettings.new()

func generate_chunk(pos: Vector2i) -> ChunkData:
	# инициализация массивов: size_x = chunk_size+1, size_y = slice_count, size_z = chunk_size+1
	var chunk_size: int = world_settings.chunk_size
	var slice_count: int = world_settings.slice_count

	var data: ChunkData = ChunkData.new(
		chunk_size + 1, 
		slice_count, 
		chunk_size + 1
	)
	data.position = pos

	for z: int in range(chunk_size + 1):
		for y: int in range(slice_count):
			for x: int in range(chunk_size + 1):
				var value: float = noise.get_noise_3d(
					pos.x * chunk_size + x,
					y,
					pos.y * chunk_size + z
				)
                # решаем тип блока по порогу
				var id: BlockType.ID = BlockType.ID.GRASS
				if value > 0.6:
					id = BlockType.ID.STONE
				elif value > 0.3:
					id = BlockType.ID.DIRT
				data.set_block(x, y, z, id)
				# дополнительно: руда
				if id == BlockType.ID.STONE and noise.get_noise_3d(x, y, z) > 0.8:
					data.set_block(x, y, z, BlockType.ID.COAL)
	return data
