# infrastructure/bootsteps/event_bus_bootstrap.gd
extends IBootstrapStep
class_name EventBusBootstrap

func execute() -> void:
	var event_bus: EventBus = EventBus.new()
	ServiceLocator.register("EventBus", event_bus)
	var log_sevice: LogService = ServiceLocator.resolve('LogService')
	log_sevice.log("EventBus initialized.")
