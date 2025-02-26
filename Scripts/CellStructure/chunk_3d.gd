# chunk_3d.gd
extends Node3D
class_name Chunk3D

# Ссылка на объект типа ChunkSlice, который содержит линии для отрисовки
var _slice: ChunkSlice = ChunkSlice.new(1, false)
var size: Vector3 = Vector3.ONE
var debug_container: Node3D = Node3D.new()
var grid_pos: Vector2i = Vector2i.ZERO
var polygons: Array = []

func _init(p_grid_pos: Vector2i) -> void:
	grid_pos = p_grid_pos

func _ready() -> void:
	print("New chunk")
	# Создаем контейнер для отладочных узлов и добавляем его как дочерний.
	add_child(debug_container)

func need_expand() -> bool:
	return _slice.need_expand

func expand() -> void:
	_slice.need_expand = true

func get_lines() -> Array[CellLine]:
	return _slice.lines

func add_line(line: CellLine) -> void:
	_slice.add_line(line)

func set_chunk(new_chunk: ChunkSlice) -> void:
	_slice = new_chunk

func _clear_debug_container() -> void:
	# Удаляем все дочерние узлы из контейнера.
	for child: Node in debug_container.get_children():
		child.queue_free()

func create_polygons() -> void:
	# TODO требуется рефакторинг и оптимизация
	# TODO сейчас присутствуют дубли, требуется не генерировать дубли
	for line: CellLine in _slice.lines:
		var poly_arr: Array = _slice.find_polygon(line)
		var is_found: bool = false
		#for i: int in range(polygons.size()):
			#var a: Array = poly_dic['points']
			#is_found = a.all(func(el: CellPoint) -> bool: return el in polygons[i])
			#if is_found: break
		#if not is_found:
			#polygons.append(poly_dic['points'])
			#for l: CellLine in poly_dic['lines']:
				#l.add_polygon_membership()
		# Поиск дублей
		for i: int in range(polygons.size()):
			is_found = poly_arr.all(func(el: CellPoint) -> bool: return el in polygons[i])
			if is_found: break
		if not is_found:
			polygons.append(poly_arr)
	



func update_geometry() -> void:
	_clear_debug_container()
	# Проходим по всем линиям, сохраненным в slice
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var color: Color = Color(rng.randf_range(0, 1), rng.randf_range(0, 1), rng.randf_range(0, 1))
	for line: CellLine in _slice.lines:
		var start_pos: Vector3 = Vector3(line.start.position.x, 0, line.start.position.y) - position
		var end_pos: Vector3 = Vector3(line.end.position.x, 0, line.end.position.y) - position
		# Опционально: создаем отладочные узлы для проверки позиций точек.
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = color
		var start_placeholder: MeshInstance3D = MeshInstance3D.new()
		var end_placeholder: MeshInstance3D = MeshInstance3D.new()
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.025
		sphere.height = 0.05
		start_placeholder.mesh = sphere
		end_placeholder.mesh = sphere
		start_placeholder.position = start_pos
		end_placeholder.position = end_pos
		start_placeholder.material_override = mat
		end_placeholder.material_override = mat
		debug_container.add_child(start_placeholder)
		debug_container.add_child(end_placeholder)
		
		# Создаем линию между start_pos и end_pos с помощью SurfaceTool.
		var line_instance: MeshInstance3D = create_line(start_pos, end_pos, Color(1, 0, 0))
		debug_container.add_child(line_instance)
		# Рисуем границы чанка согласно size

	# Для каждого полигона (массив CellLine) формируем набор точек и рисуем многоугольник.
	for cell_point_arr: Array in polygons:
		# Например, выбираем случайный цвет для полигона.
		var poly_color: Color = Color(rng.randf(), rng.randf(), rng.randf())
		var poly_mesh: MeshInstance3D = create_polygon_mesh(cell_point_arr, poly_color)
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = poly_color
		poly_mesh.material_override = mat
		debug_container.add_child(poly_mesh)

		
		
	# Предполагаем, что границы рисуются на плоскости XZ, начиная от локального начала (0, 0, 0)
	var p0: Vector3 = Vector3(0, 0, 0)
	var p1: Vector3 = Vector3(size.x, 0, 0)
	var p2: Vector3 = Vector3(size.x, 0, size.z)
	var p3: Vector3 = Vector3(0, 0, size.z)
	
	# Создаем замкнутый контур границ
	var boundaries: Array = [
		[p0, p1],
		[p1, p2],
		[p2, p3],
		[p3, p0]
	]
	
	for segment: Array in boundaries:
		var boundary_line: MeshInstance3D = create_line(segment[0], segment[1], Color(0, 1, 0))
		debug_container.add_child(boundary_line)
		
func create_line(start_pos: Vector3, end_pos: Vector3, color: Color) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	# Используем примитив для линий.
	st.begin(Mesh.PRIMITIVE_LINES)
	# Задаем цвет для обеих вершин.
	st.set_color(color)
	st.add_vertex(start_pos)
	st.add_vertex(end_pos)
	# Завершаем создание меша.
	var mesh: Mesh = st.commit()
	var line_instance: MeshInstance3D = MeshInstance3D.new()
	line_instance.mesh = mesh
	return line_instance

func create_polygon_from_cell_lines(cell_lines: Array) -> Array:
	# Предполагаем, что линии уже отсортированы таким образом,
	# что конец одной линии совпадает с началом следующей.
	var points: Array = []
	if cell_lines.size() == 0:
		return points
	# Начинаем с начала первой линии.
	points.append(Vector2(cell_lines[0].start.position.x, cell_lines[0].start.position.y))
	# Для каждой линии добавляем конечную точку.
	for line: CellLine in cell_lines:
		points.append(Vector2(line.end.position.x, line.end.position.y))
	# Если многоугольник не замкнут, закрываем его.
	if points[0] != points[points.size() - 1]:
		points.append(points[0])
	return points

func create_polygon_mesh(points: Array, color: Color) -> MeshInstance3D:
	# Используем Geometry2D.triangulate_polygon для получения треугольников.
	var triangles: Array = Geometry2D.triangulate_polygon(points)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(color)
	# Проходим по индексам с шагом 3.
	for i: int in range(0, triangles.size(), 3):
		st.add_vertex(Vector3(points[triangles[i]].position.x, -0.05, points[triangles[i]].position.y))
		st.add_vertex(Vector3(points[triangles[i + 1]].position.x, -0.05, points[triangles[i + 1]].position.y))
		st.add_vertex(Vector3(points[triangles[i + 2]].position.x, -0.05, points[triangles[i + 2]].position.y))
	var mesh: Mesh = st.commit()
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	return mesh_instance
