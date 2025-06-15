extends Node
class_name MeshGenerator

const EDGE_VERTS: Array[Array] = [
	[Vector2(0, 0), Vector2(1, 0)],
	[Vector2(1, 0), Vector2(1, 1)],
	[Vector2(1, 1), Vector2(0, 1)],
	[Vector2(0, 1), Vector2(0, 0)],
]

const MS_TABLE: Dictionary[int, Array] = {
	0: [],
	1: [3, 0],
	2: [0, 1],
	3: [3, 1],
	4: [1, 2],
	5: [3, 0, 1, 2], # ambiguous
	6: [0, 2],
	7: [3, 2],
	8: [2, 3],
	9: [0, 2],
	10: [0, 1, 2, 3], # ambiguous
	11: [1, 2],
	12: [1, 3],
	13: [0, 1],
	14: [3, 0],
	15: []
}

func generate_layer_mesh(
		weight_fields: Array, # 3D массив: weight_fields[layer_num][z][x] значения от 0.0 до 0.5
		block_ids: Array, # 3D массив: block_ids[layer_num][z][x] значения BlockType.ID
		layer: int,
		layer_height: float
) -> Dictionary[BlockType.ID, ArrayMesh]:
	var threshold: float = 0.5
	var meshes: Dictionary[BlockType.ID, ArrayMesh] = {}
	var surface_tools: Dictionary = {}

	# Создать SurfaceTool для каждого существующего типа
	# TODO Не создавать SurfaceTool для типов которые отсутствуют в сетке
	for block_id: BlockType.ID in BlockType.ID.values():
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tools[block_id] = st


	# проверим, что слой существует
	if layer < 0 or layer >= weight_fields.size():
		print('выход за границы')
		return meshes
	
	var weight_2d: Array[Array] = weight_fields[layer]
	var blocks_2d: Array[Array] = block_ids[layer]

	for x: int in range(weight_2d.size() - 1):
		for z: int in range(weight_2d.size() - 1):
			var block_id: BlockType.ID = blocks_2d[z][x]
			if block_id == BlockType.ID.EMPTY:
				continue
			var a: float = 1.0 - weight_2d[z][x]
			var b: float = weight_2d[z][x + 1]
			var c: float = weight_2d[z + 1][x + 1]
			var d: float = weight_2d[z + 1][x]

			if blocks_2d[z][x + 1] == block_id:
				b = 1 - b
			if blocks_2d[z + 1][x + 1] == block_id:
				c = 1 - c
			if blocks_2d[z + 1][x] == block_id:
				d = 1 - d

			# если все четыре плотности нулевые, пропустить
			if a <= 0 and b <= 0 and c <= 0 and d <= 0:
				continue
			# конвертация в биты
			var va: bool = a > threshold
			var vb: bool = b > threshold
			var vc: bool = c > threshold
			var vd: bool = d > threshold
			var config: int = int(va) | (int(vb) << 1) | (int(vc) << 2) | (int(vd) << 3)
			var pts: Array[Vector2] = []
			if config == 15:
				# полный квад
				pts = [
					Vector2(x, z),
					Vector2(x + 1, z),
					Vector2(x + 1, z + 1),
					Vector2(x, z + 1)
				]
			else:
				if not MS_TABLE.has(config):
					continue
				for edge: int in MS_TABLE[config]:
					var p1: Vector2 = EDGE_VERTS[edge][0]
					var p2: Vector2 = EDGE_VERTS[edge][1]
					var v1: float = _vertex_val(p1, a, b, c, d)
					var v2: float = _vertex_val(p2, a, b, c, d)
					var ip: Vector2 = _interp(p1, p2, v1, v2, threshold)
					pts.append(Vector2(x, z) + ip)
				# добавляем углы ячейки, у которых плотность > threshold
				if va: pts.append(Vector2(x, z))
				if vb: pts.append(Vector2(x + 1, z))
				if vc: pts.append(Vector2(x + 1, z + 1))
				if vd: pts.append(Vector2(x, z + 1))
				
			if pts.size() < 3:
				continue
			# сортировка по углу
			var center: Vector2 = Vector2.ZERO
			for p: Vector2 in pts:
				center += p
			center /= pts.size()
			pts.sort_custom(func(v1: Vector2, v2: Vector2) -> bool: 
				return atan2(v1.y - center.y, v1.x - center.x) < atan2(v2.y - center.y, v2.x - center.x)
			)
			# экструзия и добавление вершин
			var layer_y: float = layer * layer_height
			var mesh2d: ArrayMesh = extrude_polygon(pts, layer_height, layer_y)
			surface_tools[blocks_2d[z][x]].append_from(mesh2d, 0, Transform3D.IDENTITY)


	# # Для каждого блока создаём меш слоя
	# for block_id: BlockType.ID in field.keys():
	# 	var density3d: Array[Array] = field[block_id]
	# 	# проверим, что слой существует
	# 	if layer < 0 or layer >= density3d.size():
	# 		print('выход за границы')
	# 		continue
		
	# 	var layer_2d: Array[Array] = density3d[layer]

	# 	for x: int in range(layer_2d.size() - 1):
	# 		var row0: Array = layer_2d[x]
	# 		# var row1: Array = layer_2d[z + 1]
	# 		for z: int in range(row0.size() - 1):
	# 			var a: float = density3d[layer][z][x]
	# 			var b: float = density3d[layer][z][x + 1]
	# 			var c: float = density3d[layer][z + 1][x + 1]
	# 			var d: float = density3d[layer][z + 1][x]
	# 			# если все четыре плотности нулевые, пропустить
	# 			if a <= 0 and b <= 0 and c <= 0 and d <= 0:
	# 				continue
	# 			# конвертация в биты
	# 			var va: bool = a > threshold
	# 			var vb: bool = b > threshold
	# 			var vc: bool = c > threshold
	# 			var vd: bool = d > threshold
	# 			var config: int = int(va) | (int(vb) << 1) | (int(vc) << 2) | (int(vd) << 3)
	# 			var pts: Array[Vector2] = []
	# 			if config == 15:
	# 				# полный квад
	# 				pts = [
	# 					Vector2(x, z),
	# 					Vector2(x + 1, z),
	# 					Vector2(x + 1, z + 1),
	# 					Vector2(x, z + 1)
	# 				]
	# 			else:
	# 				if not MS_TABLE.has(config):
	# 					continue
	# 				for edge: int in MS_TABLE[config]:
	# 					var p1: Vector2 = EDGE_VERTS[edge][0]
	# 					var p2: Vector2 = EDGE_VERTS[edge][1]
	# 					var v1: float = _vertex_val(p1, a, b, c, d)
	# 					var v2: float = _vertex_val(p2, a, b, c, d)
	# 					var ip: Vector2 = _interp(p1, p2, v1, v2, threshold)
	# 					pts.append(Vector2(x, z) + ip)
	# 				# **добавляем углы ячейки, у которых плотность > threshold**
	# 				if va: pts.append(Vector2(x,   z))
	# 				if vb: pts.append(Vector2(x+1, z))
	# 				if vc: pts.append(Vector2(x+1, z+1))
	# 				if vd: pts.append(Vector2(x,   z+1))
					
	# 			if pts.size() < 3:
	# 				continue
	# 			# сортировка по углу
	# 			var center: Vector2 = Vector2.ZERO
	# 			for p: Vector2 in pts:
	# 				center += p
	# 			center /= pts.size()
	# 			pts.sort_custom(func(v1: Vector2, v2: Vector2) -> bool: 
	# 				return atan2(v1.y - center.y, v1.x - center.x) < atan2(v2.y - center.y, v2.x - center.x)
	# 			)
	# 			# экструзия и добавление вершин
	# 			var layer_y: float = layer * layer_height
	# 			var mesh2d: ArrayMesh = extrude_polygon(pts, layer_height, layer_y)
	# 			surface_tools[block_id].append_from(mesh2d, 0, Transform3D.IDENTITY)

	# Коммит инструментов в ArrayMesh
	for block_id: BlockType.ID in surface_tools.keys():
		var st: SurfaceTool = surface_tools[block_id]
		st.generate_normals()
		meshes[block_id] = st.commit()

	return meshes

func _vertex_val(pos: Vector2, a: float, b: float, c: float, d: float) -> float:
	if pos == Vector2(0, 0): return a
	if pos == Vector2(1, 0): return b
	if pos == Vector2(1, 1): return c
	if pos == Vector2(0, 1): return d
	return 0.0

func _interp(p1: Vector2, p2: Vector2, v1: float, v2: float, thr: float) -> Vector2:
	var t: float = 0.5 if (v1 == v2) else clamp((thr - v1) / (v2 - v1), 0.0, 1.0)
	return p1.lerp(p2, t)

func extrude_polygon(polygon: Array[Vector2], height: float, y_off: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Array[Vector3] = []
	var bot: Array[Vector3] = []
	for pt: Vector2 in polygon:
		top.append(Vector3(pt.x, y_off,     pt.y))
		bot.append(Vector3(pt.x, y_off - height, pt.y))
	# верх
	for i: int in range(1, top.size() - 1):
		st.add_vertex(top[0]); st.add_vertex(top[i]); st.add_vertex(top[i+1])
	# низ
	for i: int in range(1, bot.size() - 1):
		st.add_vertex(bot[0]); st.add_vertex(bot[i+1]); st.add_vertex(bot[i])
	# стороны
	for i: int in range(polygon.size()):
		var ni: int = (i + 1) % polygon.size()
		st.add_vertex(top[i])
		st.add_vertex(bot[i])
		st.add_vertex(bot[ni])
		st.add_vertex(top[i])
		st.add_vertex(bot[ni])
		st.add_vertex(top[ni])
	return st.commit()
