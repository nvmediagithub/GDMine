# Scripts/Voronoi/voronoi_demo_2d.gd
extends Node2D

@export var area_width: int = 256
@export var area_height: int = 256
@export var seed_count: int = 10

var seeds = []
var voronoi_polygons = {}  # Dictionary, где ключ – индекс сайта, значение – массив точек

func _ready() -> void:
    randomize()
    _generate_seeds()
    
    # Создаем экземпляр алгоритма FortuneVoronoi и задаем сайты
    var fortune = preload("res://Scripts/Voronoi/fortune_voronoi.gd").new()
    fortune.sites = seeds
    fortune.generate_voronoi()  # В нашей демонстрационной версии ничего не делает
    voronoi_polygons = fortune.get_polygons()
    queue_redraw()

func _generate_seeds() -> void:
    seeds.clear()
    for i in range(seed_count):
        var p = Vector2(randf() * area_width, randf() * area_height)
        seeds.append(p)

func _draw() -> void:
    # Рисуем сайты
    for p in seeds:
        draw_circle(p, 3, Color.RED)
    
    # Для каждой ячейки из voronoi_polygons рисуем заливку и контур
    for seed_id in voronoi_polygons.keys():
        var pts = voronoi_polygons[seed_id]
        if pts.size() < 3:
            continue
        # Можно упорядочить точки (например, через выпуклую оболочку)
        var hull = Geometry2D.convex_hull(PackedVector2Array(pts))
        var polygon = hull.duplicate()
        
        # Генерируем случайный цвет для ячейки
        var cell_color = Color(randf(), randf(), randf())
        
        # Заливаем многоугольник
        draw_polygon(polygon, [cell_color])
        
        # Рисуем контур
        for i in range(polygon.size()):
            var p1 = polygon[i]
            var p2 = polygon[(i + 1) % polygon.size()]
            draw_line(p1, p2, Color.GREEN, 1)
