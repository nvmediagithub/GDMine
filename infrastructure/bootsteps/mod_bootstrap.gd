extends IBootstrapStep
class_name ModBootstrap

# TODO add implements IBootstrapStep after godot update
#implements IBootstrapStep

func execute() -> void:
	var mod_loader: ModLoader = ModLoader.new()
	mod_loader.load_mods()
	ServiceLocator.resolve("LogService").log("Mods loaded.")
