extends MeshInstance3D

enum BlockType { GRASS, STONE }

# Размер одного тайла в атласе (например, если текстура 16x16 в атласе 256x256)
const ATLAS_TILE_SIZE: float = 16.0 / 256.0

# Определяем UV-регионы для каждого типа блоков (координаты в диапазоне [0,1])
var uv_data = {
	BlockType.GRASS: {
		"top": Rect2(0 * ATLAS_TILE_SIZE, 0 * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE),
		"side": Rect2(1 * ATLAS_TILE_SIZE, 0 * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE),
		"bottom": Rect2(2 * ATLAS_TILE_SIZE, 0 * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE)
	},
	BlockType.STONE: {
		"all": Rect2(3 * ATLAS_TILE_SIZE, 0 * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE)
	}
}

const CHUNK_SIZE = 16        # Чанк 16x16 блоков
const BLOCK_SIZE = 1.0       # Размер одного блока

var noise: FastNoiseLite

func _ready():
	# Если шум не назначен через инспектор, создаём его
	if noise == null:
		noise = FastNoiseLite.new()
		# В Godot 4.3 используйте NOISE_TYPE_SIMPLEX вместо NOISE_SIMPLEX
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  
		noise.frequency = 0.1
	# Генерируем меш для этого чанка
	mesh = generate_chunk_mesh()

func generate_chunk_mesh() -> ArrayMesh:
	var new_mesh = ArrayMesh.new()
	var arrays = []
	var vertices = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Генерируем чанки по координатам x,z
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			# Вычисляем высоту по шуму
			var height = int(noise.get_noise_2d(x, z) * 10)
			# Если высота меньше 1, пропускаем
			if height < 1:
				continue
			for y in range(height):
				var block_origin = Vector3(x * BLOCK_SIZE, y * BLOCK_SIZE, z * BLOCK_SIZE)
				# Определяем тип блока: верхний блок – GRASS, остальные – STONE
				var block_type = BlockType.STONE
				if y == height - 1:
					block_type = BlockType.GRASS
				# Получаем данные куба для этого блока
				var cube_data = get_cube_data_for_block(block_type, block_origin, BLOCK_SIZE)
				var cube_verts = cube_data[0]
				var cube_uvs = cube_data[1]
				var start_index = vertices.size()
				vertices.append_array(cube_verts)
				uvs.append_array(cube_uvs)
				var cube_indices = get_cube_indices24(start_index)
				indices.append_array(cube_indices)
	
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return new_mesh

func get_cube_indices24(start_index: int) -> PackedInt32Array:
	return PackedInt32Array([
		# Front face
		start_index + 0, start_index + 1, start_index + 2,
		start_index + 0, start_index + 2, start_index + 3,
		# Back face
		start_index + 4, start_index + 5, start_index + 6,
		start_index + 4, start_index + 6, start_index + 7,
		# Left face
		start_index + 8, start_index + 9, start_index + 10,
		start_index + 8, start_index + 10, start_index + 11,
		# Right face
		start_index + 12, start_index + 13, start_index + 14,
		start_index + 12, start_index + 14, start_index + 15,
		# Top face
		start_index + 16, start_index + 17, start_index + 18,
		start_index + 16, start_index + 18, start_index + 19,
		# Bottom face
		start_index + 20, start_index + 21, start_index + 22,
		start_index + 20, start_index + 22, start_index + 23
	])


# Возвращает данные куба: [vertices, uvs]
func get_cube_data(origin: Vector3, size: float) -> Array:
	var half = size / 2.0
	var verts = []
	var uvs = []
	
	# Front face (Z negative)
	verts.append(origin + Vector3(-half, -half, -half))
	verts.append(origin + Vector3( half, -half, -half))
	verts.append(origin + Vector3( half,  half, -half))
	verts.append(origin + Vector3(-half,  half, -half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	# Back face (Z positive)
	verts.append(origin + Vector3( half, -half, half))
	verts.append(origin + Vector3(-half, -half, half))
	verts.append(origin + Vector3(-half,  half, half))
	verts.append(origin + Vector3( half,  half, half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	# Left face (X negative)
	verts.append(origin + Vector3(-half, -half, half))
	verts.append(origin + Vector3(-half, -half, -half))
	verts.append(origin + Vector3(-half,  half, -half))
	verts.append(origin + Vector3(-half,  half,  half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	# Right face (X positive)
	verts.append(origin + Vector3( half, -half, -half))
	verts.append(origin + Vector3( half, -half,  half))
	verts.append(origin + Vector3( half,  half,  half))
	verts.append(origin + Vector3( half,  half, -half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	# Top face (Y positive)
	verts.append(origin + Vector3(-half,  half, -half))
	verts.append(origin + Vector3( half,  half, -half))
	verts.append(origin + Vector3( half,  half,  half))
	verts.append(origin + Vector3(-half,  half,  half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	# Bottom face (Y negative)
	verts.append(origin + Vector3(-half, -half,  half))
	verts.append(origin + Vector3( half, -half,  half))
	verts.append(origin + Vector3( half, -half, -half))
	verts.append(origin + Vector3(-half, -half, -half))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(1,0))
	uvs.append(Vector2(0,0))
	
	return [PackedVector3Array(verts), PackedVector2Array(uvs)]



# Возвращает массив [PackedVector3Array вершин, PackedVector2Array UV]
func get_cube_data_for_block(block_type: int, origin: Vector3, size: float) -> Array:
	var half = size / 2.0
	var verts = []
	var uvs = []
	
	# Функция для генерации UV для граней по заданному Rect2
	var face_uvs = func face_uvs(rect: Rect2) -> PackedVector2Array:
		return PackedVector2Array([
			rect.position + Vector2(0, rect.size.y),
			rect.position + Vector2(rect.size.x, rect.size.y),
			rect.position,
			rect.position + Vector2(rect.size.x, 0)
		])
	
	# Функция для добавления данных одной грани
	# face: массив из 4 вершин (с местным смещением относительно центра)
	var add_face = func add_face(face_verts: Array, face_uv: Rect2) -> void:
		# Добавляем вершины
		for v in face_verts:
			verts.append(v)
		# Добавляем UV (в том же порядке, что и вершины)
		var f_uvs = face_uvs.call(face_uv)
		uvs.append_array(f_uvs)
	
	# Определяем UV-rect для каждой грани в зависимости от типа блока
	var uv_top: Rect2
	var uv_side: Rect2
	var uv_bottom: Rect2
	if block_type == BlockType.GRASS:
		uv_top = uv_data[BlockType.GRASS]["top"]
		uv_side = uv_data[BlockType.GRASS]["side"]
		uv_bottom = uv_data[BlockType.GRASS]["bottom"]
	elif block_type == BlockType.STONE:
		uv_top = uv_data[BlockType.STONE]["all"]
		uv_side = uv_data[BlockType.STONE]["all"]
		uv_bottom = uv_data[BlockType.STONE]["all"]
	else:
		uv_top = Rect2(0,0,1,1)
		uv_side = Rect2(0,0,1,1)
		uv_bottom = Rect2(0,0,1,1)
	
	# Определяем центр куба
	var center = origin + Vector3(half, half, half)
	
	# Для каждой грани вычисляем вершины (с местным смещением относительно center)
	# Порядок: front, back, left, right, top, bottom
	# Front face (Z negative)
	add_face.call([
		center + Vector3(-half, -half, -half),
		center + Vector3( half, -half, -half),
		center + Vector3( half,  half, -half),
		center + Vector3(-half,  half, -half)
	], uv_side)
	
	# Back face (Z positive)
	add_face.call([
		center + Vector3( half, -half, half),
		center + Vector3(-half, -half, half),
		center + Vector3(-half,  half, half),
		center + Vector3( half,  half, half)
	], uv_side)
	
	# Left face (X negative)
	add_face.call([
		center + Vector3(-half, -half, half),
		center + Vector3(-half, -half, -half),
		center + Vector3(-half,  half, -half),
		center + Vector3(-half,  half,  half)
	], uv_side)
	
	# Right face (X positive)
	add_face.call([
		center + Vector3( half, -half, -half),
		center + Vector3( half, -half,  half),
		center + Vector3( half,  half,  half),
		center + Vector3( half,  half, -half)
	], uv_side)
	
	# Top face (Y positive)
	add_face.call([
		center + Vector3(-half,  half, -half),
		center + Vector3( half,  half, -half),
		center + Vector3( half,  half,  half),
		center + Vector3(-half,  half,  half)
	], uv_top)
	
	# Bottom face (Y negative)
	add_face.call([
		center + Vector3(-half, -half,  half),
		center + Vector3( half, -half,  half),
		center + Vector3( half, -half, -half),
		center + Vector3(-half, -half, -half)
	], uv_bottom)
	
	return [PackedVector3Array(verts), PackedVector2Array(uvs)]
