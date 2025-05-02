extends IBootstrapStep
class_name LogBootstrap

# TODO add implements IBootstrapStep after godot update
#implements IBootstrapStep

func execute() -> void:
	var log_service: LogService = LogService.new()
	ServiceLocator.register("LogService", log_service)
	log_service.log("Log service initialized.")
