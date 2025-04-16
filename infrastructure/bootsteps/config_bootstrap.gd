extends Node
class_name ConfigBootstrap
implements IBootstrapStep

func execute() -> void:
	var config = preload("res://infrastructure/config_manager.gd").new()
	ServiceLocator.register("ConfigManager", config)
	ServiceLocator.resolve("LogService").log("Config service initialized.")
