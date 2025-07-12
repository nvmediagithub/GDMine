extends Node3D

# Путь к AnimationTree (узел должен быть дочерним)
@onready var animation_tree: AnimationTree = $AnimationTree
# Получаем плейбак StateMachine
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")


# Методы-переходы для стейт-машины
func idle() -> void:
    state_machine.travel("Idle")
func move() -> void:
    state_machine.travel("Move")
func fall() -> void:
    state_machine.travel("Fall")
func jump() -> void:
    state_machine.travel("Jump")

