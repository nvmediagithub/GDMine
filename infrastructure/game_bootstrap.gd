extends Node
class_name GameBootstrap

func initialize() -> void:
	print("Bootstrapping game...")
	# Пример регистрации сервисов
	var log_service = preload("res://infrastructure/log_service.gd").new()
	var config_manager = preload("res://infrastructure/config_manager.gd").new()
	var save_service = preload("res://infrastructure/save_service.gd").new()

	var locator = preload("res://infrastructure/service_locator.gd")
	locator.register("LogService", log_service)
	locator.register("ConfigManager", config_manager)
	locator.register("SaveService", save_service)

	log_service.log("Game initialized successfully.")
