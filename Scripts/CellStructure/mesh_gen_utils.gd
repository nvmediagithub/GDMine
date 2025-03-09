extends RefCounted
class_name MeshGenUtils

static func create_line(start_pos: Vector3, end_pos: Vector3, color: Color) -> MeshInstance3D:
	var st: SurfaceTool = SurfaceTool.new()
	# Используем примитив для линий.
	st.begin(Mesh.PRIMITIVE_LINES)
	# Задаем цвет для обеих вершин.
	st.set_color(color)
	st.add_vertex(start_pos)
	st.add_vertex(end_pos)
	# Завершаем создание меша.
	var mesh: Mesh = st.commit()
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	var line_instance: MeshInstance3D = MeshInstance3D.new()
	line_instance.mesh = mesh
	line_instance.material_override = mat
	return line_instance

static func create_polygon_mesh(points: Array, color: Color) -> MeshInstance3D:
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
