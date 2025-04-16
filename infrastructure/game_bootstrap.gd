extends Node
class_name GameBootstrap

var steps: Array = []

func _ready() -> void:
	register_core_steps()
	run_steps()

func register_core_steps() -> void:
	steps.append(preload("res://infrastructure/bootsteps/log_bootstrap.gd").new())
	steps.append(preload("res://infrastructure/bootsteps/config_bootstrap.gd").new())
	steps.append(preload("res://infrastructure/bootsteps/mod_bootstrap.gd").new())

func run_steps() -> void:
	for step: Variant in steps:
		step.execute()
