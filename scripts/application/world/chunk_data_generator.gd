# scripts/application/world/chunk_data_generator.gd
extends Node
class_name ChunkDataGenerator

@export var noise: FastNoiseLite

# TODO hueta
var world_settings: WorldSettings = WorldSettings.new()


# TODO Добавить генерацию других материалов
# TODO можно оптимизировать
# TODO помечать путые массивы
func generate_chunk(pos: Vector2i) -> ChunkData:
	var chunk_size: int = world_settings.chunk_size
	var slice_count: int = world_settings.slice_count

	var data: ChunkData = ChunkData.new()
	data.position = pos

	var weight_fields: Array[Array] = []
	var block_ids: Array[Array] = []

	weight_fields.resize(slice_count)
	block_ids.resize(slice_count)

	for y: int in range(slice_count):
		var weight_slice: Array[Array] = []
		var block_slice: Array[Array] = []
		weight_slice.resize(chunk_size + 1)
		block_slice.resize(chunk_size + 1)
		for z: int in range(chunk_size + 1):
			var weight_row: Array[float] = []
			var block_row: Array[BlockType.ID] = []
			weight_row.resize(chunk_size + 1)
			block_row.resize(chunk_size + 1)
			for x: int in range(chunk_size + 1):
				block_row[x] = BlockType.ID.EMPTY
				weight_row[x] = 1.0
			weight_slice[z] = weight_row
			block_slice[z] = block_row
		weight_fields[y] = weight_slice
		block_ids[y] = block_slice
		data.dirty_layers[y] = false
	data.weight_fields = weight_fields
	data.block_ids = block_ids
	
	# Нижний слой бедрока
	data.dirty_layers[0] = true
	for z: int in range(chunk_size + 1):
		for x: int in range(chunk_size + 1):
			block_ids[0][z][x] = BlockType.ID.BEDROCK
			weight_fields[0][z][x] = 1.0

	# Нижний слой
	for y: int in range(1, min(5, slice_count)):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight: float = noise.get_noise_2d(
					pos.y * chunk_size + z,
					pos.x * chunk_size + x,
				) + 1.0 # Возвращает значение от -1 до 1
				if weight > 0.5 + y * 0.25:
					block_ids[y][z][x] = BlockType.ID.BEDROCK
				else:
					block_ids[y][z][x] = BlockType.ID.STONE
				weight_fields[y][z][x] = weight
		data.dirty_layers[y] = true

	# Нижние пещеры
	for y: int in range(5, min(40, slice_count)):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight_1: float = noise.get_noise_2d(
					pos.y * chunk_size + z,
					pos.x * chunk_size + x,
				) + 1.0 # Возвращает значение от -1 до 1
				
				var weight_2: float = noise.get_noise_3d(
					pos.y * chunk_size + z,
					y,
					pos.x * chunk_size + x,
				) # Возвращает значение от -1 до 1
				if weight_2 > 0.25:
					if weight_1 > y * 0.10:
						block_ids[y][z][x] = BlockType.ID.STONE
					else:
						block_ids[y][z][x] = BlockType.ID.EMPTY
				elif weight_2 < -0.5:
					block_ids[y][z][x] = BlockType.ID.COAL
					weight_fields[y][z][x] = weight_1
				else:
					block_ids[y][z][x] = BlockType.ID.STONE
					weight_fields[y][z][x] = weight_1
		data.dirty_layers[y] = true


	# Верхние горы
	for y: int in range(40, min(60, slice_count)):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight_1: float = noise.get_noise_2d(
					pos.y * chunk_size + z,
					pos.x * chunk_size + x,
				) + 1.0 # Возвращает значение от -1 до 1
				if weight_1 > y * 0.05:
					block_ids[y][z][x] = BlockType.ID.STONE
					weight_fields[y][z][x] = weight_1
				else:
					block_ids[y][z][x] = BlockType.ID.EMPTY
		data.dirty_layers[y] = true


	return data
