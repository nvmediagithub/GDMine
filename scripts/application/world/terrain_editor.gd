# scripts/application/world/terrain_editor.gd
extends Node
class_name TerrainEditor

var chunk_manager: ChunkManager
var mesh_generator: MeshGenerator
#var chunks_to_update: Dictionary = {}

func remove_voxel(world_pos: Vector3, radius: float = 1.0) -> void:
	#chunks_to_update = {}
	
	var chunk_size: int = chunk_manager.chunk_size
	var cell_size: float = chunk_manager.cell_size
	var layer_height: float = chunk_manager.layer_height

	# Центр сферы в мировых координатах
	var center_x: float = world_pos.x
	var center_y: float = world_pos.y
	var center_z: float = world_pos.z

	# Область поиска вокруг центра
	var min_x: int = floori((center_x - radius) / cell_size)
	var max_x: int = ceili((center_x + radius) / cell_size)
	var min_y: int = floori((center_y - radius) / layer_height)
	var max_y: int = ceili((center_y + radius) / layer_height)
	var min_z: int = floori((center_z - radius) / cell_size)
	var max_z: int = ceili((center_z + radius) / cell_size)

	# Обход всех точек в пределах сферы
	for y: int in range(min_y, max_y):
		for z: int in range(min_z, max_z):
			for x: int in range(min_x, max_x):
				var dx: float = (x * cell_size - center_x)
				var dy: float = (y * layer_height - center_y)
				var dz: float = (z * cell_size - center_z)
				if dx * dx + dy * dy + dz * dz > radius * radius:
					continue

				# Мировые координаты в чанковую систему
				var chunk_pos: Vector2i = Vector2i(floori(float(x) / chunk_size), floori(float(z) / chunk_size))
				var chunk: ChunkData = chunk_manager.chunks.get(chunk_pos)
				if chunk == null:
					continue

				var local_x: int = posmod(x, chunk_size + 1)
				var local_y: int = y
				var local_z: int = posmod(z, chunk_size + 1)

				chunk.set_value(local_x, local_y, local_z, -1.0)
				chunk.dirty_layers[local_y] = true
				chunk_manager.dirty_chunks[chunk_pos] = chunk
	
	for chunk_pos: Vector2i in chunk_manager.dirty_chunks:
		var task: MeshGenerationTask = MeshGenerationTask.new()
		task.chunk_pos = chunk_pos
		task.chunk_data = chunk_manager.dirty_chunks[chunk_pos]
		task.generator = mesh_generator.generate_layer_mesh
		task.cell_size = cell_size
		task.chunk_size = chunk_size
		task.layer_height = layer_height
		task.slice_count = chunk_manager.slice_count
		chunk_manager.mesh_worker.enqueue(task)


func find_renderer_for_chunk(chunk_pos: Vector2i) -> ChunkRenderer:
	for child: Node in chunk_manager.get_children():
		if child is ChunkRenderer and child.has_meta("chunk_pos") and child.get_meta("chunk_pos") == chunk_pos:
			return child
	return null
