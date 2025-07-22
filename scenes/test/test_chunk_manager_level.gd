extends Node3D

# Управление шейдером неба и его параметрами из кода

@export var day_length: float = 30.0                               # длина дня в секундах
@export var sky_shader: Shader = preload("res://scenes/test/stylized_sky.gdshader")

# Текстуры для облаков и звёзд
@export var clouds_texture: Texture2D = load("res://scenes/test/noise.tres")
@export var clouds_distort_texture: Texture2D = load("res://scenes/test/noise.tres")
@export var clouds_noise_texture: Texture2D = load("res://scenes/test/noise.tres")
@export var stars_texture: Texture2D = load("res://scenes/test/voronoi.tres")

# Цвета градиентов (день / закат / ночь)
@export var day_bottom_color: Color = Color(0.507643, 0.828123, 0.941873)
@export var day_top_color:    Color = Color(0.505882, 0.827451, 0.941176)
@export var sunset_bottom_color: Color = Color(0.624623, 0.379458, 0.274083)
@export var sunset_top_color:    Color = Color(0.205718, 0.255085, 0.582273)
@export var night_bottom_color: Color = Color(0.129936, 0.0757987, 0.172913)
@export var night_top_color:    Color = Color(0, 0, 0)

# Горизонт
@export var horizon_color_day:    Color = Color(0.495828, 0.741677, 0.260391)
@export var horizon_color_sunset: Color = Color(0.911657, 0.235353, 0.189874)
@export var horizon_color_night:  Color = Color(0.227109, 0.00605149, 0.169566)
@export var horizon_falloff: float = 0.7

# Солнце и Луна
@export var sun_col: Color = Color(0.945993, 0.923485, 0)
@export var sun_size: float = 0.15
@export var sun_blur: float = 0.5
@export var moon_col: Color = Color(1,1,1)
@export var moon_size: float = 0.15
@export var moon_crescent_offset: float = 0.08

# Облака
@export var clouds_speed: float = 0.05
@export var clouds_scale: float = 0.15
@export var clouds_cutoff: float = 0.17
@export var clouds_fuzziness: float = 0.2
@export var clouds_main_color: Color = Color(1,1,1)
@export var clouds_edge_color: Color = Color(0.316292, 0.673882, 0.615686)

# Звёзды
@export var stars_speed: float = 0.014
@export var stars_cutoff: float = 0.925

var shader_mat: ShaderMaterial
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var light_node: DirectionalLight3D = $DirectionalLight3D

func _ready() -> void:
    # Включаем seamless для NoiseTexture2D для бесшовного тайлинга
    clouds_texture.seamless = true
    clouds_distort_texture.seamless = true
    clouds_noise_texture.seamless = true
    stars_texture.seamless = true
    # Опционально: настраиваем blend_skirt для лучшего перехода
    clouds_texture.seamless_blend_skirt = 0.1
    clouds_distort_texture.seamless_blend_skirt = 0.1
    clouds_noise_texture.seamless_blend_skirt = 0.1

    # Создаём и настраиваем ShaderMaterial
    shader_mat = ShaderMaterial.new()
    shader_mat.shader = sky_shader

    # Задаём все uniform-параметры шейдера
    shader_mat.set_shader_parameter("clouds_texture", clouds_texture)
    shader_mat.set_shader_parameter("clouds_distort_texture", clouds_distort_texture)
    shader_mat.set_shader_parameter("clouds_noise_texture", clouds_noise_texture)
    shader_mat.set_shader_parameter("stars_texture", stars_texture)

    # Градиенты дня/заката/ночи
    shader_mat.set_shader_parameter("day_bottom_color", day_bottom_color)
    shader_mat.set_shader_parameter("day_top_color", day_top_color)
    shader_mat.set_shader_parameter("sunset_bottom_color", sunset_bottom_color)
    shader_mat.set_shader_parameter("sunset_top_color", sunset_top_color)
    shader_mat.set_shader_parameter("night_bottom_color", night_bottom_color)
    shader_mat.set_shader_parameter("night_top_color", night_top_color)

    # Горизонт
    shader_mat.set_shader_parameter("horizon_color_day", horizon_color_day)
    shader_mat.set_shader_parameter("horizon_color_sunset", horizon_color_sunset)
    shader_mat.set_shader_parameter("horizon_color_night", horizon_color_night)
    shader_mat.set_shader_parameter("horizon_falloff", horizon_falloff)

    # Солнце/Луна
    shader_mat.set_shader_parameter("sun_col", sun_col)
    shader_mat.set_shader_parameter("sun_size", sun_size)
    shader_mat.set_shader_parameter("sun_blur", sun_blur)
    shader_mat.set_shader_parameter("moon_col", moon_col)
    shader_mat.set_shader_parameter("moon_size", moon_size)
    shader_mat.set_shader_parameter("moon_crescent_offset", moon_crescent_offset)

    # Облака
    shader_mat.set_shader_parameter("clouds_speed", clouds_speed)
    shader_mat.set_shader_parameter("clouds_scale", clouds_scale)
    shader_mat.set_shader_parameter("clouds_cutoff", clouds_cutoff)
    shader_mat.set_shader_parameter("clouds_fuzziness", clouds_fuzziness)
    shader_mat.set_shader_parameter("clouds_main_color", clouds_main_color)
    shader_mat.set_shader_parameter("clouds_edge_color", clouds_edge_color)

    # Звёзды
    shader_mat.set_shader_parameter("stars_speed", stars_speed)
    shader_mat.set_shader_parameter("stars_cutoff", stars_cutoff)

    # Настраиваем окружение
    var env_res: Environment = world_env.environment
    env_res.background_mode = Environment.BG_SKY
    env_res.volumetric_fog_enabled = true
    env_res.volumetric_fog_density = 0.1
    env_res.volumetric_fog_sky_affect = 0.05

    # Привязываем ShaderMaterial к Sky
    var sky_res: Sky = Sky.new()
    sky_res.sky_material = shader_mat
    env_res.sky = sky_res
    world_env.environment = env_res


func _process(delta: float) -> void:
    # Вычисляем нормализованное время суток в диапазоне [0, 1]
    var raw_norm: float = fmod(Time.get_ticks_msec() / 1000.0, day_length) / day_length

    # Устанавливаем угол солнца/ночи: 0 -> 0°, 1 -> 180°
    light_node.rotation_degrees.x = raw_norm * 360.0