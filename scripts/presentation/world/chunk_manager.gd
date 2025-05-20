# scripts/presentation/world/chunk_manager.gd
extends Node3D
class_name ChunkManager

@export var render_radius: int = 1  # Радиус в чанках вокруг (0,0)
@export var chunk_size: int = 32
@export var cell_size: float = 1.0
@export var layer_height: float = 1.0
@export var slice_count: int = 10
var dirty_chunks: Dictionary = {}
var mesh_generator: MeshGenerator = MeshGenerator.new()
# @export var noise: FastNoiseLite

var chunks: Dictionary = {}
var mesh_worker: MeshGenerationWorker

func _on_mesh_generated(chunk_pos: Vector2i, layer_meshes: Dictionary) -> void:
	var renderer: ChunkRenderer = find_renderer_for_chunk(chunk_pos)
	if renderer == null:
		return
	renderer.clear_layers()
	for i: int in layer_meshes:
		var mesh: ArrayMesh = layer_meshes[i]
		renderer.render_layer(i, mesh, cell_size, chunk_size)

func _ready() -> void:
	mesh_worker = MeshGenerationWorker.new()
	add_child(mesh_worker)
	mesh_worker.connect("mesh_generated", _on_mesh_generated)
	mesh_worker.start()
	
	var generator: ChunkGenerator = ChunkGenerator.new()
	generator.chunk_size = chunk_size
	generator.cell_size = cell_size
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	generator.noise = noise

	
	var terrain_editor: TerrainEditor = TerrainEditor.new()
	terrain_editor.chunk_manager = self
	terrain_editor.mesh_generator = mesh_generator
	add_child(terrain_editor)
	ServiceLocator.register("TerrainEditor", terrain_editor)
	
	for y: int in range(-render_radius, render_radius + 1):
		for x: int in range(-render_radius, render_radius + 1):
			var pos: Vector2i = Vector2i(x, y)
			if not chunks.has(pos):
				var renderer: ChunkRenderer = ChunkRenderer.new()
				renderer.chunk_pos = pos
				renderer.set_meta("chunk_pos", pos)
				add_child(renderer)
				var data: ChunkData = generator.generate_chunk(pos)
				chunks[pos] = data
				renderer.render_chunk(data, mesh_generator.generate_layer_mesh, cell_size, chunk_size, layer_height, slice_count)

func find_renderer_for_chunk(chunk_pos: Vector2i) -> ChunkRenderer:
	for child: Node in get_children():
		if child is ChunkRenderer and child.has_meta("chunk_pos") and child.get_meta("chunk_pos") == chunk_pos:
			return child
	return null
