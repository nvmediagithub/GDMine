extends IBootstrapStep
class_name WorldGenerationBootstrap

func execute() -> void:
	var world_generator: WorldGenerator = WorldGenerator.new()
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	world_generator.noise = noise
	ServiceLocator.register("WorldGenerator", world_generator)
	world_generator.generate()
	ServiceLocator.resolve("LogService").log("World generation completed.")
