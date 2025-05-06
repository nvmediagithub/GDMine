# scripts/presentation/main_menu.gd
extends MarginContainer
class_name MainMenu

@onready var btn_play: Button    = $VBoxContainer/Play
@onready var btn_options: Button = $VBoxContainer/Options
@onready var btn_exit: Button    = $VBoxContainer/Exit


func _on_play_pressed() -> void:
	var event_bus: EventBus = ServiceLocator.resolve('EventBus')
	event_bus.emit_signal("start_game")
