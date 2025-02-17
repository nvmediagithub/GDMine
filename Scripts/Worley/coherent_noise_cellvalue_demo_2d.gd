# Scripts/Voronoi/coherent_noise_cellvalue_demo_2d.gd
extends Node2D

@export var image_width: int = 256
@export var image_height: int = 256
@export var seed_count: int = 20

var seeds = []
var seed_colors = {}   # Dictionary: ключ – индекс семени, значение – Color
var noise_sprite: Sprite2D


func _ready() -> void:
	randomize()
	_generate_seeds()
	_assign_seed_colors()
	
	$SpriteLayer.layer = 0  # Нижний слой
	$CircleLayer.layer = 1  # Верхний слой
	
	# Загружаем модуль клеточного шума
	var noise_module = preload("res://Scripts/Worley/coherent_noise_cell_value.gd").new()
	# Генерируем изображение клеточного шума
	var noise_img = noise_module.generate_cell_value_image(image_width, image_height, seeds, seed_colors)
	# Создаем текстуру из изображения
	#noise_texture = ImageTexture.new()
	#noise_texture.create_from_image(noise_img)
	var noise_texture = ImageTexture.create_from_image(noise_img)
	noise_sprite = Sprite2D.new()
	noise_sprite.texture = noise_texture
	#noise_sprite.global_position = Vector2.ZERO
	#noise_sprite.position = Vector2.ZERO
	noise_sprite.position = Vector2(128, 128)
	$SpriteLayer.add_child(noise_sprite)
	queue_redraw()

func _generate_seeds() -> void:
	seeds.clear()
	for i in range(seed_count):
		var p = Vector2(randf() * image_width, randf() * image_height)
		seeds.append(p)

# Функция присваивает каждому семени случайный цвет и сохраняет его в seed_colors
func _assign_seed_colors() -> void:
	seed_colors.clear()
	for i in range(seed_count):
		# Например, можно использовать случайный цвет
		seed_colors[i] = Color(randf(), randf(), randf())

func _draw() -> void:
	# Для отладки также рисуем семена
	for p in seeds:
		draw_circle(p, 3, Color.RED)
