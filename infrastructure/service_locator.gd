class_name ServiceLocator

static var services: Dictionary = {}

static func register(name: String, instance: Enemy) -> void:
	services[name] = instance

static func get(name):
	return services.get(name)
