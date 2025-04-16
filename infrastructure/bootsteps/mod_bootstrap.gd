extends Node
class_name ModBootstrap
implements IBootstrapStep

func execute() -> void:
	var mod_loader = preload("res://infrastructure/mod_loader.gd").new()
	mod_loader.load_mods()
	ServiceLocator.resolve("LogService").log("Mods loaded.")
