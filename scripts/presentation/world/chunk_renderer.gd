# scripts/presentation/world/chunk_renderer.gd
extends Node3D
class_name ChunkRenderer

func render_chunk(
	data: ChunkData,
	generator: Callable,
	cell_size: float,
	layer_height: float,
	slice_count: int
) -> void:
	get_children()[0].queue_free() # Очистить предыдущие меши и коллизии
	for i: int in range(slice_count):
		var threshold: float = float(i) / slice_count
		var mesh: ArrayMesh = generator.call(data.field, threshold, i, cell_size, layer_height)
		var instance: MeshInstance3D = MeshInstance3D.new()
		var static_body: StaticBody3D = StaticBody3D.new()
		instance.mesh = mesh
		instance.translate(
			Vector3(
				data.position.x * data.field[0].size() * cell_size,
				0,
				data.position.y * data.field.size() * cell_size
			)
		)
		static_body.add_child(instance)
		instance.create_trimesh_collision()
		add_child(static_body)
