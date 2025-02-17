# Scripts/Voronoi/worley_demo_2d.gd
extends Node2D

@export var area_width: int = 512
@export var area_height: int = 512
@export var seed_count: int = 32
@export var cell_size: int = 8

var seeds = []
var voronoi_polygons = {}  # Dictionary, где ключ – индекс семени, значение – массив точек (Vector2)

func _ready() -> void:
	randomize()
	_generate_seeds()
	
	# Загружаем скрипт с генерацией ячеек на основе Worley Noise
	var cellular_noise = preload("res://Scripts/Worley/cellular_noise.gd").new()
	voronoi_polygons = cellular_noise.generate_cells(area_width, area_height, cell_size, seeds)
	queue_redraw()

func _generate_seeds() -> void:
	seeds.clear()
	for i in range(seed_count):
		var p = Vector2(randf() * area_width, randf() * area_height)
		seeds.append(p)

func _draw() -> void:
	# Рисуем ячейки, залитые случайными цветами
	for seed_id in voronoi_polygons.keys():
		var pts = voronoi_polygons[seed_id]
		if pts.size() < 3:
			continue
		# Используем полученный контур; он уже упорядочен (выпуклая оболочка)
		var polygon = pts
		# Генерируем случайный цвет для ячейки
		var cell_color = Color(randf(), randf(), randf())
		# Заливаем многоугольник
		draw_polygon(polygon, [cell_color])
		# Отрисовываем контур для отладки
		for i in range(polygon.size()):
			var p1 = polygon[i]
			var p2 = polygon[(i + 1) % polygon.size()]
			draw_line(p1, p2, Color.GREEN, 1)
	# Рисуем семена
	for p in seeds:
		draw_circle(p, 3, Color.RED)
