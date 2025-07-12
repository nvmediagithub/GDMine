# Сценовый скрипт (например, прикреплён к корню сцены)
extends Node3D

# Цвета неба
@export var day_length: float = 30.0                               # длина полного цикла в секундах
@export var sky_top_gradient: Gradient = Gradient.new()            # цвет неба в зените
@export var sky_horizon_gradient: Gradient = Gradient.new()        # цвет у горизонта
@export var light_color_gradient: Gradient = Gradient.new()        # цвет DirectionalLight3D
@export var light_energy_curve: Curve = Curve.new()                # яркость света в зависимости от времени
@export var sky_energy_curve: Curve = Curve.new()                  # яркость градиента неба по времени
@export var sun_angle_max: float = 30.0                            # угол диска солнца
@export var sun_curve: float = 0.15                                # сглаживание края солнца

var sky_mat: ProceduralSkyMaterial
var light_node: DirectionalLight3D
var world_env: WorldEnvironment

func _ready() -> void:
	for i: int in range(sky_top_gradient.get_point_count() - 1, -1, -1):
		sky_top_gradient.remove_point(i)
	sky_top_gradient.add_point(0.0, Color(0.05, 0.05, 0.2))   # тёмно-синий рассвет
	sky_top_gradient.add_point(0.5, Color(0.2, 0.6, 1.0))     # голубое небо днём
	sky_top_gradient.add_point(0.8, Color(0.1, 0.0, 0.2))     # фиолетовый закат
	sky_top_gradient.add_point(1.0, Color(0.05, 0.05, 0.2))   # тёмно-синий рассвет


	for i: int in range(sky_horizon_gradient.get_point_count() - 1, -1, -1):
		sky_horizon_gradient.remove_point(i)
	sky_horizon_gradient.add_point(0.0, Color(0.8, 0.4, 0.2))
	sky_horizon_gradient.add_point(0.5, Color(1.0, 0.8, 0.5))
	sky_horizon_gradient.add_point(0.8, Color(0.05, 0.02, 0.1))
	sky_horizon_gradient.add_point(1.0, Color(0.8, 0.4, 0.2))

	light_energy_curve.clear_points()
	light_energy_curve.add_point(Vector2(0.0, 0.2))
	light_energy_curve.add_point(Vector2(0.4, 1.0))   # начало убывания
	light_energy_curve.add_point(Vector2(0.6, 0.8))   # полумрак
	light_energy_curve.add_point(Vector2(0.8, 0.4))   # почти ночь
	light_energy_curve.add_point(Vector2(1.0, 0.2))
	light_energy_curve.bake() # Ускоряем запросы sample()
	
	for i: int in range(light_color_gradient.get_point_count() - 1, -1, -1):
		light_color_gradient.remove_point(i)
	light_color_gradient.add_point(0.0, Color(0.2, 0.2, 0.6))   # ранний рассвет / поздний закат
	light_color_gradient.add_point(0.25, Color(1.0, 0.95, 0.8)) # утро
	light_color_gradient.add_point(0.5, Color(1.0, 1.0, 1.0))   # полдень
	light_color_gradient.add_point(0.75, Color(1.0, 0.9, 0.7))  # вечер
	light_color_gradient.add_point(1.0, Color(0.2, 0.2, 0.6))   # закат / ранняя ночь

	sky_energy_curve.clear_points()
	sky_energy_curve.add_point(Vector2(0.0, 0.1))   # ночь — почти не видно
	sky_energy_curve.add_point(Vector2(0.2, 0.6))   # рассвет тусклый
	sky_energy_curve.add_point(Vector2(0.5, 1.0))   # день — полная яркость
	sky_energy_curve.add_point(Vector2(0.8, 0.6))   # закат
	sky_energy_curve.add_point(Vector2(1.0, 0.1))   # ночь
	sky_energy_curve.bake()

	# 1) Получаем ссылки на узлы
	world_env = $WorldEnvironment                             # узел WorldEnvironment
	light_node = $DirectionalLight3D                          # источник «солнца»

	# 2) Создаём ProceduralSkyMaterial и задаём статичные параметры
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max         = sun_angle_max
	sky_mat.sun_curve             = sun_curve
	# Начальная установка цветов будет в _process()

	# 3) Привязываем sky_mat к окружению
	var env_res: Environment = world_env.environment
	env_res.background_mode = Environment.BG_SKY               # включаем отрисовку неба
	env_res.volumetric_fog_enabled = true                           # объёмный fog
	env_res.volumetric_fog_density = 0.1                           # базовая плотность
	env_res.volumetric_fog_sky_affect = 0.05                         # туман чуть затмевает небо



	var sky_res: Sky = Sky.new()
	sky_res.sky_material = sky_mat
	env_res.sky = sky_res
	world_env.environment = env_res


func _process(delta: float) -> void:
	# 1) Нормируем время от 0.0 до 1.0, используя OS.get_ticks_msec()
	var t_norm: float = fmod(Time.get_ticks_msec() / 1000.0, day_length) / day_length
	
	# 2) Вращаем DirectionalLight3D: от восхода (-90°) до заката (270°)
	light_node.rotation_degrees.x = lerp(-90.0, 270.0, t_norm)                 # поворот солнца

	# 3) Обновляем цвет неба из Gradient
	sky_mat.sky_top_color     = sky_top_gradient.sample(t_norm)
	sky_mat.sky_horizon_color = sky_horizon_gradient.sample(t_norm)

	# 4) Обновляем параметры солнца через DirectionalLight3D
	light_node.light_color  = light_color_gradient.sample(t_norm)
	light_node.light_energy = light_energy_curve.sample(t_norm)

	# 5) Регулируем яркость неба
	sky_mat.sky_energy_multiplier = sky_energy_curve.sample(t_norm)
