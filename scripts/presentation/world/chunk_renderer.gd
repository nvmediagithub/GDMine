# scripts/presentation/world/chunk_renderer.gd
extends Node3D
class_name ChunkRenderer

var chunk_pos: Vector2i

func _ready() -> void:
	set_meta("chunk_pos", chunk_pos)

var pending_jobs: int = 0

func _check_done() -> void:
	if pending_jobs == 0:
		# Все слои готовы
		pass

func render_chunk(
	data: ChunkData,
	generator: Callable,
	cell_size: float,
	chunk_size: int,
	layer_height: float,
	slice_count: int
) -> void:
	# Очистить предыдущие меши и коллизии
	for child: Node in get_children():
		child.queue_free()


	for i: int in range(slice_count):
		if not data.dirty_layers[i]: continue
		
		var threshold: float = float(i) / slice_count
		var mesh: ArrayMesh = generator.call(data.field, threshold, i, cell_size, layer_height)
		
		if mesh == null:
			continue  # Пропустить, если меш не создан


		var static_body: StaticBody3D = StaticBody3D.new()
		add_child(static_body)
		static_body.translate(
			Vector3(
				chunk_pos.x * chunk_size * cell_size,
				0,
				chunk_pos.y * chunk_size * cell_size
			)
		)

		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		static_body.add_child(mesh_instance)

		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
		if shape != null:
			collision_shape.shape = shape
			static_body.add_child(collision_shape)

func clear_layers() -> void:
	for child: Node in get_children():
		child.queue_free()

func render_layer(
		mesh: ArrayMesh,
		cell_size: float,
		chunk_size: int
	) -> void:
	var static_body: StaticBody3D = StaticBody3D.new()
	add_child(static_body)
	static_body.translate(
		Vector3(
			chunk_pos.x * chunk_size * cell_size, 
			0, 
			chunk_pos.y * chunk_size * cell_size
		)
	)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	static_body.add_child(mesh_instance)

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var shape: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	if shape:
		collision_shape.shape = shape
		static_body.add_child(collision_shape)
