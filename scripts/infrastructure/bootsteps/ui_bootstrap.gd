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
	
	# 3) Инстанцируем и регистрируем менеджер сцен
	var scene_manager: SceneManager = SceneManager.new()
	call_deferred("add_child", scene_manager)
	ServiceLocator.register("SceneManager", scene_manager)
	ServiceLocator.resolve("LogService").log("SceneManager initialized.")
