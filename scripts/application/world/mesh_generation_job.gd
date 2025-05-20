# scripts/application/world/mesh_generation_job.gd
extends RefCounted
class_name MeshGenerationJob

var field: Array
var threshold: float
var layer_index: int
var cell_size: float
var chunk_size: int
var layer_height: float
var generator: Callable
var callback: Callable

func run() -> void:
	var mesh: ArrayMesh = generator.call(field, threshold, layer_index, cell_size, layer_height)
	call_deferred("on_complete", mesh)

func on_complete(mesh: ArrayMesh) -> void:
	callback.call(mesh, layer_index)
