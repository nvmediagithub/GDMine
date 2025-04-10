class_name ServiceLocator

static var services: Dictionary = {}

static func register(name: String, instance: Variant) -> void:
	services[name] = instance

static func resolve(name: String) -> Variant:
	return services.get(name, null)
