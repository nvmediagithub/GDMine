# Scripts/Worley/coherent_noise_polygons_demo_2d.gd
extends Node2D

@export var area_width: int = 256
@export var area_height: int = 256
@export var seed_count: int = 20
@export var cell_size: int = 16

var seeds = []
var polygons = {}  # Dictionary: ключ – индекс семени, значение – массив Vector2 (контур ячейки)
var cell_colors = {}  # Словарь для случайного цвета каждой ячейки

func _ready() -> void:
	randomize()
	_generate_seeds()
	_assign_seed_colors()
	
	var noise_polygons = preload("res://Scripts/Worley/coherent_noise_polygons.gd").new()
	polygons = noise_polygons.generate_polygons(area_width, area_height, cell_size, seeds)
	
	queue_redraw()

func _generate_seeds() -> void:
	seeds.clear()
	for i in range(seed_count):
		var p = Vector2(randf() * area_width, randf() * area_height)
		seeds.append(p)

func _assign_seed_colors() -> void:
	cell_colors.clear()
	for i in range(seed_count):
		cell_colors[i] = Color(randf(), randf(), randf())

func _draw() -> void:
	
	# Отрисовываем ячейки (если есть)
	for seed_id in polygons.keys():
		var pts = polygons[seed_id]
		if pts.size() < 3:
			continue
		# Генерируем цвет для ячейки (из cell_colors)
		var cell_color = cell_colors[seed_id] if cell_colors.has(seed_id) else Color.WHITE
		draw_polygon(pts, [cell_color])
		# Рисуем контур многоугольника
		for i in range(pts.size()):
			var p1 = pts[i]
			var p2 = pts[(i + 1) % pts.size()]
			draw_line(p1, p2, Color.GREEN, 1)
	# Рисуем семена
	for p in seeds:
		draw_circle(p, 3, Color.RED)
