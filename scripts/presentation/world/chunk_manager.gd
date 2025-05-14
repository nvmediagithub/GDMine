# scripts/presentation/world/chunk_manager.gd
extends Node3D
class_name ChunkManager

@export var render_radius: int = 1  # Радиус в чанках вокруг (0,0)
@export var chunk_size: int = 32
@export var cell_size: float = 0.5
@export var layer_height: float = 1.0
@export var slice_count: int = 10
@export var noise: FastNoiseLite

var chunks: Dictionary = {}

func _ready() -> void:
	var generator: ChunkGenerator = ChunkGenerator.new()
	generator.chunk_size = chunk_size
	generator.cell_size = cell_size
	generator.noise = noise

	var mesh_generator: MeshGenerator = MeshGenerator.new()
	var renderer: ChunkRenderer = ChunkRenderer.new()
	add_child(renderer)

	for y: int in range(-render_radius, render_radius + 1):
		for x: int in range(-render_radius, render_radius + 1):
			var pos: Vector2i = Vector2i(x, y)
			if not chunks.has(pos):
				var data: ChunkData = generator.generate_chunk(pos)
				chunks[pos] = data
				renderer.render_chunk(data, mesh_generator.generate_layer_mesh, cell_size, layer_height, slice_count)
