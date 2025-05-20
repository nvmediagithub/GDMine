# scripts/application/world/mesh_generation_worker.gd
extends Node
class_name MeshGenerationWorker

signal mesh_generated(chunk_pos: Vector2i, layer_meshes: Dictionary)

var thread: Thread = Thread.new()
var should_stop: bool = false

func start() -> void:
	thread.start(_run)

var task_queue: Array = []
var task_mutex: Mutex = Mutex.new()

func enqueue(task: MeshGenerationTask) -> void:
	task_mutex.lock()
	task_queue.append(task)
	task_mutex.unlock()

func _run(_userdata: Variant = null) -> void:
	while not should_stop:
		task_mutex.lock()
		if task_queue.size() == 0:
			task_mutex.unlock()
			OS.delay_msec(10)
			continue
		var task: MeshGenerationTask = task_queue.pop_front()
		task_mutex.unlock()

		var result: Dictionary = {}
		for i: int in range(task.slice_count):
			if not task.chunk_data.dirty_layers[i]:
				continue
			var threshold: float = float(i) / task.slice_count
			var mesh: ArrayMesh = task.generator.call(task.chunk_data.field, threshold, i, task.cell_size, task.layer_height)
			if mesh:
				result[i] = mesh
		emit_signal("mesh_generated", task.chunk_pos, result)

func stop() -> void:
	should_stop = true
	thread.wait_to_finish()
