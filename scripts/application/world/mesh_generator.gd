extends Node
class_name MeshGenerator

func generate_layer_mesh(block_ids: Array, layer: int, cell_size: float, layer_height: float) -> Dictionary:
	# Словарь { block_type: ArrayMesh }
	var meshes: Dictionary = {}

	# Шаг 1: собрать все уникальные типы блоков
	var types: Dictionary = {}
	for y: int in range(block_ids.size()):
		for x: int in range(block_ids[y][layer].size()):
			var block_type: int = block_ids[y][layer][x]
			if block_type != 0:
				types[block_type] = true

	# Шаг 2: создать SurfaceTool для каждого типа
	var surface_tools: Dictionary = {}
	for t: int in types.keys():
		var st: SurfaceTool= SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tools[t] = st

	# Шаг 3: применить marching squares к каждому типу
	for y: int in range(block_ids.size() - 1):
		for x: int in range(block_ids[y][layer].size() - 1):
			var a: int = block_ids[y][layer][x]
			var b: int = block_ids[y][layer][x + 1]
			var c: int = block_ids[y + 1][layer][x + 1]
			var d: int = block_ids[y + 1][layer][x]

			# Пропускаем ячейки, если они все пустые
			if a == 0 and b == 0 and c == 0 and d == 0:
				continue

			# Найдём наиболее частый тип блока среди четырёх (простой приоритет)
			var block_type: int = max(a, b, c, d)
			if block_type == 0:
				continue

			var threshold: float = 0.1  # произвольный, тк работаем с целыми id, это просто логика
			var val_a: float = float(a != 0)
			var val_b: float = float(b != 0)
			var val_c: float = float(c != 0)
			var val_d: float = float(d != 0)

			var config: int = int(val_a > threshold) \
				| (int(val_b > threshold) << 1) \
				| (int(val_c > threshold) << 2) \
				| (int(val_d > threshold) << 3)

			if config == 0:
				continue

			var pB: Vector2 = interp(Vector2(x, y), Vector2(x + 1, y), val_a, val_b, threshold)
			var pR: Vector2 = interp(Vector2(x + 1, y), Vector2(x + 1, y + 1), val_b, val_c, threshold)
			var pT: Vector2 = interp(Vector2(x, y + 1), Vector2(x + 1, y + 1), val_d, val_c, threshold)
			var pL: Vector2 = interp(Vector2(x, y), Vector2(x, y + 1), val_a, val_d, threshold)

			var corners: Array = [
				{ "val": val_a, "pt": Vector2(x, y) },
				{ "val": val_b, "pt": Vector2(x + 1, y) },
				{ "val": val_c, "pt": Vector2(x + 1, y + 1) },
				{ "val": val_d, "pt": Vector2(x, y + 1) }
			]

			var poly_pts: Array = []
			for item: Dictionary in corners:
				if item["val"] > threshold:
					poly_pts.append(item["pt"] * cell_size)

			if (val_a > threshold) != (val_b > threshold):
				poly_pts.append(pB * cell_size)
			if (val_b > threshold) != (val_c > threshold):
				poly_pts.append(pR * cell_size)
			if (val_c > threshold) != (val_d > threshold):
				poly_pts.append(pT * cell_size)
			if (val_d > threshold) != (val_a > threshold):
				poly_pts.append(pL * cell_size)

			if poly_pts.size() < 3:
				continue

			var center: Vector2 = Vector2.ZERO
			for p: Vector2 in poly_pts:
				center += p
			center /= poly_pts.size()

			poly_pts.sort_custom(func(_a: Vector2, _b: Vector2) -> float:
				return atan2(_a.y - center.y, _a.x - center.x) < atan2(_b.y - center.y, _b.x - center.x)
			)

			var mesh: ArrayMesh = extrude_polygon(poly_pts, layer_height, layer * layer_height)
			surface_tools[block_type].append_from(mesh, 0, Transform3D.IDENTITY)

	# Шаг 4: создать финальные меши
	for t: int in surface_tools:
		surface_tools[t].generate_normals()
		meshes[t] = surface_tools[t].commit()

	return meshes


func interp(p1: Vector2, p2: Vector2, v1: float, v2: float, threshold: float) -> Vector2:
	var t: float = 0.5 if v2 == v1 else clamp((threshold - v1) / (v2 - v1), 0.0, 1.0)
	return p1.lerp(p2, t)


func extrude_polygon(polygon: Array, height: float, y_offset: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top : Array = []
	var bottom : Array= []

	for point: Vector2 in polygon:
		top.append(Vector3(point.x, y_offset, point.y))
		bottom.append(Vector3(point.x, y_offset - height, point.y))

	for i: int in range(1, top.size() - 1):
		st.add_vertex(top[0])
		st.add_vertex(top[i])
		st.add_vertex(top[i + 1])

	for i: int in range(1, bottom.size() - 1):
		st.add_vertex(bottom[0])
		st.add_vertex(bottom[i + 1])
		st.add_vertex(bottom[i])

	for i: int in range(polygon.size()):
		var next: int = (i + 1) % polygon.size()
		st.add_vertex(top[i])
		st.add_vertex(bottom[i])
		st.add_vertex(bottom[next])
		st.add_vertex(top[i])
		st.add_vertex(bottom[next])
		st.add_vertex(top[next])

	return st.commit()
