# chunk_3d.gd
extends Node3D
class_name Chunk3D

enum Status {RED, YELLOW, GREEN}
# Ссылка на объект типа ChunkSlice, который содержит линии для отрисовки
# TODO Слоев должно быть много
var slice: ChunkSlice = ChunkSlice.new()
var debug_container: Node3D = Node3D.new()
# TODO перенести полигоны в слои
var polygons: Array = []
var size: Vector3
var grid_pos: Vector2i
var status: Status = Status.RED

func _init(p_grid_pos: Vector2i, p_size: Vector3) -> void:
	grid_pos = p_grid_pos
	size = p_size

func _ready() -> void:
	add_child(debug_container)

func get_lines() -> Array[CellLine]:
	return slice.lines

func add_line(line: CellLine) -> void:
	slice.add_line(line)


func _clear_debug_container() -> void:
	# Удаляем все дочерние узлы из контейнера.
	for child: Node in debug_container.get_children():
		child.queue_free()

func create_polygons() -> void:
	# TODO требуется рефакторинг и оптимизация
	# TODO сейчас присутствуют дубли, требуется не генерировать дубли
	# TODO сейчас генерится 2 полигона за раз на 1 линию, требуется оптимизация
	for l: CellLine in slice.lines:
		var lines: Array[CellLine] = [l, CellLine.new(l.end, l.start)]
		for line: CellLine in lines:
			var poly_arr: Array = slice.find_polygon(line)
			var is_found: bool = false
			# Поиск дублей
			for i: int in range(polygons.size()):
				is_found = poly_arr.all(func(el: CellPoint) -> bool: return el in polygons[i])
				if is_found: break
			if not is_found:
				polygons.append(poly_arr)
	
func update_debug_geometry() -> void:
	_clear_debug_container()
	# Проходим по всем линиям, сохраненным в slice
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var color: Color =\
		Color(rng.randf_range(0, 1), rng.randf_range(0, 1), rng.randf_range(0, 1))
	var line_color: Color
	if status == Status.RED:
		line_color = Color(1.0, 0.0, 0.0)
	elif status == Status.YELLOW:
		line_color = Color(1.0, 1.0, 0.0)
	elif status == Status.GREEN:
		line_color = Color(0.0, 0.0, 1.0)
	else:
		line_color = Color(0.0, 1.0, 1.0)
		
	for line: CellLine in slice.lines:
		var start_pos: Vector3 =\
			Vector3(line.start.position.x, 0, line.start.position.y)
		var end_pos: Vector3 =\
			Vector3(line.end.position.x, 0, line.end.position.y)
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
		var line_instance: MeshInstance3D =\
			MeshGenUtils.create_line(start_pos, end_pos, Color(1, 0, 0))
		debug_container.add_child(line_instance)
		# Рисуем границы чанка согласно size

	# Для каждого полигона (массив CellLine) формируем набор точек и рисуем многоугольник.
	for cell_point_arr: Array[CellPoint] in polygons:
		# Например, выбираем случайный цвет для полигона.
		var poly_color: Color = Color(rng.randf(), rng.randf(), rng.randf())
		var poly_mesh: MeshInstance3D =\
			MeshGenUtils.create_polygon_mesh(cell_point_arr, poly_color)
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
		var boundary_line: MeshInstance3D =\
			MeshGenUtils.create_line(segment[0], segment[1], line_color)
		debug_container.add_child(boundary_line)
		
