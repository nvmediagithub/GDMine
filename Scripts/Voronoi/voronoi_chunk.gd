extends Node3D

@export var diagram_width: int = 256      # Ширина области диаграммы в пикселях
@export var diagram_height: int = 256     # Высота области диаграммы в пикселях
@export var cell_size: int = 8            # Шаг дискретизации (размер ячейки сетки)
@export var seed_count: int = 10          # Количество семян (точек)
@export var extrusion_height: float = 2.0 # Высота экструзии 2D‑контуров в 3D

var seeds = []         # Массив Vector2 – координаты семян
var cell_ids = []      # 2D-массив: для каждой дискретной точки хранится индекс ближайшего семени
var voronoi_polygons = []  # Массив 2D-многоугольников (каждый – массив Vector2), представляющих контуры ячеек

func _ready() -> void:
	randomize()
	generate_seeds()
	generate_cell_ids()
	voronoi_polygons = extract_polygons()
	generate_chunk()

# Генерация случайных семян
func generate_seeds() -> void:
	seeds.clear()
	for i in range(seed_count):
		var p = Vector2(randf() * diagram_width, randf() * diagram_height)
		seeds.append(p)

# Заполнение cell_ids – для каждой точки сетки (с шагом cell_size) находим ближайшее семя
func generate_cell_ids() -> void:
	var cols = diagram_width / cell_size
	var rows = diagram_height / cell_size
	cell_ids.resize(cols)
	for x in range(cols):
		cell_ids[x] = []
		for y in range(rows):
			var pos = Vector2(x * cell_size, y * cell_size)
			var closest = -1
			var min_dist = INF
			for i in range(seed_count):
				var d = pos.distance_to(seeds[i])
				if d < min_dist:
					min_dist = d
					closest = i
			cell_ids[x].append(closest)

# Упрощённое извлечение контуров ячеек (упрощённая версия marching squares)
func extract_polygons() -> Array:
	var polys = []
	var cols = cell_ids.size()
	if cols == 0:
		return polys
	var rows = cell_ids[0].size()
	# Для каждого семени собираем точки, где происходит смена принадлежности
	for seed_index in range(seed_count):
		var points = []
		for x in range(cols - 1):
			for y in range(rows - 1):
				# Если хотя бы одна из 4 ячеек квадратного сегмента отличается от seed_index,
				# считаем, что это граница
				if (cell_ids[x][y] == seed_index and (cell_ids[x+1][y] != seed_index or cell_ids[x][y+1] != seed_index or cell_ids[x+1][y+1] != seed_index)):
					points.append(Vector2(x * cell_size, y * cell_size))
		if points.size() > 2:
			# Можно дополнительно упорядочить точки по углу относительно центра, чтобы получить корректный контур.
			polys.append(points)
	return polys

# Экструзия 2D-многоугольника в 3D-меш с помощью SurfaceTool
func extrude_polygon(poly: Array) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Преобразуем 2D точки в 3D: нижняя грань (Z = 0) и верхняя грань (Z = extrusion_height)
	var bottom = []
	var top = []
	for p in poly:
		bottom.append(Vector3(p.x, p.y, 0))
		top.append(Vector3(p.x, p.y, extrusion_height))
	
	# Треангуляция многоугольника
	var triangles = Geometry2D.triangulate_polygon(poly)

	# Добавляем нижнюю грань (отсчет по часовой стрелке, можно инвертировать, если нужно)
	for i in range(0, triangles.size(), 3):
		st.add_vertex(bottom[triangles[i]])
		st.add_vertex(bottom[triangles[i + 1]])
		st.add_vertex(bottom[triangles[i + 2]])
	
	# Верхняя грань (обратный порядок)
	for i in range(0, triangles.size(), 3):
		st.add_vertex(top[triangles[i + 2]])
		st.add_vertex(top[triangles[i + 1]])
		st.add_vertex(top[triangles[i]])
	
	# Боковые грани
	for i in range(poly.size()):
		var next_i = (i + 1) % poly.size()
		# Первый треугольник
		st.add_vertex(bottom[i])
		st.add_vertex(bottom[next_i])
		st.add_vertex(top[i])
		# Второй треугольник
		st.add_vertex(bottom[next_i])
		st.add_vertex(top[next_i])
		st.add_vertex(top[i])
	
	var mesh = st.commit()
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	return mi

# Генерация чанка: для каждого многоугольника, полученного из диаграммы Вороного,
# создаём 3D-объект (MeshInstance3D) и добавляем его в качестве дочернего узла
func generate_chunk() -> void:
	# Удаляем старых потомков (если есть)
	for child in get_children():
		child.queue_free()
	
	for poly in voronoi_polygons:
		var cell_mesh_instance = extrude_polygon(poly)
		add_child(cell_mesh_instance)
