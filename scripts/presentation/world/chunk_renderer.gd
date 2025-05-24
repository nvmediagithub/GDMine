# scripts/presentation/world/chunk_renderer.gd
extends Node3D
class_name ChunkRenderer

var chunk_pos: Vector2i
var type_colors: Dictionary[BlockType.ID, Color] = {
	BlockType.ID.GRASS: Color.GREEN,
	BlockType.ID.DIRT: Color.SANDY_BROWN,
	BlockType.ID.COAL: Color.BLACK,
	BlockType.ID.STONE: Color.GRAY,
}


func render_chunk(data: ChunkData, mesh_gen: Callable, ws: WorldSettings) -> void:
	for c: Node in get_children(): c.queue_free()
	# для каждого слоя (y)
	for layer: int in range(ws.slice_count):
		if not data.dirty_layers[layer]: continue
		var layer_meshes: Dictionary[BlockType.ID, ArrayMesh] = mesh_gen.call(data.block_ids, layer, ws.cell_size, ws.layer_height)
		
		for t: BlockType.ID in layer_meshes.keys():
			var mat: StandardMaterial3D = StandardMaterial3D.new()
			mat.albedo_color = type_colors[t]
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = layer_meshes[t]
			mi.material_override = mat
			# коллизия
			var body: StaticBody3D = StaticBody3D.new()
			body.add_child(mi)
			var cs: CollisionShape3D = CollisionShape3D.new()
			cs.shape = layer_meshes[t].create_trimesh_shape()
			body.add_child(cs)
			body.translate(
				Vector3(
					chunk_pos.x*ws.chunk_size*ws.cell_size, 
					0, 
					chunk_pos.y*ws.chunk_size*ws.cell_size
				)
			)
			add_child(body)
