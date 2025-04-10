extends Node

func _ready() -> void:
	print("Main scene ready")
	var bootstrap = preload("res://infrastructure/game_bootstrap.gd").new()
	add_child(bootstrap)
	bootstrap.initialize()
