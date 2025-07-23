# scripts/application/world/chunk_data_generator.gd
extends Node
class_name ChunkDataGenerator

@export var cave_noise: FastNoiseLite
@export var height_noise: FastNoiseLite
@export var ore_noise: FastNoiseLite


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


	
	# руды
	for y: int in range(0, slice_count):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight_1: float = ore_noise.get_noise_3d(
					pos.x * chunk_size + x,
					y,
					pos.y * chunk_size + z,
				) # Возвращает значение от -1 до 1
				weight_1 = (weight_1 + 1.0) / 2

				if weight_1 > 0.75:
					block_ids[y][z][x] = BlockType.ID.COAL
		data.dirty_layers[y] = true

	# TODO вынести параметры высоты горы в settings
	# Верхние горы
	for y: int in range(0, slice_count):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight_1: float = height_noise.get_noise_2d(
					pos.y * chunk_size + z,
					pos.x * chunk_size + x,
				) # Возвращает значение от -1 до 1
				weight_1 = (weight_1 + 1.0) / 2
				var d: float = weight_1 - float(y) / float(slice_count)
				if d > 0.05:
					if block_ids[y][z][x] != BlockType.ID.COAL:
						block_ids[y][z][x] = BlockType.ID.STONE
					weight_fields[y][z][x] = weight_1
				elif d > 0.015:
					block_ids[y][z][x] = BlockType.ID.DIRT
					weight_fields[y][z][x] = weight_1
				elif d > 0.0:
					block_ids[y][z][x] = BlockType.ID.GRASS
					weight_fields[y][z][x] = weight_1
				else:
					block_ids[y][z][x] = BlockType.ID.EMPTY
		data.dirty_layers[y] = true


	# пещеры
	for y: int in range(8, slice_count):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight_1: float = cave_noise.get_noise_3d(
					pos.x * chunk_size + x,
					y,
					pos.y * chunk_size + z,
				) # Возвращает значение от -1 до 1
				weight_1 = (weight_1 + 1.0) / 2

				if weight_1 > 0.83:
					block_ids[y][z][x] = BlockType.ID.EMPTY
					weight_fields[y][z][x] = 1.0
		data.dirty_layers[y] = true

	# # Нижние пещеры
	# for y: int in range(5, min(40, slice_count)):
	# 	for z: int in range(chunk_size + 1):
	# 		for x: int in range(chunk_size + 1):
	# 			var weight_1: float = noise.get_noise_2d(
	# 				pos.y * chunk_size + z,
	# 				pos.x * chunk_size + x,
	# 			) + 1.0 # Возвращает значение от -1 до 1
				
	# 			var weight_2: float = noise.get_noise_3d(
	# 				pos.y * chunk_size + z,
	# 				y,
	# 				pos.x * chunk_size + x,
	# 			) # Возвращает значение от -1 до 1
	# 			if weight_2 > 0.25:
	# 				if weight_1 > y * 0.10:
	# 					block_ids[y][z][x] = BlockType.ID.STONE
	# 				else:
	# 					block_ids[y][z][x] = BlockType.ID.EMPTY
	# 			elif weight_2 < -0.5:
	# 				block_ids[y][z][x] = BlockType.ID.COAL
	# 				weight_fields[y][z][x] = weight_1
	# 			else:
	# 				block_ids[y][z][x] = BlockType.ID.STONE
	# 				weight_fields[y][z][x] = weight_1
	# 	data.dirty_layers[y] = true



	# Нижний слой
	for y: int in range(1, min(5, slice_count)):
		for z: int in range(chunk_size + 1):
			for x: int in range(chunk_size + 1):
				var weight: float = height_noise.get_noise_2d(
					pos.y * chunk_size + z,
					pos.x * chunk_size + x,
				) + 1.0 # Возвращает значение от -1 до 1
				if weight > 0.5 + y * 0.25:
					block_ids[y][z][x] = BlockType.ID.BEDROCK
		data.dirty_layers[y] = true
	# Нижний слой бедрока
	data.dirty_layers[0] = true
	for z: int in range(chunk_size + 1):
		for x: int in range(chunk_size + 1):
			block_ids[0][z][x] = BlockType.ID.BEDROCK

	return data
