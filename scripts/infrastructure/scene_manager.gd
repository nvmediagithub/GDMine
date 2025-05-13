# infrastructure/scene_manager.gd
extends Node
class_name SceneManager

func _ready() -> void:
	var event_bus: EventBus = ServiceLocator.resolve('EventBus')
	event_bus.start_game.connect(_start_game_scene)

func _start_game_scene() -> void:
	#get_tree().change_scene_to_file("res://scenes/test/test_world_scene.tscn")
	#get_tree().change_scene_to_file("res://scenes/test/test_chunk_manager_level.tscn")
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen/loading_screen.tscn")
	#print('loading test_world_scene')
