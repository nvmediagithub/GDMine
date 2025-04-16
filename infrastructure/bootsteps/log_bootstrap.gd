extends Node
class_name LogBootstrap
implements IBootstrapStep

func execute() -> void:
	var log_service = preload("res://infrastructure/log_service.gd").new()
	ServiceLocator.register("LogService", log_service)
	log_service.log("Log service initialized.")
