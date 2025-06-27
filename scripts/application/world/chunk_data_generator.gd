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
				weight_row[x] = noise.get_noise_3d(
					pos.y * chunk_size + z,
					y,
					pos.x * chunk_size + x,
				) # Возвращает значение от -1 до 1
				weight_row[x] = (weight_row[x] + 1.0) / 2
				if weight_row[x] > 0.7:
					block_row[x] = BlockType.ID.DIRT
				elif weight_row[x] > 0.6:
					block_row[x] = BlockType.ID.GRASS
				elif weight_row[x] > 0.4:
					block_row[x] = BlockType.ID.STONE
				elif weight_row[x] > 0.2:
					block_row[x] = BlockType.ID.COAL
				else:
					block_row[x] = BlockType.ID.EMPTY

					
			weight_slice[z] = weight_row
			block_slice[z] = block_row
		weight_fields[y] = weight_slice
		block_ids[y] = block_slice
		data.dirty_layers[y] = true
	data.weight_fields = weight_fields
	data.block_ids = block_ids
	
	# var dirt_field: Array[Array] = []
	# dirt_field.resize(slice_count)
	# for y: int in range(slice_count):
	# 	var material_layer: Array[Array] = []
	# 	material_layer.resize(chunk_size + 1)
	# 	for z: int in range(chunk_size + 1):
	# 		var row: Array[float] = []
	# 		row.resize(chunk_size + 1)
	# 		for x: int in range(chunk_size + 1):
	# 			row[x] = noise.get_noise_3d(
	# 				pos.y * chunk_size + z,
	# 				y,
	# 				pos.x * chunk_size + x,
	# 			) # Возвращает значение от -1 до 1
	# 			# row[x] = (row[x] + 1.0) * 0.5
	# 		material_layer[z] = row
	# 	dirt_field[y] = material_layer
	# 	data.dirty_layers[y] = true
	# data.field[BlockType.ID.DIRT] = dirt_field


	# var grass_field: Array[Array] = []
	# grass_field.resize(slice_count)
	# for y: int in range(slice_count):
	# 	var material_layer: Array[Array] = []
	# 	material_layer.resize(chunk_size + 1)
	# 	for z: int in range(chunk_size + 1):
	# 		var row: Array[float] = []
	# 		row.resize(chunk_size + 1)
	# 		for x: int in range(chunk_size + 1):
	# 			row[x] = data.field[BlockType.ID.DIRT][y][z][x]
	# 			# data.field[BlockType.ID.DIRT][y][z][x] *= 0.8
	# 			# row[x] -= data.field[BlockType.ID.DIRT][y][z][x]
	# 			if y < slice_count - 1:
	# 				if data.field[BlockType.ID.DIRT][y + 1][z][x] <= 0.0:
	# 					if data.field[BlockType.ID.DIRT][y][z][x] >= 0:
	# 						data.field[BlockType.ID.DIRT][y][z][x] *= -1.0
	# 				else:
	# 					if row[x] >= 0:
	# 						row[x] *= -1.0
	# 			else:
	# 				if data.field[BlockType.ID.DIRT][y][z][x] >= 0:
	# 					data.field[BlockType.ID.DIRT][y][z][x] *= -1.0

	# 		material_layer[z] = row
	# 	grass_field[y] = material_layer
	# 	data.dirty_layers[y] = true
	# data.field[BlockType.ID.GRASS] = grass_field


	return data



# func generate_chunk(pos: Vector2i) -> ChunkData:
# 	# инициализация массивов: size_x = chunk_size+1, size_y = slice_count, size_z = chunk_size+1
# 	var chunk_size: int = world_settings.chunk_size
# 	var slice_count: int = world_settings.slice_count

# 	var data: ChunkData = ChunkData.new(
# 		slice_count, 
# 		chunk_size + 1
# 	)
# 	data.position = pos

# 	for z: int in range(chunk_size + 1):
# 		for y: int in range(slice_count):
# 			for x: int in range(chunk_size + 1):
# 				var value: float = noise.get_noise_3d(
# 					pos.x * chunk_size + x,
# 					y,
# 					pos.y * chunk_size + z
# 				)
# 				# решаем тип блока по порогу
# 				var id: BlockType.ID = BlockType.ID.EMPTY
# 				if value > 0.3:
# 					id = BlockType.ID.GRASS
# 				elif value > 0.2:
# 					id = BlockType.ID.STONE
# 				elif value > 0.1:
# 					id = BlockType.ID.DIRT
# 				data.set_block(x, y, z, id)
# 				# дополнительно: руда
# 				if id == BlockType.ID.STONE and noise.get_noise_3d(x, y, z) > 0.8:
# 					data.set_block(x, y, z, BlockType.ID.COAL)
# 	return data
