extends Node
class_name GameBootstrap

func initialize() -> void:
	print("Bootstrapping game...")
	
	# Пример регистрации сервисов
	var log_service: LogService = LogService.new()
	var config_manager: ConfigManager = ConfigManager.new()
	var save_service: SaveService = SaveService.new()
#
	ServiceLocator.register("LogService", log_service)
	ServiceLocator.register("ConfigManager", config_manager)
	ServiceLocator.register("SaveService", save_service)

	log_service.log("Game initialized successfully.")
