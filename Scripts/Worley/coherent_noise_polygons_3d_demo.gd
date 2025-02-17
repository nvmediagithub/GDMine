extends Node3D

@export var area_width: int = 256
@export var area_height: int = 256
@export var seed_count: int = 20
@export var cell_size: int = 8
@export var extrusion_height: float = 10.0

var seeds = []            # Массив Vector2 для семян
var polygons = {}         # Dictionary: ключ – индекс семени, значение – массив Vector2 (2D контур)
var cell_colors = {}      # Для визуальной дифференциации ячеек

func _ready() -> void:
	randomize()
	_generate_seeds()
	_assign_seed_colors()
	
	# Загружаем модуль генерации 2D‑контуров (убедитесь, что он находится по нужному пути)
	var poly_generator = preload("res://Scripts/Worley/coherent_noise_polygons.gd").new()
	polygons = poly_generator.generate_polygons(area_width, area_height, cell_size, seeds)
	
	_create_extruded_cells()
	
	# Опционально, добавить камеру и свет, если сцена их не содержит

func _generate_seeds() -> void:
	seeds.clear()
	for i in range(seed_count):
		var p = Vector2(randf() * area_width, randf() * area_height)
		seeds.append(p)

func _assign_seed_colors() -> void:
	cell_colors.clear()
	for i in range(seed_count):
		# Случайный яркий цвет
		cell_colors[i] = Color(randf(), randf(), randf())

# Функция, которая для каждого семени берет 2D контур и экструзирует его в 3D-меш, затем добавляет его как дочерний узел
func _create_extruded_cells() -> void:
	for seed_id in polygons.keys():
		var poly = polygons[seed_id]
		if poly.size() < 3:
			continue
		# Преобразуем 2D контур в PackedVector2Array (контур должен быть замкнутым и упорядоченным)
		var poly_array = PackedVector2Array(poly)
		# Экструзия в 3D-меш с заданной высотой
		var cell_mesh_instance = extrude_polygon(poly_array, extrusion_height)
		# Применяем материал с цветом, соответствующим семени
		var mat = StandardMaterial3D.new()
		mat.albedo_color = cell_colors[seed_id] if cell_colors.has(seed_id) else Color.WHITE
		cell_mesh_instance.material_override = mat
		# Добавляем полученный MeshInstance3D в сцену
		add_child(cell_mesh_instance)

# Функция экструзии 2D многоугольника (замкнутый контур) в 3D меш с заданной высотой
func extrude_polygon(polygon: PackedVector2Array, height: float) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var bottom = []  # Вершины нижней грани (на плоскости XZ, Y = 0)
	var top = []     # Вершины верхней грани (на плоскости XZ, Y = height)
	for p in polygon:
		# Интерпретируем 2D координаты как X и Z
		bottom.append(Vector3(p.x, 0, p.y))
		top.append(Vector3(p.x, height, p.y))
	
	# Треангуляция нижней грани с помощью Geometry2D.triangulate_polygon
	var triangles = Geometry2D.triangulate_polygon(polygon)
	# Нижняя грань: добавляем треугольники в порядке, полученном из триангуляции
	for i in range(0, triangles.size(), 3):
		st.add_vertex(bottom[triangles[i]])
		st.add_vertex(bottom[triangles[i + 1]])
		st.add_vertex(bottom[triangles[i + 2]])

	# Верхняя грань: обратный порядок для корректного направления нормалей
	for i in range(0, triangles.size(), 3):
		st.add_vertex(top[triangles[i + 2]])
		st.add_vertex(top[triangles[i + 1]])
		st.add_vertex(top[triangles[i]])
	
	# Боковые грани: для каждой пары соседних вершин контура
	for i in range(polygon.size()):
		var next_i = (i + 1) % polygon.size()
		# Первый треугольник боковой грани
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
