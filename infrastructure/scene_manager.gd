class_name SceneManager

func _ready() -> void:
	var event_bus: EventBus = ServiceLocator.resolve('EventBus')
	event_bus.start_game.connect(_start_game_scene)

func _start_game_scene() -> void:
	print('loading test_world_scene')
