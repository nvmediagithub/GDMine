# main.gd
extends Node

func _ready() -> void:
	print("Main scene ready")
	var bootstrap: GameBootstrap = GameBootstrap.new()
	add_child(bootstrap)
