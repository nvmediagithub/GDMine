# infrastructure/bootsteps/ui_bootstrap.gd
extends IBootstrapStep
class_name UIBootstrap


func execute() -> void:
	# 1) Инстанцируем сцену главного меню
	var main_menu: Control = preload("res://scenes/ui/main_menu.tscn").instantiate()
	call_deferred("add_child", main_menu)
	# 2) Регистрируем контроллер через ServiceLocator
	ServiceLocator.register("MainMenu", main_menu)
	ServiceLocator.resolve("LogService").log("MainMenu initialized.")
