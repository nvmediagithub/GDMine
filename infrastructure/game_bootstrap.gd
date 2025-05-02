# infrastructure/game_bootstrap.gd
extends Node
class_name GameBootstrap

var steps: Array[IBootstrapStep] = []

func _ready() -> void:
	register_core_steps()
	run_steps()

func register_core_steps() -> void:
	steps.append(LogBootstrap.new())
	steps.append(ConfigBootstrap.new())
	steps.append(EventBusBootstrap.new())
	
	var ui_bootstrap: UIBootstrap = UIBootstrap.new()
	add_child(ui_bootstrap);
	steps.append(ui_bootstrap)
	
	steps.append(WorldGenerationBootstrap.new())
	steps.append(ModBootstrap.new())
	
func run_steps() -> void:
	for step: IBootstrapStep in steps:
		step.execute()
