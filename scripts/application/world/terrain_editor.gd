# scripts/application/world/terrain_editor.gd
extends Node
class_name TerrainEditor

var chunk_manager: ChunkManager
var mesh_generator: MeshGenerator
var world_settings: WorldSettings = WorldSettings.new()

func remove_voxel(world_pos: Vector3, radius: float = 1.0) -> void:
	var chunk_size: int = world_settings.chunk_size
	var cell_size: float = world_settings.cell_size
	var layer_height: float = world_settings.layer_height

	var center_x: float = world_pos.x
	var center_y: float = world_pos.y
	var center_z: float = world_pos.z

	var min_x: int = floori((center_x - radius) / cell_size)
	var max_x: int = ceili((center_x + radius) / cell_size)
	var min_y: int = floori((center_y - radius) / layer_height)
	var max_y: int = ceili((center_y + radius) / layer_height)
	var min_z: int = floori((center_z - radius) / cell_size)
	var max_z: int = ceili((center_z + radius) / cell_size)

	for y: int in range(min_y, max_y):
		for z: int in range(min_z, max_z):
			for x: int in range(min_x, max_x):
				var dx: float = (x * cell_size - center_x)
				var dy: float = (y * layer_height - center_y)
				var dz: float = (z * cell_size - center_z)
				if dx * dx + dy * dy + dz * dz > radius * radius:
					continue

				# Обрабатываем до 4 чанков, в которых может находиться воксель на границе
				for offset_x: int in [0, -1]:
					for offset_z: int in [0, -1]:
						var chunk_x: int = floori((x + offset_x) / float(chunk_size))
						var chunk_z: int = floori((z + offset_z) / float(chunk_size))
						var chunk_pos: Vector2i = Vector2i(chunk_x, chunk_z)

						var local_x: int = x - chunk_x * chunk_size
						var local_z: int = z - chunk_z * chunk_size

						if local_x < 0 or local_x >= chunk_size + 1:
							continue
						if local_z < 0 or local_z >= chunk_size + 1:
							continue
						if y < 0 or y >= world_settings.slice_count:
							continue

						var chunk: ChunkData = chunk_manager.chunks.get(chunk_pos)
						if chunk == null:
							continue

						chunk.set_block(local_x, y, local_z, 0)
						chunk.dirty_layers[y] = true
						chunk_manager.dirty_chunks[chunk_pos] = chunk

	# Запускаем пересборку затронутых чанков
	for chunk_pos: Vector2i in chunk_manager.dirty_chunks:
		var task: MeshGenerationTask = MeshGenerationTask.new()
		task.chunk_pos = chunk_pos
		task.chunk_data = chunk_manager.dirty_chunks[chunk_pos]
		task.generator = mesh_generator.generate_layer_mesh
		task.cell_size = cell_size
		task.chunk_size = chunk_size
		task.layer_height = layer_height
		task.slice_count = world_settings.slice_count
		chunk_manager.mesh_worker.enqueue(task)
