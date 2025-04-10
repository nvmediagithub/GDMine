class_name ServiceLocator

static var services = {}

static func register(name, instance):
    services[name] = instance

static func get(name):
    return services.get(name)
