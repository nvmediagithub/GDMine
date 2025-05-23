# scripts/domain/word/world_generator.gd
# TODO outdated
extends Node3D
class_name WorldGenerator

@export var map_width: int = 100
@export var map_height: int = 100
@export var cell_size: float = 0.5
@export var noise: FastNoiseLite
@export var slice_count: int = 1
@export var layer_height: float = 1.0

func _ready() -> void:
	var field: Array = generate_noise_field()
	for i: int in slice_count:
		var threshold: float = float(i) / slice_count
		var mesh: ArrayMesh = generate_layer_mesh(field, threshold, i)
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		add_child(mesh_instance)


func generate_noise_field() -> Array:
	var field: Array = []
	for y: int in range(map_height + 1):
		var row: Array = []
		for x: int in range(map_width + 1):
			var value: float = noise.get_noise_2d(x, y)
			row.append(value)
		field.append(row)
	return field	


func generate_layer_mesh(field: Array, threshold: float, layer_index: int) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for y: int in range(map_height):
		for x: int in range(map_width):
			var a: float = field[y][x]
			var b: float = field[y][x + 1]
			var c: float = field[y + 1][x + 1]
			var d: float = field[y + 1][x]
			var config: int = int(a > threshold) \
					   | (int(b > threshold) << 1) \
					   | (int(c > threshold) << 2) \
					   | (int(d > threshold) << 3)
			if config == 0:
				continue  # Пропускаем пустые или полностью заполненные клетки

			var inv_y0: int = map_height - y
			var inv_y1: int = map_height - y - 1

			var pB: Vector2 = interp(Vector2(x, inv_y0), Vector2(x + 1, inv_y0), a, b, threshold)
			var pR: Vector2 = interp(Vector2(x + 1, inv_y0), Vector2(x + 1, inv_y1), b, c, threshold)
			var pT: Vector2 = interp(Vector2(x, inv_y1), Vector2(x + 1, inv_y1), d, c, threshold)
			var pL: Vector2 = interp(Vector2(x, inv_y0), Vector2(x, inv_y1), a, d, threshold)

			var corners: Array = [
				{ "val": a, "pt": Vector2(x, inv_y0) },
				{ "val": b, "pt": Vector2(x + 1, inv_y0) },
				{ "val": c, "pt": Vector2(x + 1, inv_y1) },
				{ "val": d, "pt": Vector2(x, inv_y1) }
			]
			var poly_pts: Array = []
			for item: Dictionary in corners:
				if item["val"] > threshold:
					poly_pts.append(item["pt"] * cell_size)

			if (a > threshold) != (b > threshold):
				poly_pts.append(pB * cell_size)
			if (b > threshold) != (c > threshold):
				poly_pts.append(pR * cell_size)
			if (c > threshold) != (d > threshold):
				poly_pts.append(pT * cell_size)
			if (d > threshold) != (a > threshold):
				poly_pts.append(pL * cell_size)

			if poly_pts.size() < 3:
				continue  # нечего заполнять
			var center: Vector2 = Vector2.ZERO
			for p: Vector2 in poly_pts:
				center += p
			center /= poly_pts.size()

			poly_pts.sort_custom(func(v1: Vector2, v2: Vector2) -> bool:
				var ang_a: float = atan2(v1.y - center.y, v1.x - center.x)
				var ang_b: float = atan2(v2.y - center.y, v2.x - center.x)
				return ang_a < ang_b
			)
			
			# Экструзия полигона
			var mesh: ArrayMesh = extrude_polygon(poly_pts, layer_height, layer_index * layer_height)
			st.append_from(mesh, 0, Transform3D.IDENTITY)
			
	st.generate_normals()
	return st.commit()

func interp(p1: Vector2, p2: Vector2, v1: float, v2: float, threshold: float) -> Vector2:
	var t: float = 0.5 if (v2 == v1) else clamp((threshold - v1) / (v2 - v1), 0.0, 1.0)
	return p1.lerp(p2, t)

func extrude_polygon(polygon: Array, height: float, y_offset: float) -> ArrayMesh:
	var st : SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top_vertices: Array = []
	var bottom_vertices: Array  = []

	# Создание верхней и нижней поверхностей
	for point: Vector2 in polygon:
		top_vertices.append(Vector3(point.x, y_offset, point.y))
		bottom_vertices.append(Vector3(point.x, y_offset - height, point.y))

	# Добавление верхней поверхности
	for i: int in range(1, top_vertices.size() - 1):
		st.add_vertex(top_vertices[0])
		st.add_vertex(top_vertices[i])
		st.add_vertex(top_vertices[i + 1])

	# Добавление нижней поверхности
	for i: int in range(1, bottom_vertices.size() - 1):
		st.add_vertex(bottom_vertices[0])
		st.add_vertex(bottom_vertices[i + 1])
		st.add_vertex(bottom_vertices[i])

	# Добавление боковых граней
	for i: int in range(polygon.size()):
		var next: int = (i + 1) % polygon.size()
		st.add_vertex(top_vertices[i])
		st.add_vertex(bottom_vertices[i])
		st.add_vertex(bottom_vertices[next])

		st.add_vertex(top_vertices[i])
		st.add_vertex(bottom_vertices[next])
		st.add_vertex(top_vertices[next])

	return st.commit()
