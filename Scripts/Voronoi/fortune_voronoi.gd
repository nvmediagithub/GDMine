# Основной класс алгоритма Fortune’s
class_name FortuneVoronoi

# Scripts/Voronoi/fortune_voronoi.gd
extends Node

# В данном скелете мы определяем базовые классы событий и дуг,
# но для демонстрации полного алгоритма Фортуна их реализация будет неполной.
class SiteEvent:
	var site: Vector2
	func _init(_site: Vector2):
		site = _site

class CircleEvent:
	var center: Vector2
	var y: float  # координата события (свайп-линия)
	func _init(_center: Vector2, _y: float):
		center = _center
		y = _y

class Arc:
	var site: Vector2
	func _init(_site: Vector2):
		site = _site

var sites = []      # Массив Vector2 (семена)
var edges = []      # Здесь предполагаются вычисленные края (пока не используются)
var beach_line = [] # Упрощённое представление beach line (массив Arc)
var event_queue = []# Очередь событий (SiteEvent и CircleEvent)

# Функция инициализации (в полной реализации здесь происходила бы настройка очереди)
func init_sites(_sites: Array) -> void:
	sites = _sites.duplicate()
	# Сортировка сайтов по Y, затем по X (если потребуется)
	sites.sort_custom(_compare_sites)
	event_queue.clear()
	for s in sites:
		event_queue.append(SiteEvent.new(s))
		# В полноценном алгоритме здесь бы также добавлялись circle events

# Функция сравнения для Vector2 (сайты)
func _compare_sites(a: Vector2, b: Vector2) -> int:
	if a.y == b.y:
		return -1 if a.x < b.x else 1
	return -1 if a.y < b.y else 1

# В этой демонстрационной версии мы не реализуем обработку событий.
# Вместо этого, для каждого семени мы создадим замкнутый контур – например, окружность с 10 вершинами.
func generate_voronoi() -> void:
	# Для демонстрации просто оставляем sites как они есть.
	# (В полноценном алгоритме здесь бы вызывался process_events())
	# Здесь ничего не делаем, так как get_polygons() будет сгенерирована отдельно.
	pass

# Функция, возвращающая замкнутые контуры для каждого сайта.
# Для демонстрации для каждого сайта создаём окружность с 10 вершинами.
func get_polygons() -> Dictionary:
	var polys = {}
	for i in range(sites.size()):
		var center = sites[i]
		var poly = []
		var segments = 10
		var radius = 50.0  # радиус можно сделать параметром
		for j in range(segments):
			var angle = j * (TAU / segments)
			poly.append(center + Vector2(cos(angle), sin(angle)) * radius)
		polys[i] = poly
	return polys
