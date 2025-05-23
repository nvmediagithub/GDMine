# scripts\domain\world\mesh_generator.gd
extends Node
class_name MeshGenerator_old

func generate_layer_mesh(field: Array, threshold: float, layer_index: int, cell_size: float, layer_height: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y: int in range(field.size() - 1):
		for x: int in range(field[y][layer_index].size() - 1):
			var a: float = field[y][layer_index][x]
			var b: float = field[y][layer_index][x + 1]
			var c: float = field[y + 1][layer_index][x + 1]
			var d: float = field[y + 1][layer_index][x]

			var config: int = int(a > threshold) \
				| (int(b > threshold) << 1) \
				| (int(c > threshold) << 2) \
				| (int(d > threshold) << 3)
			if config == 0:
				continue

			var pB: Vector2 = interp(Vector2(x, y), Vector2(x + 1, y), a, b, threshold)
			var pR: Vector2 = interp(Vector2(x + 1, y), Vector2(x + 1, y + 1), b, c, threshold)
			var pT: Vector2 = interp(Vector2(x, y + 1), Vector2(x + 1, y + 1), d, c, threshold)
			var pL: Vector2 = interp(Vector2(x, y), Vector2(x, y + 1), a, d, threshold)

			var corners: Array = [
				{ "val": a, "pt": Vector2(x, y) },
				{ "val": b, "pt": Vector2(x + 1, y) },
				{ "val": c, "pt": Vector2(x + 1, y + 1) },
				{ "val": d, "pt": Vector2(x, y + 1) }
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
				continue

			var center: Vector2 = Vector2.ZERO
			for p: Vector2 in poly_pts:
				center += p
			center /= poly_pts.size()

			poly_pts.sort_custom(func(v1: Vector2, v2: Vector2) -> bool:
				var ang_a: float = atan2(v1.y - center.y, v1.x - center.x)
				var ang_b: float = atan2(v2.y - center.y, v2.x - center.x)
				return ang_a < ang_b
			)

			var mesh: ArrayMesh = extrude_polygon(poly_pts, layer_height, layer_index * layer_height)
			st.append_from(mesh, 0, Transform3D.IDENTITY)

	st.generate_normals()
	return st.commit()

func interp(p1: Vector2, p2: Vector2, v1: float, v2: float, threshold: float) -> Vector2:
	var t: float = 0.5 if (v2 == v1) else clamp((threshold - v1) / (v2 - v1), 0.0, 1.0)
	return p1.lerp(p2, t)


func extrude_polygon(polygon: Array, height: float, y_offset: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top_vertices: Array = []
	var bottom_vertices: Array = []

	for point: Vector2 in polygon:
		top_vertices.append(Vector3(point.x, y_offset, point.y))
		bottom_vertices.append(Vector3(point.x, y_offset - height, point.y))

	for i: int in range(1, top_vertices.size() - 1):
		st.add_vertex(top_vertices[0])
		st.add_vertex(top_vertices[i])
		st.add_vertex(top_vertices[i + 1])

	for i: int in range(1, bottom_vertices.size() - 1):
		st.add_vertex(bottom_vertices[0])
		st.add_vertex(bottom_vertices[i + 1])
		st.add_vertex(bottom_vertices[i])

	for i: int in range(polygon.size()):
		var next: int = (i + 1) % polygon.size()
		st.add_vertex(top_vertices[i])
		st.add_vertex(bottom_vertices[i])
		st.add_vertex(bottom_vertices[next])
		st.add_vertex(top_vertices[i])
		st.add_vertex(bottom_vertices[next])
		st.add_vertex(top_vertices[next])

	return st.commit()
