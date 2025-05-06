# config_bootstrap.gd
extends IBootstrapStep
class_name ConfigBootstrap
# TODO add implements IBootstrapStep after godot update
#implements IBootstrapStep

func execute() -> void:
	var config: ConfigManager = ConfigManager.new()
	ServiceLocator.register("ConfigManager", config)
	ServiceLocator.resolve("LogService").log("Config service initialized.")
