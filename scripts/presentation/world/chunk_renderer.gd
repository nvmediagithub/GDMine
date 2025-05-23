# scripts/presentation/world/chunk_renderer.gd
extends Node3D
class_name ChunkRenderer

var chunk_pos: Vector2i

func render_chunk(data: ChunkData, mesh_gen: Callable, ws: WorldSettings) -> void:
	for c: Node in get_children(): c.queue_free()
	# для каждого слоя (y)
	for layer: int in range(ws.slice_count):
		if not data.dirty_layers[layer]: continue
		var layer_meshes: Dictionary = mesh_gen.call(data.block_ids, layer, ws.cell_size, ws.layer_height)
		
		for layer_mesh: ArrayMesh in layer_meshes.values():
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = layer_mesh
			mi.translate(Vector3(chunk_pos.x*ws.chunk_size*ws.cell_size, 0, chunk_pos.y*ws.chunk_size*ws.cell_size))
			add_child(mi)
			# коллизия
			var body: StaticBody3D = StaticBody3D.new()
			body.add_child(mi)
			var cs: CollisionShape3D = CollisionShape3D.new()
			cs.shape = layer_mesh.create_trimesh_shape()
			body.add_child(cs)
			add_child(body)
