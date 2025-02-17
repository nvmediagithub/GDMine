extends Node3D

@export var extrusion_height: float = 2.0

# Принимает массив Vector2, возвращает MeshInstance3D
func extrude_polygon(poly: Array) -> MeshInstance3D:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Преобразуем 2D точки в 3D (на плоскости XY, Z = 0)
	var bottom = []
	var top = []
	for p in poly:
		bottom.append(Vector3(p.x, p.y, 0))
		top.append(Vector3(p.x, p.y, extrusion_height))
	
	# Генерация меша: можно использовать алгоритм триангуляции для многоугольника
	# Для простоты используем метод Geometry.triangulate_polygon
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
	
	# Боковые грани: соединяем последовательные вершины
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
