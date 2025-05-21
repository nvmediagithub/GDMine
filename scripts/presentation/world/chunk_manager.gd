# scripts/presentation/world/chunk_manager.gd
extends Node3D
class_name ChunkManager

# TODO возможно стоит перенести в ServiceLocator
@onready var world_settings: WorldSettings = WorldSettings.new()

var dirty_chunks: Dictionary = {}
var chunks: Dictionary = {}
var mesh_worker: MeshGenerationWorker
var mesh_generator: MeshGenerator
var render_radius: int = 1

func _ready() -> void:
	# 1. TODO возможно стоит перенести в DI или ServiceLocator
	mesh_generator = MeshGenerator.new()
	mesh_worker = MeshGenerationWorker.new()
	add_child(mesh_worker)
	mesh_worker.start()
	mesh_worker.connect("mesh_generated", _on_mesh_generated)

	var terrain_editor: TerrainEditor = TerrainEditor.new()
	terrain_editor.chunk_manager = self
	terrain_editor.mesh_generator = mesh_generator
	add_child(terrain_editor)
	ServiceLocator.register("TerrainEditor", terrain_editor)

	# 2. Init generator
	var generator: ChunkGenerator = ChunkGenerator.new()
	generator.noise = FastNoiseLite.new()
	generator.noise.frequency = 0.02

	# 3. Init world
	for y: int in range(-render_radius, render_radius + 1):
		for x: int in range(-render_radius, render_radius + 1):
			var pos: Vector2i = Vector2i(x, y)
			if not chunks.has(pos):
				var renderer: ChunkRenderer = ChunkRenderer.new()
				renderer.chunk_pos = pos
				add_child(renderer)
				var data: ChunkData = generator.generate_chunk(pos)
				chunks[pos] = data
				renderer.render_chunk(
					data, 
					mesh_generator.generate_layer_mesh, 
					world_settings.cell_size, 
					world_settings.chunk_size, 
					world_settings.layer_height, 
					world_settings.slice_count
				)

func _on_mesh_generated(chunk_pos: Vector2i, layer_meshes: Dictionary) -> void:
	var renderer: ChunkRenderer = find_renderer_for_chunk(chunk_pos)
	if renderer:
		renderer.clear_layers()
		for i: int in layer_meshes:
			renderer.render_layer(
				layer_meshes[i], 
				world_settings.cell_size, 
				world_settings.chunk_size
			)

func find_renderer_for_chunk(chunk_pos: Vector2i) -> ChunkRenderer:
	for child: Node in get_children():
		if child is ChunkRenderer and child.chunk_pos == chunk_pos:
			return child
	return null
