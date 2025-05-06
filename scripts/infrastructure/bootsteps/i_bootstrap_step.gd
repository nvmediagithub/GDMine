# i_bootstrap_step.gd
# This is interface
extends Node
class_name IBootstrapStep

func execute() -> void:
	push_error("Шаг не реализует метод execute()")
