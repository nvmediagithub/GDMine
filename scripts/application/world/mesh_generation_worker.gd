# scripts/application/world/mesh_generation_worker.gd
extends Node
class_name MeshGenerationWorker

@warning_ignore("unused_signal")
signal mesh_generated(chunk_pos: Vector2i, layer_meshes: Dictionary)

var thread: Thread = Thread.new()
var should_stop : bool = false
var task_queue: Array = []
var task_mutex: Mutex = Mutex.new()

func start() -> void:
	print("start")
	if not thread.is_started():
		thread.start(_run)


func enqueue(task: MeshGenerationTask) -> void:
	print("Enqueued chunk for mesh gen:", task.chunk_pos)
	task_mutex.lock()
	task_queue.append(task)
	task_mutex.unlock()

func _run(_userdata: Variant = null) -> void:
	while not should_stop:
		task_mutex.lock()
		if task_queue.size() == 0:
			task_mutex.unlock()
			OS.delay_msec(5)
			continue
		var task: MeshGenerationTask = task_queue.pop_front()
		task_mutex.unlock()

		var result: Dictionary = {}

		for i: int in range(task.slice_count):
			if not task.chunk_data.dirty_layers.get(i, false):
				continue
			# теперь передаем block_ids вместо field, и убираем threshold
			var meshes: Dictionary[BlockType.ID, ArrayMesh] = task.generator.call(
				task.chunk_data.block_ids,
				i,
				task.cell_size,
				task.layer_height
			)
			if meshes:
				result[i] = meshes

		call_deferred("emit_signal", "mesh_generated", task.chunk_pos, result)


func stop() -> void:
	should_stop = true
	thread.wait_to_finish()
