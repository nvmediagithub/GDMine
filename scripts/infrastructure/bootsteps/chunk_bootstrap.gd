extends IBootstrapStep
class_name ChunkBootstrap

func execute() -> void:
	var chunk_manager: ChunkManager = preload("res://scripts/presentation/world/chunk_manager.gd").new()
	#get_tree().get_root().add_child(chunk_manager)
	ServiceLocator.register("ChunkManager", chunk_manager)
	ServiceLocator.resolve("LogService").log("ChunkManager initialized.")
