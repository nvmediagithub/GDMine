extends Node
class_name MeshGenerator


# Конфигурация многотиповой таблицы
const T: int = 4  # число состояний в каждой точке
# Вершины квадрата
const POINTS: Dictionary[int, Vector2] = {
	0: Vector2(0, 0),
	1: Vector2(1, 0),
	2: Vector2(1, 1),
	3: Vector2(0, 1),
}
# Рёбра: (индекс вершины a, индекс вершины b)
const EDGES: Dictionary[int, Vector2i] = {
	0: Vector2i(0, 1),  # верх
	1: Vector2i(1, 2),  # право
	2: Vector2i(2, 3),  # низ
	3: Vector2i(3, 0),  # лево
}

# Веерная триангуляция списка вершин poly.
func fan_tris(poly: Array) -> Array:
	var res: Array = []
	for i: int in range(1, poly.size() - 1):
		var triangle: Array = [poly[0], poly[i], poly[i+1]]
		res.append(triangle)
		pass
	return res

func build_multitype_table() -> Dictionary[int, Dictionary]:
	"""
	Генерирует таблицу из T^4 кейсов,
	где каждый кейс — словарь:
	{ 0: [...tris], 1: [...], …, T-1: [...], 'aband': [...] }
	"""
	var table: Dictionary[int, Dictionary] = {}
	
	# Четырёхкратный вложенный цикл вместо itertools.product
	for v0: int in range(T):
		for v1: int in range(T):
			for v2: int in range(T):
				for v3: int in range(T):
					var vals: Array = [v0, v1, v2, v3]
					# Индекс случая: sum(vals[i] * (T ** i))
					var case_idx: int = vals[0] \
						+ vals[1] * T \
						+ vals[2] * T * T \
						+ vals[3] * T * T * T

					# Инициализация подтаблиц
					var subtables: Dictionary = {}
					for t: int in range(T):
						subtables[t] = []
					subtables["aband"] = []

					# Обработка каждого типа t
					for t: int in range(T):
						# Собираем ребра, где значение в вершинах отличается и одно из них == t
						var segs: Array = []
						for e_key: int in EDGES.keys():
							var pair: Vector2i = EDGES[e_key]  # массив из двух индексов вершин
							if (vals[pair[0]] == t) != (vals[pair[1]] == t):
								segs.append(e_key)

						# Случай сплошной области
						if segs.is_empty():
							var all_eq: bool = true
							for v: int in vals:
								if v != t:
									all_eq = false
									break
							if all_eq:
								subtables[t] = [
									[ ["p", 0], ["p", 1], ["p", 2] ],
									[ ["p", 0], ["p", 2], ["p", 3] ]
								]
						# Случай 2 или 3 пересечения
						elif segs.size() in [2, 3]:
							var poly: Array = []
							for i: int in range(4):
								if segs.has(i):
									poly.append(["e", i])
								var nxt: int = (i + 1) % 4
								if vals[nxt] == t:
									poly.append(["p", nxt])
							if poly.size() >= 3:
								subtables[t] = fan_tris(poly)
						# Спорные области (>3 пересечений)
						else:
							var tris: Array = []
							# Треугольники по вершинам
							for ci: int in range(4):
								if vals[ci] == t:
									var rel: Array = []
									for e_key: int in segs:
										var pr: Vector2i = EDGES[e_key]
										if pr[0] == ci or pr[1] == ci:
											rel.append(e_key)
									if rel.size() == 2:
										if ci != 0:
											tris.append([ ["p", ci], ["e", rel[1]], ["e", rel[0]] ])
										else:
											tris.append([ ["p", ci], ["e", rel[0]], ["e", rel[1]] ])
							# Центр спора
							var center: Array = []
							for e_key: int in segs:
								center.append(["e", e_key])
							tris += fan_tris(center)
							subtables[t] = tris

					# Формирование 'aband' (пояс)
					var all_segs: Array = []
					for t: int in range(T):
						var local_segs: Array = []
						for e_key: int in EDGES.keys():
							var pr: Vector2i = EDGES[e_key]
							if (vals[pr[0]] == t) != (vals[pr[1]] == t):
								local_segs.append(e_key)
						for e_key: int in local_segs:
							if not all_segs.has(e_key):
								all_segs.append(e_key)
					all_segs.sort()
					var band: Array = []
					for e_key: int in all_segs:
						band.append(["e", e_key])
					if band.size() >= 3:
						subtables["aband"] = fan_tris(band)

					table[case_idx] = subtables

	return table


func interp(p1: Vector2, p2: Vector2, w1: float, w2: float) -> Vector2:
	var total: float = w1 + w2
	var t: float = 0.5 if total == 0 else w1/total
	return Vector2(
		p1[0] + t * (p2[0] - p1[0]),
		p1[1] + t * (p2[1] - p1[1])
	)

func vertex_val(pos: Vector2, a: float, b: float, c: float, d: float) -> float:
	if pos == Vector2(0, 0): return a
	if pos == Vector2(1, 0): return b
	if pos == Vector2(1, 1): return c
	if pos == Vector2(0, 1): return d
	return 0.0

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

func sequential_map(blocks: Array[BlockType.ID]) -> Array[int]:
	"""
	Преобразует список blocks, заменяя каждый элемент на код,
	соответствующий порядку первого вхождения.
	"""
	var mapping: Dictionary = {}            # значение -> код
	var next_id: int = 0             # следующий код
	var result: Array[int] = []             # результирующий список

	for x: int in blocks:
		if x not in mapping:
			mapping[x] = next_id
			next_id += 1
		result.append(mapping[x])

	return result

var MULTI_TABLE: Dictionary = build_multitype_table()

# # TODO возможно стоит перенести в ServiceLocator
# @onready var world_settings: WorldSettings = WorldSettings.new()

func generate_layer_mesh(
		weight_fields: Array, # 3D массив: weight_fields[layer_num][z][x] значения от 0.0 до 0.5
		block_ids: Array, # 3D массив: block_ids[layer_num][z][x] значения BlockType.ID
		layer: int,
		layer_height: float
) -> Dictionary[BlockType.ID, ArrayMesh]:
	var meshes: Dictionary[BlockType.ID, ArrayMesh] = {}
	var surface_tools: Dictionary[BlockType.ID, SurfaceTool] = {}

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
			# a, b, c, d
			var blocks: Array[BlockType.ID] = [
				blocks_2d[z][x],
				blocks_2d[z][x + 1],
				blocks_2d[z + 1][x + 1],
				blocks_2d[z + 1][x]
			]

			var weights: Array = [
				weight_2d[z][x],
				weight_2d[z][x + 1],
				weight_2d[z + 1][x + 1],
				weight_2d[z + 1][x]
			]

			var values: Array[int] = sequential_map(blocks)
			var ms_case: int = 0
			for i: int in range(4):
				ms_case += values[i]*(T**i)

			var block_id_map: Dictionary[int, BlockType.ID] = {}
			for i: int in range(4):
				block_id_map[ values[i] ] = blocks[i]
			
			# после того, как вы заполнили block_id_map
			for code: int in block_id_map.keys():
				var base_id: BlockType.ID = block_id_map[code]
				# достаём именно ту часть таблицы, что для этого кода
				var tris: Array = MULTI_TABLE[ms_case][code]
				for tri: Array in tris:
					var pts: Array = []
					for e: Array in tri:
						var kind: String = e[0]
						var idx: int     = e[1]
						if kind == 'p':
							pts.append(POINTS[idx])
						else:
							var a: int = EDGES[idx][0]
							var b: int = EDGES[idx][1]
							pts.append(interp(POINTS[a], POINTS[b], weights[a], weights[b]))
					for p: Vector2 in pts:
						surface_tools[base_id].add_vertex(
							Vector3(
								x + p.x, 
								layer * layer_height, 
								z + p.y
							) * 0.2 # TODO это размер ячейки, его нужно брать из конфига
						)
			
	for block_id: BlockType.ID in surface_tools.keys():
		var st: SurfaceTool = surface_tools[block_id]
		st.generate_normals()
		meshes[block_id] = st.commit()

	return meshes
